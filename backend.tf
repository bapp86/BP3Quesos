# Configuración del backend S3
terraform {
  backend "s3" {
    # Reemplace el 's3_bucket_name' con el de la otra infraestructura: s3-backend-bootstrap
    bucket = "mi-tfstate-backend-bp3quesos-2025"

    # Ruta dentro del bucket para este estado específico
    key = "the-cheese-factory/prod.tfstate"
    
    # Región donde se creó el bucket
    region = "us-east-1"

    # Reemplace el 'dynamodb_table_name' con el de la otra infraestructura: s3-backend-bootstrap
    dynamodb_table = "mi-tfstate-lock-bp3quesos"
    
    # Habilitar encriptación del estado en reposo
    encrypt = true
  }
}