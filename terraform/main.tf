resource "aws_instance" "web" {
  ami           = "ami-0a716d3f3b16d290c"
  instance_type = "t3.micro"
  key_name      = "terraform-key"  
  
  tags = {
    Name = "Terraform-Test-EC2"
  }
}
