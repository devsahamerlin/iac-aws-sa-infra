resource "aws_security_group" "web-server-sg" {
  name = "${var.server_name}-sg"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = var.web_server_port
    to_port     = var.web_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "serveur-web" {
  ami                    = var.ami_id #data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web-server-sg.id]
  subnet_id     = var.subnet_id
  associate_public_ip_address = true

  credit_specification {
    cpu_credits = "unlimited"
  }

  user_data  = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              sed -i -e 's/80/${var.web_server_port}/' /etc/apache2/ports.conf
              currentDateTime=$(date)
              echo "Hello AWS Terraform Web server $currentDateTime" > /var/www/html/index.html
              systemctl restart apache2
              EOF
  tags = {
    Name = var.server_name
  }
}