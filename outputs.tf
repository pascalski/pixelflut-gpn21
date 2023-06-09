output "names" {
  value = {for public_instance in aws_instance.public_instance: public_instance.name => public_instance.public_ip}
}
