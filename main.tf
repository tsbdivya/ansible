variable "aws_key_pair" {
  default = "C:/Terraform/default-ec2.pem"
}

provider "aws" {
  region  = "us-east-1"
  version = "~>2.46"
}

resource "aws_default_vpc" "default"{
 
}

data "aws_subnet_ids" "default_subnets"{
    vpc_id = aws_default_vpc.default.id
}



//http Server -> 80 TCP , 22 TCP , CIDR ["0.0.0.0/0"]

resource "aws_security_group" "http_server_sg" {
  name   = "http_server_sg"
  #vpc_id = "vpc-0eb937cb061740c4e"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "http_server_sg"
  }
}

resource "aws_instance" "http_server" {
  ami                    = "ami-09538990a0c4fe9be"
  key_name               = "default-ec2"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  //subnet_id              = "subnet-032152eb8fd0fe039"
  for_each =data.aws_subnet_ids.default_subnets.ids
  subnet_id = each.value

  tags = {
    name: "http_servers_${each.value}"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.aws_key_pair)

  }

  provisioner "remote-exec" {

    inline = [
      "sudo yum install httpd -y",
      "sudo service httpd start",
      "echo Welcome to EC2 instance is at ${self.public_dns}  | sudo tee /var/www/html/index.html"
    ]

  }
}