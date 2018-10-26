#-----global/s3/outputs.tf

#-----Define an output to capture the S3 bucket resource name
output "s3_bucket_arn" {
  value = "${aws_s3_bucket.terraform_state.arn}"
}
