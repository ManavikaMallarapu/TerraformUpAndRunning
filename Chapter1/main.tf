#aws provider ec2 instance in ohio region
provider "aws" {
  region = "us-east-2"
}

#aws provider ec2 instance with ami and instance type, availability zone, bash script to install apache
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "Hello, World" > index.html
              sudo mv index.html /var/www/html
              EOF
}
