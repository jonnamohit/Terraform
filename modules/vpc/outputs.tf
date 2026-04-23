output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "private_subnets" {
  value = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
}

output "public_subnets" {
  value = [
    aws_subnet.public1.id
  ]
}
