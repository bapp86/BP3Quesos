# terraform.tfvars

# Archivo donde controlo todas las variables personalizables.
# Modifico este archivo para ajustar la infraestructura sin tocar otros archivos.

# Región AWS donde la voy a desplegar
aws_region = "us-east-1"

# Tipo de instancia EC2
instance_type = "t2.micro"

# Dirección IP desde la que permito el acceso SSH
# Ejemplo inseguro para pruebas rápidas: "0.0.0.0/0"
# En producción reemplazar por "TU_IP_PUBLICA/32"
my_ip = "0.0.0.0/0"

# Lista de imágenes Docker que ejecuto en cada instancia (una por instancia)
# Modifico esta lista para cambiar qué contenedores lanzo por cada servidor.
docker_images = [
  "errm/cheese:wensleydale",
  "errm/cheese:cheddar",
  "errm/cheese:stilton"
]

environment = "dev"