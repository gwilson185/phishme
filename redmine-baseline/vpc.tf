###### VPC Section #########
resource "aws_vpc" "phishme-vpc" {
  cidr_block = "198.18.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags {
    Name = "phishme-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.phishme-vpc.id}"
}

resource "aws_subnet" "public1" {
  vpc_id     = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.1.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "public_1"
  }
}

resource "aws_route_table" "igw_rt" {
  vpc_id = "${aws_vpc.phishme-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "main"
  }
}

resource "aws_route_table_association" "igw_rt_assoc" {
  subnet_id      = "${aws_subnet.public1.id}"
  route_table_id = "${aws_route_table.igw_rt.id}"
}
