# The "this" is the name (label) of the resource instance so you can reuse in module

resource "aws_security_group" "this" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  tags = {
    Name = var.sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for port in var.ingress_ports : tostring(port) => port }
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.ingress_cidr
  from_port         = each.value
  to_port           = each.value
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
