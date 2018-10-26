#-----Specify a path to an existing S3 storage bucket to store
#-----the tfstate file S3 bucket resource
terraform {
  backend "s3" {
    bucket = "macrosity-tf-up-and-running-state"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"
  }
}
