#-----Define AWS and Region
provider "aws" {
  region = "us-east-1"
}

#-----Module for webserver cluster with stage variables defined. There are empty
#-----values defined for these in modules/services/webserver-cluster/variables.tf
#-----so the variables are defined here
module "webserver_cluster" {
  #source = "../../../modules/services/webserver-cluster"
  source = "git::git@github.com:macrosity/aws-terraform-modules.git//webserver-cluster?ref=v0.0.1"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "macrosity-tf-up-and-running-state"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
}
