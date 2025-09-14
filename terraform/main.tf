############################################################
# PROVIDER
############################################################
provider "aws" {
  region = "eu-north-1"
}

############################################################
# EC2 INSTANCES
############################################################
resource "aws_instance" "web1" {
  ami                    = "ami-0a716d3f3b16d290c"
  instance_type          = "t3.micro"
  key_name               = "terraform-key"
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = var.vpc_security_group_ids

  associate_public_ip_address = true 

  user_data = <<-EOF
              #!/bin/bash
              # Update packages
              apt update
              apt install -y nginx python3.11 python3.11-venv python3-pip mysql-client git

              # Create app directory
              mkdir -p /opt/sslchecker
              cd /opt/sslchecker

              # Clone your GitHub repository
              git clone https://github.com/GeorgiAndreev96/ssl-checker.git .

              # Setup Python virtual environment
              python3.11 -m venv venv
              source venv/bin/activate
              pip install --upgrade pip
              pip install -r requirements.txt

              # Create systemd service for FastAPI
              cat > /etc/systemd/system/sslchecker.service << EOL
              [Unit]
              Description=SSL Checker FastAPI
              After=network.target

              [Service]
              User=ubuntu
              WorkingDirectory=/opt/sslchecker/backend
              Environment="PATH=/opt/sslchecker/venv/bin"
              ExecStart=/opt/sslchecker/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

              [Install]
              WantedBy=multi-user.target
              EOL

              # Start and enable FastAPI service
              systemctl daemon-reload
              systemctl start sslchecker
              systemctl enable sslchecker

              # Deploy frontend files to nginx root
              mkdir -p /var/www/html/sslchecker
              cp -r /opt/sslchecker/frontend/* /var/www/html/sslchecker/

              # Configure Nginx reverse proxy
              cat > /etc/nginx/sites-available/sslchecker << EOL
              server {
                  listen 80;

                  root /var/www/html/sslchecker;
                  index index.html;

                  location /api/ {
                      proxy_pass http://127.0.0.1:8000/api/;
                      proxy_set_header Host \$host;
                      proxy_set_header X-Real-IP \$remote_addr;
                  }

                  location / {
                      try_files \$uri /index.html;
                  }
              }
              EOL

              ln -s /etc/nginx/sites-available/sslchecker /etc/nginx/sites-enabled/
              rm /etc/nginx/sites-enabled/default
              systemctl restart nginx

              EOF

  tags = {
    Name = "iaac-task-web1"
  }
}

resource "aws_instance" "web2" {
  ami                    = "ami-0a716d3f3b16d290c"
  instance_type          = "t3.micro"
  key_name               = "terraform-key"
  subnet_id              = var.subnet_ids[1]
  vpc_security_group_ids = var.vpc_security_group_ids

  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  associate_public_ip_address = true 

  tags = {
    Name = "iaac-task-web2"
  }
}

############################################################
# RDS SUBNET GROUP
############################################################
resource "aws_db_subnet_group" "iaac_task_db_subnet" {
  name       = var.db_subnet_group_name
  subnet_ids = var.subnet_ids

  tags = {
    Name = var.db_subnet_group_name
  }
}

############################################################
# RDS DATABASES
############################################################
resource "aws_db_instance" "db_master" {
  identifier             = "db-iaac-task"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  username               = var.rds_username
  password               = var.rds_password
  allocated_storage      = 20
  # Change this line to reference the subnet group resource's name
  db_subnet_group_name   = aws_db_subnet_group.iaac_task_db_subnet.name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az               = false
  skip_final_snapshot    = false
  backup_retention_period = 7

  tags = {
    Name = "db-iaac-task11"
  }
}

resource "aws_db_instance" "db_replica" {
  identifier             = "db-iaac-task-rep"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  replicate_source_db    = aws_db_instance.db_master.arn
  # Change this line to reference the subnet group resource's name
  db_subnet_group_name   = aws_db_subnet_group.iaac_task_db_subnet.name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az               = false
  skip_final_snapshot    = true

  tags = {
    Name = "db-iaac-task-rep"
  }
}


############################################################
# NEW TARGET GROUP FOR ALB
############################################################
resource "aws_lb_target_group" "web_tg" {
  name     = "TG-iaac-task-new"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "TG-iaac-task-new"
  }
}

############################################################
# NEW APPLICATION LOAD BALANCER
############################################################
resource "aws_lb" "web_alb" {
  name               = "aws-iaac-alb-new"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.vpc_security_group_ids
  subnets            = var.subnet_ids

  tags = {
    Name = "aws-iaac-alb-new"
  }
}

############################################################
# LISTENER FOR THE ALB
############################################################
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

############################################################
# REGISTER EC2 INSTANCES WITH NEW TARGET GROUP
############################################################
resource "aws_lb_target_group_attachment" "web1_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2_attach" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

