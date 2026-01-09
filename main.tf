# main.tf - Infrastructure as Code for Expense Tracker
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

# 1. SECURITY GROUP (Firewall) - THIS BLOCK WAS MISSING
resource "aws_security_group" "flask_app_sg" {
  # !!! CHANGE THIS NAME IF DUPLICATE ERROR PERSISTS !!!
  # Use a unique name like "flask-app-sg-<yourname>"
  name        = "flask-app-sg-sanju"
  description = "Allow SSH and Flask app port"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Flask application port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Flask-App-SG"
  }
}

# 2. EC2 INSTANCE
resource "aws_instance" "expense_tracker_app" {
  # Get the latest Ubuntu AMI
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  # Attach the security group we defined above
  vpc_security_group_ids = [aws_security_group.flask_app_sg.id]
  # !!! CHANGE THIS TO YOUR KEY PAIR NAME !!!
  key_name      = "my-expense-key"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y python3-pip python3-venv git
              git clone https://github.com/SanjPersonalD21/expense-tracker-devops.git /home/ubuntu/app
              cd /home/ubuntu/app
              python3 -m venv venv
              source venv/bin/activate
              pip install -r application/requirements.txt
              cd application
              nohup python3 app.py > /var/log/flask_app.log 2>&1 &
              echo "App deployed at $(date)" > /home/ubuntu/deployment_status.txt
              EOF

  tags = {
    Name    = "Expense-Tracker-App"
    Project = "DevOps-Coursework"
  }
}

# Data source to fetch the latest Ubuntu AMI (ADD THIS BLOCK)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "application_url" {
  value       = "http://${aws_instance.expense_tracker_app.public_ip}:5000"
  description = "URL to access your live Flask application"
}