terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.2.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${var.environment}-${var.application_name}-vpc"
    Location = "${var.location}"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-${var.application_name}-public_subnet"
    Location = "${var.location}"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "${var.environment}-${var.application_name}-igw"
    Location = "${var.location}"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-${var.application_name}-route-table-public"
    Location = "${var.location}"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id

}


resource "aws_security_group" "web_sg" {
  name   = "SSH"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-${var.application_name}-web-sg"
    Location = "${var.location}"
    Environment = "${var.environment}"
  }
}

resource "aws_key_pair" "leon" {
  key_name   = "leon-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFul1dKr5rwuqpkj2uucuh0x4QLyASfyvyddqTDXYKGDr"
}

resource "aws_instance" "public_instance" {
  count = 4
  ami           = "ami-0b0c5a84b89c4bf99"
  instance_type = "t3.small"
  key_name      = aws_key_pair.leon.key_name

  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = {
    Name = "${var.environment}-${var.application_name}-${count.index}"
    Location = "${var.location}"
    Environment = "${var.environment}"
  }
}