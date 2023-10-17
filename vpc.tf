# Alle Locals werden innerhalb des locals Block definiert
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "TF VPC"
  }
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "publics" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true # Wir wollen, dass die Instanzen eine öffentliche IP bekommen
  tags = {
    Name = "TF-Public-Subnet-${count.index}",
  }
}
resource "aws_subnet" "privates" {
  count = 3

  vpc_id = aws_vpc.main.id

  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]

  map_public_ip_on_launch = false
  tags = {
    Name = "TF-Private-Subnet-${count.index}"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "TF Internet Gateway"
  }
}

resource "aws_eip" "nateip" {
  count  = 3
  domain = "vpc"
}
# Create NAT-Gateways
resource "aws_nat_gateway" "ngw" {
  count = 3

  allocation_id = aws_eip.nateip[count.index].id
  subnet_id     = aws_subnet.publics[count.index].id

  tags = {
    Name = "TF-NAT-Gateway-${count.index}"
  }

  depends_on = [aws_internet_gateway.gw]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "rtpublic" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"                # Das gesamte Internet
    gateway_id = aws_internet_gateway.gw.id # Link zu unserem erstellten Internet Gateway
  }
  tags = {
    Name = "TF Route Table"
  }
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "a" {
  count          = 3
  subnet_id      = aws_subnet.publics[count.index].id
  route_table_id = aws_route_table.rtpublic.id
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "rtprivate" {
  vpc_id = aws_vpc.main.id
  count = 3
  route {
    cidr_block = "0.0.0.0/0"                # Das gesamte Internet
    gateway_id = aws_nat_gateway.ngw[count.index].id # Link zu unserem erstellten Internet Gateway
  }
  tags = {
    Name = "TF Route Table"
  }
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "p" {
  count          = 3
  subnet_id      = aws_subnet.privates[count.index].id
  route_table_id = aws_route_table.rtprivate[count.index].id
}
