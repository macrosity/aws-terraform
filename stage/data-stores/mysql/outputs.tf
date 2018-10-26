#-----stage/data-stores/mysql/outputs.tf

output "address" {
  value = "${aws_db_instance.backend.address}"
}

output "port" {
  value = "${aws_db_instance.backend.port}"
}
