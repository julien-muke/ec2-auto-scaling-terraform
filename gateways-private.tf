# Elastic IP for NAT gateway
resource "aws_eip" "jm_eip" {
  depends_on = [aws_internet_gateway.jm_gw]
  domain = "vpc"
  tags = {
    Name = "jm_EIP_for_NAT"
  }
}

# NAT gateway for private subnets 
# (for the private subnet to access internet - eg. ec2 instances downloading softwares from internet)
resource "aws_nat_gateway" "jm_nat_for_private_subnet" {
  allocation_id = aws_eip.jm_eip.id
  subnet_id     = aws_subnet.jm_subnet_1a.id # nat should be in public subnet

  tags = {
    Name = "jm NAT for private subnet"
  }

  depends_on = [aws_internet_gateway.jm_gw]
}

# route table - connecting to NAT
resource "aws_route_table" "jm_rt_private" {
  vpc_id = aws_vpc.jm_main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.jm_nat_for_private_subnet.id
  }
}

# associate the route table with private subnet
resource "aws_route_table_association" "jm_rta3" {
  subnet_id      = aws_subnet.jm_subnet_2.id
  route_table_id = aws_route_table.jm_rt_private.id
}