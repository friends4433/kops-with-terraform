# This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

##Varibles 
variable "vpc_cidr" {}
variable "vpc_name" {}
variable "environment" {}
variable "IGW_name" {}
variable "public_subnet1_cidr" {}
variable "public_subnet2_cidr" {}
variable "public_subnet3_cidr" {}
variable "public_subnet1_name" {}
variable "public_subnet2_name" {}
variable "public_subnet3_name" {}
variable "sgname" {}
variable "Main_Routing_Table" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

##TFVars
vpc_cidr = "10.91.0.0/16"
vpc_name = "Kubernets-VPC"
environment = "Prod"
IGW_name = "Kubernets-VPC-IGW"
public_subnet1_cidr = "10.91.1.0/24"
public_subnet2_cidr = "10.91.2.0/24"
public_subnet3_cidr = "10.91.3.0/24"
public_subnet1_name = "Kubernets-Subnet-1"
public_subnet2_name = "Kubernets-Subnet-2"
public_subnet3_name = "Kubernets-Subnet-3"
sgname = "Kubernet_Allow_All_SG"
Main_Routing_Table = "Kubernets-Mail-RT"
# aws_access_key = "XXXXX"
# aws_secret_key = "XXXXX"
aws_region = "us-east-1"


##VPC Creation
resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "${var.vpc_name}"
	Owner = "Ram"
	Env =  "prod"
	environment = "${var.environment}"
    }
}
resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
	tags = {
        Name = "${var.IGW_name}"
    }
}

##Sunets Creation
resource "aws_subnet" "subnet1-public" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.public_subnet1_cidr}"
    availability_zone = "us-east-1a"

    tags = {
        Name = "${var.public_subnet1_name}"
    }
}

resource "aws_subnet" "subnet2-public" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.public_subnet2_cidr}"
    availability_zone = "us-east-1b"

    tags = {
        Name = "${var.public_subnet2_name}"
    }
}

resource "aws_subnet" "subnet3-public" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.public_subnet3_cidr}"
    availability_zone = "us-east-1c"

    tags = {
        Name = "${var.public_subnet3_name}"
    }
	
}

##Routing Table
 resource "aws_route_table" "terraform-public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags = {
        Name = "${var.Main_Routing_Table}"
    }
}

resource "aws_route_table_association" "terraform-public1" {
    subnet_id = "${aws_subnet.subnet1-public.id}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}

resource "aws_route_table_association" "terraform-public2" {
    subnet_id = "${aws_subnet.subnet2-public.id}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}

resource "aws_route_table_association" "terraform-public3" {
    subnet_id = "${aws_subnet.subnet3-public.id}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}

##Security Group Cration
resource "aws_security_group" "allow_all" {
  name        = "${var.sgname}"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    }
    tags = {
    Name = "${var.vpc_name}-SG-Allow-All"
}
}

##S3 Creation
resource "aws_s3_bucket" "s3" {
  bucket = "rbpatnam.live"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "Kubernets-Configs-Files"
    Environment = "Prod"
  }
}

##EC2 Creation
data "template_file" "ec2_user_data" {
  template = file("${path.cwd}/Stratup.txt")
}
resource "aws_instance" "web-1" {
  ami                         = "ami-0261755bbcb8c4a84"
  availability_zone           = "us-east-1a"
  instance_type               = "t2.micro"
  key_name                    = "Desktop-Kye"
  subnet_id                   = aws_subnet.subnet1-public.id
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address = true
  user_data                   = data.template_file.ec2_user_data.template
  tags = {
    Name       = "Kubernets-MGMT-SVR"
    Env        = "Prod"
    }
}


