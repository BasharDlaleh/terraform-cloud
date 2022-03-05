# workspace and required_providers
terraform {

  cloud {
    organization = "cNepho"

    workspaces {
      name = "terraform-cloud"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# vpc id
data "aws_vpc" "main" {
  id = "vpc-09e763c3abc8bf95b"
}

# ec2 instance authorized ssh key
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDT4HlnIctbZx76n752Xv3+uWihgnUz8gR/w6ToJ4pXidn/mgxYRdGfLW0+otgp/zniug27T+vCaz+kAM6likKldGqy4D/xu4EImdHHW2prn2SnGYAYrn/thipYQRfOLJ+v0Qa0iyMxiQwl+WfoGbjX8R6el9YrEp921zSGpS7n8pTA7+jUJEL6FevxdSQSrPG4zJ5SKTqMcIGA48Gf2s4QQdYJqv8D4PdI3wRzMbh9UwLxbNUjGVoUkqH7FlnLfZ5XVJyuFFrGsbnuRVH9Y2iGcvqvMAZr9//y2xZvrNnXs8wEQD7laTTUffXPh275AYiP1U7c4vJ9pDA0EK/VPaN7 root@myserver"
}

# user data
data "template_file" "user_data" {
  template = file("./userdata.yaml")
}

# ec2 instance 
resource "aws_instance" "my_server" {
  ami           = "ami-033b95fb8079dc481"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_my_server.id]
  key_name = "${aws_key_pair.deployer.key_name}"
  user_data = data.template_file.user_data.rendered
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
  tags = {
    Name = "My-Server"
  }
}

# security group
resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "MyServer Security Group"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description      = "HTTP from Anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  ingress {
    description      = "SSH from Anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "MyServer Security Group"
  }
}

output "public_ip" {
  value = aws_instance.my_server.public_ip
}
