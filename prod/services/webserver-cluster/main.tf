#-----Define AWS and Region
provider "aws" {
  region = "us-east-1"
}

#-----Module for webserver cluster with prod variables defined. There are empty
#-----values defined for these in modules/services/webserver-cluster/variables.tf
#-----so the variables are defined here
module "webserver_cluster" {
  #source = "../../../modules/services/webserver-cluster"
  source = "git::git@github.com:macrosity/aws-terraform-modules.git//webserver-cluster?ref=v0.0.1"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "macrosity-tf-up-and-running-state"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 8
}

#-----Define a schedule for our ASG within the module to ramp up cluster
#-----during office hours and back down again overnight
resource "aws_autoscaling_schedule" "scale_out_9_5" {
  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
  scheduled_action_name  = "scale-out-9-to-5"
  min_size               = 2
  max_size               = 8
  desired_capacity       = 8
  recurrence             = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_5_9" {
  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
  scheduled_action_name  = "scale-in-5-to-9"
  min_size               = 2
  max_size               = 8
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
}
