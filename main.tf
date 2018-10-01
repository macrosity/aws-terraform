# Providers for AWS Infrastructure go here
provider "aws" {
  region = "eu-west-2"
}

# Variables for AWS Infrastructure go here
variable "http_port" {
  description = "Standard HTTP server port"
  default     = 8080
}

variable "sshd_port" {
  description = "Standard SSH server port"
  default     = 22
}

# Data outputs for AWS Infrastructure go here
data "aws_availability_zones" "all" {}

# Resources for AWS Infrastructure go here
resource "aws_key_pair" "macrosity-aws-key" {
  key_name = "macrosity-aws-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+sVRDvgB3d/lMkBMB3FZnFI/XcvzSs9KMwJ1hRBcKVyqdQC/saaULIa4n8T8+V8A4LDLE5PCIAGoaoDBk6x8yZbxo8ec1BcauDO2khRIeGc8UxatlaznHbsUm43V4cM651qjdLfEmGk1ES8LXeWRx2+jsEm8+AR/oC6TW9cnplKJDRdMOopruq+SB5FyS8xEexc1R+WEHVs6jmzSKzpzspFVT1YRr6wlUv+/EdRXww2JiiCbrs/T/vzesIhExigLZk4E2JB/RG5bhvYY5KmHrZvou1RMD13bJXnzxy6+0/ToD4uBr2mlrRvVMXGc676SieQmFgwp1z5482Afq8tLJZKKzdiWL1QKN97SvEVvKyRcHti6qf3e1IZHq0i7ympc76iv1cpWPAiDPNrE2WGK+X84NTpATKY0TO71h4Ra3g6xmc+4b/N9y5uAIaq5HYsE1bFmsDbES5I47tRMUJEfkgoI+plR+YJt7rKp2f5EIZVyJ53R7EFSRKoU3t2FEpJWNVqn0Yfy6ZkjSwIHUkllasF962vjOujYQXhYerQPO47YmAv0ZVS70I+56+wkKDv7gJAdEoya0W3EGIIGWHMLqLi9Ts5jYF/PS6KASfhcfxnDUTd/TlsjtJ+xG8PujrCsMO4hs48XJPBQvAZ6wKtDYLYDK1ATfjDiPB7BuBQ8nIQ== sro75@MacBook"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "nitro-elb" {
  name               = "nitro-elb-01"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.http-elb-default.id}"]

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

resource "aws_launch_configuration" "nitro-lc" {
  image_id               = "ami-506e8f37"
  instance_type          = "t2.micro"
  key_name               = "macrosity-aws-key"
  security_groups        = ["${aws_security_group.http-default-in.id}","${aws_security_group.sshd-default-in.id}"]

  user_data     = <<-EOF
                  #!/bin/bash
                  echo "Hello, World" > index.html
                  nohup busybox httpd -f -p "${var.http_port}" &
                  EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nitro-asc" {
  launch_configuration = "${aws_launch_configuration.nitro-lc.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.nitro-elb.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    key                 = "Name"
    value               = "nitro-asc"
    propagate_at_launch = "true"
  }
}

resource "aws_security_group" "http-default-in" {
  name          = "http-default-in"

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

resource "aws_security_group" "sshd-default-in" {
  name          = "sshd-default-in"

  ingress {
    from_port   = "${var.sshd_port}"
    to_port     = "${var.sshd_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "http-elb-default" {
  name = "http-elb-default"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs for AWS Infrastructure go here
output "elb_dns_name" {
  value = "${aws_elb.nitro-elb.dns_name}"
}
