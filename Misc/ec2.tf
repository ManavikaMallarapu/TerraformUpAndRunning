#aws provider ohio region
provider "aws" {
  region = "us-east-2"
}

#create an EC2 instance 
resource "aws_instance" "ec2" {
  ami = "ami-0c2b8ca1dad447f8a"
  instance_type = "t2.micro"
  key_name = "aws-key"
  subnet_id = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sg.id}"]
  tags = {
    Name = "ec2"
  }
}

#create a security group
resource "aws_security_group" "sg" {
  name = "sg"
  description = "Security group for EC2 instance"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "sg"
    }
}
