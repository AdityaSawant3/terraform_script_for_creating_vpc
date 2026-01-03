resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_instance_ssh.id]

  # Public instance requires the ssh key to connect.
  key_name = var.ssh_key
  tags = {
    Name = "Public-Instance"
  }
}

resource "aws_instance" "private_server" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_instance_ssh.id]

  # Private instance requires the ssh key to connect.
  key_name = var.ssh_key

  tags = {
    Name = "Private-Instance"
  }
}

# VPC function
resource "aws_vpc" "terraform_created_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = var.instance_tenancy

  tags = {
    Name = "terraform_created_vpc"
  }
}

# public and private subnets.
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.terraform_created_vpc.id
    cidr_block = var.public_subnet_cidr_block
    map_public_ip_on_launch = true

    tags = {
        Name = "public_subnet"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.terraform_created_vpc.id
    cidr_block = var.private_subnet_cidr_block

    tags = {
        Name = "private_subnet"
    }
}

# Internet gateway setup
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_created_vpc.id

  tags = {
    Name = "terraform_igw"
  }
}

# Route table for public subnet.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terraform_created_vpc.id

  route {
    cidr_block = var.internet_access
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# Associate the route table to public subnet.
resource "aws_route_table_association" "public_assocaition" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# To connect to the instance you need a security group wiht ssh rule.

resource "aws_security_group" "public_instance_ssh" {
  name        = "terraform_public_instance"
  description = "Contain ssh"
  vpc_id      = aws_vpc.terraform_created_vpc.id
  tags = {
    Name = "public_instance_ssh"
  }
}

resource "aws_security_group" "private_instance_ssh" {
  name        = "terraform_private_instance"
  description = "Contain ssh"
  vpc_id      = aws_vpc.terraform_created_vpc.id
  tags = {
    Name = "private_instance_ssh"
  }
}

# SG inbound rule.
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.public_instance_ssh.id

  cidr_ipv4   = var.my_ip
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_security_group_rule" "private_ssh_from_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
# Dont specify vpc cidr here.
  security_group_id = aws_security_group.private_instance_ssh.id
  source_security_group_id = aws_security_group.public_instance_ssh.id
}

# Outbound access for both the subnets.

resource "aws_vpc_security_group_egress_rule" "public_instance_outbound" {
  security_group_id = aws_security_group.public_instance_ssh.id

  cidr_ipv4   = var.internet_access
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "private_instance_outbound" {
  security_group_id = aws_security_group.private_instance_ssh.id
  cidr_ipv4   = var.internet_access
  ip_protocol = "-1"
 
}

# Elastic IP creation.
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat_gateway_eip"
  }
}

# Nat gateway.
resource "aws_nat_gateway" "terraform_ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "terraform_ngw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.terraform_igw]
}

# Route Table for private subnets.
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.terraform_created_vpc.id

  # since this is exactly the route AWS will create, the route will be adopted
  route {
    cidr_block = var.internet_access
    nat_gateway_id = aws_nat_gateway.terraform_ngw.id
  }

  tags = {
    Name = "private_rt"
  }
}

# Associate Private subnets to the route_table.
resource "aws_route_table_association" "private_assocaition" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}
