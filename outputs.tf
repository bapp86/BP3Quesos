# outputs.tf
# Defino un output que resume información útil tras el despliegue en primera persona.

output "resumen_final" {
  value = format(
    "\n%s\n\"%s\"\n\n%s\n%s\n\n%s",

    "Aquí está el nombre DNS público del Application Load Balancer. Lo selecciono, lo copio y lo pego en mi navegador. Recargo la pagina para observar los distintos tipos de quesos.",

    aws_lb.main.dns_name,

    "Aquí el listado de las direcciones IP públicas de las instancias EC2 para acceso SSH.",

    jsonencode(aws_instance.web_server[*].public_ip),

    "Trabajo hecho por BP"
  )
}
