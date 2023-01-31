#aws provider in ohio region
provider "aws" {
  region = "us-east-2"
}

#aws create two subnets with one public and one private, create ec2 instance in public subnet and rds instance in private subnet with mongodb as engine
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
      Name = "vpc"
    }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-2a"
    map_public_ip_on_launch = true
    tags = {
      Name = "public_subnet"
    }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.15.0/24"
    availability_zone = "us-east-2b"
    map_public_ip_on_launch = false
    tags = {
      Name = "private_subnet"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
    tags = {
      Name = "igw"
    }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
    route {
      cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
    tags = {
      Name = "public_route_table"
    }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id = "${aws_subnet.public_subnet.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = "${aws_eip.nat_eip.id}"
    subnet_id = "${aws_subnet.private_subnet.id}"
    tags = {
      Name = "nat_gateway"
    }
}

resource "aws_eip" "nat_eip" {
  vpc = true
    tags = {
      Name = "nat_eip"
    }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
    route {
      cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}"
    }
    tags = {
      Name = "private_route_table"
    }
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id = "${aws_subnet.private_subnet.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_security_group" "public_security_group" {
  name = "public_security_group"
    description = "Allow inbound traffic from the internet"
    vpc_id = "${aws_vpc.vpc.id}"
    ingress {
      from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port = 443
        to_port = 443
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
      Name = "public_security_group"
    }
}

resource "aws_security_group" "private_security_group" {
  name = "private_security_group"
    description = "Allow inbound traffic from the internet"
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
      Name = "private_security_group"
    }
}

resource "aws_instance" "public_instance" {
  ami = "ami-0b69ea66ff7391e80"
    instance_type = "t2.micro"
    key_name = "key"
    subnet_id = "${aws_subnet.public_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.public_security_group.id}"]
    tags = {
      Name = "public_instance"
    }
}

resource "aws_instance" "private_instance" {
  ami = "ami-0b69ea66ff7391e80"
    instance_type = "t2.micro"
    key_name = "key"
    subnet_id = "${aws_subnet.private_subnet.id}"
    vpc_security_group_ids = ["${aws_security_group.private_security_group.id}"]
    tags = {
      Name = "private_instance"
    }
}

resource "aws_eip_association" "public_eip_association" {
  instance_id = "${aws_instance.public_instance.id}"
    allocation_id = "${aws_eip.public_eip.id}"
}

resource "aws_eip" "public_eip" {
  vpc = true
    tags = {
      Name = "public_eip"
    }
}

resource "aws_eip_association" "private_eip_association" {
  instance_id = "${aws_instance.private_instance.id}"
    allocation_id = "${aws_eip.private_eip.id}"
}

resource "aws_eip" "private_eip" {
  vpc = true
    tags = {
      Name = "private_eip"
    }
}

resource "aws_elb" "elb" {
  name = "elb"
    subnets = ["${aws_subnet.public_subnet.id}"]
    security_groups = ["${aws_security_group.public_security_group.id}"]
    listener {
      instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    health_check {
      healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        target = "HTTP:80/"
        interval = 30
    }
    instances = ["${aws_instance.public_instance.id}"]
    tags = {
      Name = "elb"
    }
}

resource "aws_db_instance" "db_instance" {
  identifier = "db_instance"
    allocated_storage = 5
    storage_type = "gp2"
    engine = "mongodb"
    engine_version = "5.7"
    instance_class = "db.t2.micro"
    name = "db"
    username = "user"
    password = "password"
    parameter_group_name = "default.mysql5.7"
    publicly_accessible = true
    vpc_security_group_ids = ["${aws_security_group.private_security_group.id}"]
    db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
    tags = {
      Name = "db_instance"
    }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "db_subnet_group"
    description = "db_subnet_group"
    subnet_ids = ["${aws_subnet.private_subnet.id}"]
    tags = {
      Name = "db_subnet_group"
    }
}







