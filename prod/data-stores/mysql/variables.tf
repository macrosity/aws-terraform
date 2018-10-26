#-----prod/data-stores/mysql/variables.tf

variable "db_name" {
  description = "The name for the mysql database"
  default     = "prod"
}

variable "db_password" {
  description = "The password for the mysql database"
}

#variable "env" {
#  description = "The environment that the service exists in"
#  default     = "prod"
#}

