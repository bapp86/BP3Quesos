# Despliegue Profesional "The Cheese Factory"

Este repositorio contiene el despliegue de la infraestructura para la aplicación "The Cheese Factory" en AWS, utilizando Terraform.

El objetivo es demostrar el uso de prácticas avanzadas de DevOps (IaC), incluyendo la gestión de estado remoto, el uso de módulos públicos verificados y la implementación de una arquitectura de red segura (VPC personalizada) que sigue el principio de mínimo privilegio.

## Arquitectura de la Infraestructura

La arquitectura desplegada consta de los siguientes componentes:

* **Red (VPC):** Se utiliza el módulo `terraform-aws-modules/vpc/aws` para crear una VPC personalizada. Esta VPC se divide en 3 subredes públicas y 3 subredes privadas, distribuidas en tres Zonas de Disponibilidad.
* **Balanceador de Carga (ALB):** Un Application Load Balancer público se despliega en las subredes públicas para recibir el tráfico web.
* **Servidores de Aplicación (EC2):** Tres instancias EC2 se despliegan en las subredes privadas. Estas instancias ejecutan la aplicación de quesos en contenedores Docker y no son accesibles directamente desde Internet.
***Estado Remoto (Backend):** El estado de Terraform (`.tfstate`) se almacena de forma segura en un bucket S3 privado y versionado, con bloqueo de estado gestionado por DynamoDB.

## Características Técnicas Implementadas

Este proyecto cumple con todos los requisitos técnicos de la actividad:

* **Gestión de Código:** El proyecto está gestionado en Git e incluye un archivo `terraform.tfvars.example`[cite: 22].
* **Estado Remoto:** El backend S3 se crea como infraestructura separada en un directorio `s3-backend-bootstrap`, cumpliendo con el requisito de desacoplamiento.
* **Modularidad (Módulos Públicos):**
    * `terraform-aws-modules/vpc/aws` para la red.
    * `terraform-aws-modules/s3-bucket/aws` para el bucket del backend.
* **Seguridad (Mínimo Privilegio):**
    * **ALB Security Group:** Permite HTTP (80) desde Internet (`0.0.0.0/0`).
    * **EC2 Security Group:** Permite HTTP (80) **únicamente** desde el Security Group del ALB y SSH (22) **únicamente** desde la IP local (definida en `terraform.tfvars`).
* **Lógica Condicional:**
    * El tipo de instancia EC2 cambia según la variable `environment`.
    * `environment = "prod"` despliega `t3.small`.
    * `environment = "dev"` despliega `t2.micro`.

## Estructura del Repositorio

El repositorio está dividido en dos proyectos independientes:<br />
├── 1-s3-backend-bootstrap/ # Proyecto para crear el bucket S3 y la tabla DynamoDB <br />
└── 2-BP3Quesos/ # Proyecto principal de la infraestructura (VPC, ALB, EC2)


Este proyecto fue desarrollado y probado localmente en:

- **Sistema operativo**: Ubuntu 22.04 LTS (máquina virtual en VMware Workstation Pro)
- **Herramientas**:
  - Terraform CLI
  - AWS CLI
  - Visual Studio Code
  - Git
  - Docker
Este entorno permite ejecutar los comandos de Terraform, editar archivos `.tf` y realizar pruebas previas al despliegue en AWS.


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
```


## Despliegue paso a paso

Sigue estos pasos para desplegar la infraestructura y visualizar la aplicación web distribuida:

__1. Clonar el repositorio.__
```
git clone https://github.com/bapp86/BP3Quesos.git
cd BP3Quesos
```
__2. Configurar las variables.__

Edita el archivo terraform.tfvars o crea uno nuevo a partir de terraform.tfvars.example:
```
cp terraform.tfvars.example terraform.tfvars
```

- __Ajusta los valores según el entorno:__

  - __aws_region__: Región de AWS (ej. "us-east-1")

  - __instance_type__: Tipo de instancia EC2 (ej. "t2.micro")

  - __my_ip__: Tu IP pública con /32 para acceso SSH seguro

  - __docker_images__: Lista de imágenes Docker (una por instancia)


__3.  Inicializar Terraform.__

```terraform init```  

Esto descarga los proveedores necesarios y prepara el entorno.

__4. Aplicar la infraestructura.__

```terraform apply ``` 

__Confirma con 'yes' cuando se te solicite. Esto desplegará:__
- 3 instancias EC2 con contenedores Docker
- Un Application Load Balancer
- Grupos de seguridad y asociaciones
                        

__5. Acceder a la aplicación__

Una vez finalizado el despliegue, copia el DNS del Load Balancer desde el output:

```terraform output resumen_final```


__Pega la URL en tu navegador y recarga la página varias veces para ver distintos tipos de queso.__
