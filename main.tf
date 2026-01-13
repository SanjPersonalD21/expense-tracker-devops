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

#Generating a unique name for the security group on each apply since I keep running into duplicate error
resource "terraform_data" "sg_name" {
  input = "flask-app-sg-sanju-${formatdate("YYYYMMDDhhmmss", timestamp())}"
}

#1. Security Group (Firewall)
resource "aws_security_group" "flask_app_sg" {
  name        = terraform_data.sg_name.output
  description = "Allow SSH and Flask app port"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  #For demo purposes only
    description = "SSH access - restrict in production"
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

#2. EC2 instance
resource "aws_instance" "expense_tracker_app" {
  #Get the latest Ubuntu AMI
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  #Attach the security group we defined above
  vpc_security_group_ids = [aws_security_group.flask_app_sg.id]
  key_name = "my-expense-key"

  user_data = <<-EOF
              #!/bin/bash
              set -e  # Exit on error
              
              echo "Starting deployment at $(date)"
              
              #Install dependencies
              sudo apt-get update -y
              sudo apt-get install -y python3-pip python3-venv git
              
              #Clone repository
              git clone https://github.com/SanjPersonalD21/expense-tracker-devops.git /home/ubuntu/app
              cd /home/ubuntu/app
              
              #Set up Python environment
              python3 -m venv venv
              source venv/bin/activate
              pip install -r application/requirements.txt
              
              #Run the application
              cd application
              nohup python3 app.py > /var/log/flask_app.log 2>&1 &
              
              #Wait and test
              sleep 10
              echo "Testing application..."
              curl -f http://localhost:5000/health || echo "Health check failed, but continuing"
              
              echo "Application deployed at $(date)" > /home/ubuntu/deployment_status.txt
              echo "Check logs: /var/log/flask_app.log"
              EOF

  tags = {
    Name = "Expense-Tracker-App"
    Project = "DevOps-Coursework"
  }
}

#Data source to fetch the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] #Standardised

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "application_url" {
  value = "http://${aws_instance.expense_tracker_app.public_ip}:5000"
  description = "URL to access live application"
}