#-----stage/data-stores/mysql/main.tf

#-----Define AWS and Region
provider "aws" {
  region = "us-east-1"
}

#-----Module for mysql node with stage variables defined. There are empty
#-----values defined for these in modules/data-stores/mysql/variables.tf
#-----so the variables are defined here
#module "mysql_backend" {
#  source      = "../../../modules/data-stores/mysql"
#  db_name     = "stage"
#  db_password = "$var.db_password"
#  env         = "stage"
#}

#-----Create RDS with mysql engine with 10G of storage
resource "aws_db_instance" "backend" {
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  name                = "${var.db_name}"
  username            = "admin"
  password            = "${var.db_password}"
  skip_final_snapshot = true
}
