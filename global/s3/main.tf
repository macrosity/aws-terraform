#-----Define the provider and region
provider "aws" {
  region = "us-east-1"
}

#-----Define a S3 bucket that will be used to store our tfstate files
resource "aws_s3_bucket" "terraform_state" {
  bucket = "macrosity-tf-up-and-running-state"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
