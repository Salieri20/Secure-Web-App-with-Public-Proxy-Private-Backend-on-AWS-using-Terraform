resource "aws_route_table" "rt" {
  vpc_id = var.vpc_id

  tags = {
    Name = var.name
  }
}

resource "aws_route" "route" {
  count = var.subnet_type == "public" ? 1:0 

  route_table_id = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = var.igw_id
}

resource "aws_route" "private_route" {
  count = var.subnet_type == "private" ? 1:0

  route_table_id = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = var.natgw_id
}

resource "aws_route_table_association" "assoc" {
  subnet_id = var.subnet_id
  route_table_id = aws_route_table.rt.id
}