resource "aws_security_group" "allow_ip" {
  name = "allow-my-ip"
  vpc_id = var.vpc_id


  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
cidr_blocks = [var.my_ip]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
