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

resource "aws_elb" "nitro_elb" {
  name               = "aws-elb-nitro-cluster"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["{$aws_security_group.elb_acl.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.http_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:${var.http_port}/"
    interval            = 30
  }
}

resource "aws_security_group" "elb_acl" {
  name = "elb-any"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nitro" {
  launch_configuration = "$aws_launch_configuration.nitro.id"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  load_balancers       = ["${data.aws_elb.nitro_elb.name}"]
  health_check_type    = "ELB"

  min_size = 2
  max_size = 8

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
  name = "web-any"

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

output "elb_dns_name" {
  value = "${aws_elb.nitro_elb.dns_name}"
}
