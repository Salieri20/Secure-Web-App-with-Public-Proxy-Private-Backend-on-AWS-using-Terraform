resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = var.name
  }

  depends_on = [aws_eip.eip]
}

