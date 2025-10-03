# BP3Quesos
Evaluacion 1 Infraestructura como Código

**App para Fábrica de Quesos**

Este proyecto despliega una aplicación web distribuida en tres instancias EC2 de AWS, cada una mostrando un tipo de queso diferente. Al acceder a la URL pública del balanceador de carga y refrescar la página, el usuario recibe una respuesta desde una instancia distinta, lo que permite visualizar diferentes quesos en cada visita.

## Objetivo

Demostrar el uso de infraestructura distribuida en AWS para servir contenido dinámico mediante contenedores Docker, gestionados con Terraform.

## Arquitectura

- **Proveedor**: AWS (Amazon Web Services)
- **Orquestación**: Terraform
- **Sistema Operativo**: Amazon Linux 2
- **Contenedores**: Docker
- **Instancias EC2**: 3, cada una con una imagen Docker distinta
- **Balanceador de carga**: Application Load Balancer (ALB)
- **Red**: VPC por defecto con subnets públicas
- **Seguridad**:
  - ALB permite tráfico HTTP desde cualquier origen
  - EC2 permite tráfico HTTP desde el ALB y acceso SSH desde una IP específica

## Componentes principales

- `main.tf`: Define proveedor, red, seguridad, balanceador, instancias EC2 y asociaciones.
- `terraform.tfvars`: Contiene variables como región, IP de acceso SSH, tipo de instancia y lista de imágenes Docker.
- `terraform.tfvars.example`: Plantilla comentada para replicar y personalizar el despliegue.
- `user_data.sh`: Script de inicialización que instala Docker y lanza el contenedor correspondiente.
- `variables.tf`: Define las variables utilizadas en el proyecto.
- `outputs.tf`: Expone la URL pública del ALB y las IPs de las instancias EC2.
- `README.md`: Este documento.

## Variables personalizables

El archivo `terraform.tfvars` permite ajustar la infraestructura sin modificar los archivos principales. Aquí se definen:

```hcl
aws_region    = "us-east-1"
instance_type = "t2.micro"
my_ip         = "0.0.0.0/0"
docker_images = [
  "errm/cheese:wensleydale",
  "errm/cheese:cheddar",
  "errm/cheese:stilton"
]




# Despliegue paso a paso

Sigue estos pasos para desplegar la infraestructura y visualizar la aplicación web distribuida:

1. Clonar el repositorio.
git clone https://github.com/bapp86/BP3Quesos.git
cd BP3Quesos

2. Configurar las variables.
Edita el archivo terraform.tfvars o crea uno nuevo a partir de terraform.tfvars.example:
cp terraform.tfvars.example terraform.tfvars

## Ajusta los valores según el entorno:
aws_region: Región de AWS (ej. "us-east-1")

instance_type: Tipo de instancia EC2 (ej. "t2.micro")

my_ip: Tu IP pública con /32 para acceso SSH seguro

docker_images: Lista de imágenes Docker (una por instancia)


3.  Inicializar Terraform.
terraform init   # Esto descarga los proveedores necesarios y prepara el entorno.

4. Aplicar la infraestructura.
terraform apply     #  Confirma con yes cuando se te solicite. Esto desplegará:
                    #  3 instancias EC2 con contenedores Docker
                    #  Un Application Load Balancer
                    #  Grupos de seguridad y asociaciones

5. Acceder a la aplicación
Una vez finalizado el despliegue, copia el DNS del Load Balancer desde el output:
terraform output resumen_final
# Pega la URL en tu navegador y recarga la página varias veces para ver distintos tipos de queso.
