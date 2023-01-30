#aws provider ec2 instance in ohio region
provider "aws" {
  region = "us-east-2"
}

#aws ec2 instance with vpc, subnet, security group, ami, instance type, route table, public ip
resource "aws_instance" "My_EC2" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.My_Security_Group.id}"]
  subnet_id = "${aws_subnet.My_Subnet.id}"
  associate_public_ip_address = true
  tags = {
    Name = "My_EC2"
  }
}

#aws vpc
resource "aws_vpc" "My_VPC" {
  cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
      Name = "My_VPC"
    }
}

#aws subnet
resource "aws_subnet" "My_Subnet" {
  vpc_id = "${aws_vpc.My_VPC.id}"
  cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-2a"
    map_public_ip_on_launch = true
    tags = {
      Name = "My_Subnet"
    }
}

#aws security group
resource "aws_security_group" "My_Security_Group" {
  name = "My_Security_Group"
  description = "Allow inbound traffic"
  vpc_id = "${aws_vpc.My_VPC.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/24"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/24"]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["10.0.0.0/24"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "My_Security_Group"
    }
}

#aws route table
resource "aws_route_table" "My_Route_Table" {
  vpc_id = "${aws_vpc.My_VPC.id}"

  route {
    cidr_block = "10.0.0.0/24"
    gateway_id = "${aws_internet_gateway.My_Internet_Gateway.id}"
    }

    tags = {
        Name = "My_Route_Table"
    }
}

#aws internet gateway
resource "aws_internet_gateway" "My_Internet_Gateway" {
  vpc_id = "${aws_vpc.My_VPC.id}"

  tags = {
    Name = "My_Internet_Gateway"
  }
}

#aws route table association
resource "aws_route_table_association" "My_Route_Table_Association" {
  subnet_id = "${aws_subnet.My_Subnet.id}"
  route_table_id = "${aws_route_table.My_Route_Table.id}"
}

output "instance_ip" {
  value = aws_instance.My_EC2.public_ip
}