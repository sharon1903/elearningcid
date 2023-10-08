#Create VPC
resource "aws_vpc" "e-learning" {
  cidr_block       = var.vpc-cidr-block
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "e-learning"
  }
}

#Declare the data source
data "aws_availability_zones" "eaz" {}

#Create Public subnet1
 resource "aws_subnet" "e-learningpub1" {
  vpc_id     = aws_vpc.e-learning.id
  cidr_block = var.pubsub1-cidr-block
  availability_zone = data.aws_availability_zones.eaz.names[0]


  map_public_ip_on_launch =true

  tags = {
    Name = "e-learningPub1"
  }
}

#Create Public subnet2
resource "aws_subnet" "e-learningpub2" {
  vpc_id     = aws_vpc.e-learning.id
  cidr_block = var.pubsub2-cidr-block
  availability_zone =  data.aws_availability_zones.eaz.names[1]

  map_public_ip_on_launch =true

  tags = {
    Name = "e-learningPub2"
  }
}

#Create Private subnet1
resource "aws_subnet" "e-learningpriv1" {
  vpc_id     = aws_vpc.e-learning.id
  cidr_block = var.privsub1-cidr-block
  availability_zone = data.aws_availability_zones.eaz.names[0]
  

  tags = {
    Name = "e-learningPriv1"
  }
}

#Create Private subnet2
resource "aws_subnet" "e-learningpriv2" {
  vpc_id     = aws_vpc.e-learning.id
  cidr_block = var.privsub2-cidr-block
  availability_zone = data.aws_availability_zones.eaz.names[1]
  

  tags = {
    Name = "e-learningPriv2"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "e-learningIGW" {
  vpc_id = aws_vpc.e-learning.id

  tags = {
    Name = "e-learningIGW"
  }
}

#Create elastic IP
resource "aws_eip" "e-learning-eip" {
  domain   = "vpc"
  tags = {
        Name = "e-learning-eip"

    }
}

#NAT Gateway
resource "aws_nat_gateway" "e-learningNGW" {
  allocation_id = aws_eip.e-learning-eip.id
  subnet_id     = aws_subnet.e-learningpub1.id

  tags = {
    Name = "e-learningNGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.e-learningIGW]
}

#Public Route Table 
resource "aws_route_table" "e-learningPubRT" {
  vpc_id = aws_vpc.e-learning.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.e-learningIGW.id
  }

}

#Private Route Table 
resource "aws_route_table" "e-learningPrivRT" {
  vpc_id = aws_vpc.e-learning.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.e-learningNGW.id
  }
}

  #Route table association -Public subnet 1
  resource "aws_route_table_association" "Rt-assoc-pub-subnet1" {
  subnet_id      = aws_subnet.e-learningpub1.id
  route_table_id = aws_route_table.e-learningPubRT.id
}

#Route table association -Public subnet 2
  resource "aws_route_table_association" "Rt-assoc-pub-subnet2" {
  subnet_id      = aws_subnet.e-learningpub2.id
  route_table_id = aws_route_table.e-learningPubRT.id
}

#Route table association -Private subnet1
  resource "aws_route_table_association" "Rt-assoc-priv-subnet1" {
  subnet_id      = aws_subnet.e-learningpriv1.id
  route_table_id = aws_route_table.e-learningPrivRT.id
}

#Route table association -Private subnet2
  resource "aws_route_table_association" "Rt-assoc-priv-subnet2" {
  subnet_id      = aws_subnet.e-learningpriv2.id
  route_table_id = aws_route_table.e-learningPrivRT.id
}


