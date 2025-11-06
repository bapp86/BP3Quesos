# variables.tf
# Declaro las variables del módulo sin valores por defecto.
# Todas las variables configurables se controlan desde terraform.tfvars.

variable "aws_region" {
  description = "La region de AWS donde se desplegarán los recursos."
  type        = string
}

variable "instance_type" {
  description = "El tipo de instancia para los servidores web EC2."
  type        = string
}

variable "my_ip" {
  description = "La dirección IP para permitir el acceso SSH. La configuro en terraform.tfvars."
  type        = string
}

variable "docker_images" {
  description = "Una lista de imágenes de Docker para desplegar en cada instancia. Cada entrada crea una instancia."
  type        = list(string)
}

variable "environment" {
  description = "Entorno de despliegue (ej: 'dev' o 'prod')."
  type        = string
  default     = "dev"
}