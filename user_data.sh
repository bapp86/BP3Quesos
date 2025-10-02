#!/bin/bash
# user_data.sh
# Actualizo paquetes, instalo Docker y lanzo el contenedor especificado por terraform.

# Actualizo paquetes e instalo Docker
yum update -y
yum install -y docker
service docker start
usermod -a -G docker ec2-user

# Ejecuta el contenedor Docker especificado por Terraform en background y con restart siempre
docker run -d --restart always -p 80:80 ${docker_image}
```