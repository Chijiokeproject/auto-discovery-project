# Creating the VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.name}_vpc"
  }
}

# Create public subnets
resource "aws_subnet" "pub_sub1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "${var.name}_pub_sub1"
  }
}

resource "aws_subnet" "pub_sub2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-1c"

  tags = {
    Name = "${var.name}_pub_sub2"
  }
}

# Create private subnets
resource "aws_subnet" "pri_sub1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "${var.name}_pri_sub1"
  }
}

resource "aws_subnet" "pri_sub2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-1c"

  tags = {
    Name = "${var.name}_pri_sub2"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}_igw"
  }
}

# Create elastic IP for NAT gateway
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "${var.name}_eip"
  }
}

# Create NAT gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub_sub1.id

  tags = {
    Name = "${var.name}_ngw"
  }
  depends_on = [aws_eip.eip]
}

# Public route table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name}_pub_rt"
  }
}

# Private route table
resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "${var.name}_pri_rt"
  }
}

# Route table associations
resource "aws_route_table_association" "ass_pub_sub1" {
  subnet_id      = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_route_table_association" "ass_pub_sub2" {
  subnet_id      = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_route_table_association" "ass_pri_sub1" {
  subnet_id      = aws_subnet.pri_sub1.id
  route_table_id = aws_route_table.pri_rt.id
}
resource "aws_route_table_association" "ass_pri_sub2" {
  subnet_id      = aws_subnet.pri_sub2.id
  route_table_id = aws_route_table.pri_rt.id
}

# TLS private key for keypair
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Local file for private key
resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "${var.name}_key.pem"
  file_permission = "440"
}

# AWS key pair
resource "aws_key_pair" "public_key" {
  key_name   = "${var.name}_infra_key"
  public_key = tls_private_key.key.public_key_openssh
}