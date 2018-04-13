variable "aws_region" {
  default = "us-east-1"
}

variable "http_port" {
  description = "HTTP Server default port"
  default = 8080
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_ami" "ubuntu" {
  most_recent = "true"

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "nitro" {
  launch_configuration = "$aws_launch_configuration.nitro.id"

  min_size = 2
  max_size = 8

  availability_zones = ["${data.aws_availability_zones.all.names}"]

  tag {
    key                 = "Name"
    value               = "Nitro Auto-Scale Group"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nitro" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.web_acl.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "{var.http_port}" &
              EOF

  lifecycle {
    create_before_destroy = true # Always create resource before destroying original
  }

  tags {
    Name = "macro-terra"
  }
}

resource "aws_security_group" "web_acl" {
  name = "web-server-any"

  ingress {
    from_port   = "${var.http_port}"
    to_port     = "${var.http_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "image_id" {
  value = "${data.aws_ami.ubuntu.id}"
}

output "public_ip" {
  value = "${aws_instance.nitro.public_ip}"
}
