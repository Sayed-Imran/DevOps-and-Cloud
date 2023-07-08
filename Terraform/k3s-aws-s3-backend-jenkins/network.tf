resource "aws_vpc" "kubernetes-aws-vpc" {
  tags = {
    Name = "kubernetes-aws-vpc"
  }
  cidr_block = "10.20.0.0/16"
}

resource "aws_internet_gateway" "int-gw" {
  vpc_id = aws_vpc.kubernetes-aws-vpc.id
}


resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.kubernetes-aws-vpc.id

}

resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.int-gw.id
}

resource "aws_main_route_table_association" "main-route-table" {
  vpc_id         = aws_vpc.kubernetes-aws-vpc.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.kubernetes-aws-vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "subnet-table-association" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_security_group" "kubernetes-aws-sg" {
  name        = "kubernetes-aws-sg"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.kubernetes-aws-vpc.id


  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}