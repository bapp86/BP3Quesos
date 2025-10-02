# main.tf
# Configuro el proveedor AWS
# Defino los recursos de red, balanceador, instancias EC2 y asociaciones.


provider "aws" {
  # Especifico la región de AWS a usar (controlada por terraform.tfvars)
  region = var.aws_region
}

# ** FUENTES DE DATOS DE LA CUENTA DE AWS **
# Obtengo la VPC por defecto así despliego recursos dentro de este
data "aws_vpc" "default" {
  default = true
}

# Obtengo las subnets públicas de la VPC por defecto
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Busco la AMI más reciente de Amazon Linux 2 para lanzar instancias
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ** Recursos de red y grupos de seguridad **
# Security Group para el Application Load Balancer (HTTP público)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Permite el trafico HTTP desde internet"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Permitir HTTP desde cualquier lugar"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-SG"
  }
}

# Security Group para las instancias web (HTTP desde ALB, SSH desde my_ip)
resource "aws_security_group" "web_sg" {
  name        = "web-server-security-group"
  description = "Permite SSH y HTTP desde el ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Permitir HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Permitir SSH desde la IP configurada en terraform.tfvars"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServer-SG"
  }
}

# ** Recursos del balanceador de carga **
# Creo un Application Load Balancer público en las subnets públicas (hasta 3 subnets)
resource "aws_lb" "main" {
  name               = "cheese-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = slice(data.aws_subnets.public.ids, 0, 3)
  tags = {
    Name = "Cheese-ALB"
  }
}

# ALB ascociado a un Target Group (HTTP en el puerto 80)
resource "aws_lb_target_group" "main" {
  name     = "cheese-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener HTTP que forwardea al target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ** Servidores EC2 **
# Creo instancias EC2, una por cada imagen Docker listada en var.docker_images
resource "aws_instance" "web_server" {
  count = length(var.docker_images)
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.public.ids, count.index)
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # user_data templated para lanzar el contenedor Docker indicado por cada elemento de docker_images
  user_data = templatefile("${path.module}/user_data.sh", {
    docker_image = element(var.docker_images, count.index)
  })

  tags = {
    # Nombre legible a la EC2 indicando el índice y la etiqueta de la imagen
    Name      = "WebServer-${count.index + 1}-${element(split(":", element(var.docker_images, count.index)), 1)}"
    IsPrimary = count.index == 0 ? true : false
  }
}

# Asocio cada instancia EC2 al target group del ALB
resource "aws_lb_target_group_attachment" "web_server_attachment" {
  count = length(aws_instance.web_server)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}
