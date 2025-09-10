resource "aws_instance" "web" {
  ami           = "ami-0b8e5c7d9b4e8c3d0"
  instance_type = "t3.micro"
  key_name      = "terraform-key"  # must match your AWS key pair

  tags = {
    Name = "Terraform-Test-EC2"
  }
}
