data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet"
  }
}

resource "aws_subnet" "cluster_public" {
  count         = 2
  vpc_id        = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  cidr_block    = var.cluster_public_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${var.name}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr_block

  tags = {
    Name = "${var.name}-private-subnet"
  }
}

resource "aws_subnet" "cluster_private" {
  count         = 2
  vpc_id        = aws_vpc.vpc.id
  cidr_block    = var.cluster_private_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${var.name}-private-${count.index}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "cluster_public_1" {
  subnet_id      = aws_subnet.cluster_public[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "cluster_public_2" {
  subnet_id      = aws_subnet.cluster_public[1].id
  route_table_id = aws_route_table.public.id
}
