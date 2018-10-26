#-----stage/services/webserver-cluster/outputs.tf

output "elb_dns_name" {
  value = "${module.webserver_cluster.elb_dns_name}"
}

output "db_address" {
  value = "${module.webserver_cluster.db_address}"
}

output "db_port" {
  value = "${module.webserver_cluster.db_port}"
}
