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

  tags = {
    Name = "iaac-task-web2"
  }
}

############################################################
# RDS DATABASES
############################################################
resource "aws_db_instance" "db_master" {
  identifier             = "db-iaac-task1"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  username               = var.rds_username
  password               = var.rds_password
  allocated_storage      = 20
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az               = false
  skip_final_snapshot    = true

  tags = {
    Name = "db-iaac-task1"
  }
}

resource "aws_db_instance" "db_replica" {
  identifier              = "db-iaac-task2"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  username                = var.rds_username
  password                = var.rds_password
  allocated_storage       = 20
  db_subnet_group_name    = var.db_subnet_group_name
  vpc_security_group_ids  = var.vpc_security_group_ids
  multi_az                = false
  replicate_source_db     = aws_db_instance.db_master.id
  skip_final_snapshot     = true

  tags = {
    Name = "db-iaac-task2"
  }
}

############################################################
# APPLICATION LOAD BALANCER
############################################################
resource "aws_lb" "web_alb" {
  name               = "aws-iaac-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.vpc_security_group_ids
  subnets            = var.subnet_ids

  tags = {
    Name = "aws-iaac-alb"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "arn:aws:elasticloadbalancing:eu-north-1:851725313439:targetgroup/TG-iaac-task/cb1528ee8919603b"
  }
}

############################################################
# REGISTER EC2 INSTANCES WITH TARGET GROUP
############################################################
resource "aws_lb_target_group_attachment" "web1_attach" {
  target_group_arn = "arn:aws:elasticloadbalancing:eu-north-1:851725313439:targetgroup/TG-iaac-task/cb1528ee8919603b"
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2_attach" {
  target_group_arn = "arn:aws:elasticloadbalancing:eu-north-1:851725313439:targetgroup/TG-iaac-task/cb1528ee8919603b"
  target_id        = aws_instance.web2.id
  port             = 80
}
