# ---------------- VPC ----------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
    Environment = "dev"
  }
}

# ---------------- INTERNET GATEWAY ----------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# ---------------- PUBLIC SUBNET ----------------
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets_cidr[0]
  map_public_ip_on_launch = true
  availability_zone       = var.azs[0]

  tags = {
    Name = "${var.project_name}-public-subnet-${var.azs[0]}"
    Type = "Public"
  }
}

# ---------------- PRIVATE SUBNETS ----------------
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidr[0]
  availability_zone = var.azs[0]

  tags = {
    Name = "${var.project_name}-private-subnet-${var.azs[0]}"
    Type = "Private"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidr[1]
  availability_zone = var.azs[1]

  tags = {
    Name = "${var.project_name}-private-subnet-${var.azs[1]}"
    Type = "Private"
  }
}

# ---------------- PUBLIC ROUTE TABLE ----------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
    Type = "Public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- ELASTIC IP ----------------
resource "aws_eip" "nat" {
  domain = "vpc"
}

# ---------------- NAT GATEWAY ----------------
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id

  depends_on = [aws_internet_gateway.igw]
}

# ---------------- PRIVATE ROUTE TABLE ----------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
    Type = "Private"
  }
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# ---------------- ASSOCIATE PRIVATE SUBNETS ----------------
resource "aws_route_table_association" "private_assoc1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}