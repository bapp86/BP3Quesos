# main.tf
# Configuro el proveedor AWS
# Defino los recursos de red, balanceador, instancias EC2 y asociaciones.

# Test 
provider "aws" {
  # Especifico la región de AWS a usar (controlada por terraform.tfvars)
  region = var.aws_region
}

# ** FUENTES DE DATOS DE LA CUENTA DE AWS **

data "aws_availability_zones" "available" {
  state = "available"
}

# SE AÑADE EL MÓDULO VPC REQUERIDO 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # Asegúrese de tener una versión estable, ej: version = "~> 5.0"
  
  name = "cheese-vpc"
  cidr = "10.0.0.0/16"

  # Configurar 3 AZs
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
private_inbound_acl_rules = [
    {
      rule_number = 101
      rule_action = "allow"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      cidr_block  = "0.0.0.0/0"
    }
  ]

  # Configurar 3 subredes privadas y 3 públicas
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # Se requiere NAT Gateway para que las instancias en subredes privadas accedan a Internet (para yum/docker)
  enable_nat_gateway = true
  single_nat_gateway = true # Ahorra costos para 'dev'
  
  # Habilitar DNS para el ALB
  enable_dns_hostnames = true

  tags = {
    Project     = "The-Cheese-Factory"
    Environment = var.environment
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
  vpc_id      = module.vpc.vpc_id

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
  vpc_id      = module.vpc.vpc_id

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
  subnets            = module.vpc.public_subnets
  tags = {
    Name = "Cheese-ALB"
  }
}

# ALB ascociado a un Target Group (HTTP en el puerto 80)
resource "aws_lb_target_group" "main" {
  name     = "cheese-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

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
  instance_type               = var.environment == "prod" ? "t3.small" : "t2.micro"
  subnet_id                   = element(module.vpc.private_subnets, count.index)
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = false

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
