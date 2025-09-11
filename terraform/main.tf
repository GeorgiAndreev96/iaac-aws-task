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
              apt update
              apt install -y nginx
              systemctl start nginx
              systemctl enable nginx
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
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az               = false
  skip_final_snapshot    = false      # optional for safe deletion
  backup_retention_period = 7         # 7 days of automated backups

  tags = {
    Name = "db-iaac-task11"
  }
}


resource "aws_db_instance" "db_replica" {
  identifier             = "db-iaac-task-rep"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  replicate_source_db    = aws_db_instance.db_master.arn  # <- use ARN instead of ID
  db_subnet_group_name   = var.db_subnet_group_name
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

