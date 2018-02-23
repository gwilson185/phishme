resource "aws_security_group" "ssh-inbound" {
  name = "ssh-inbound"
  vpc_id = "${aws_vpc.phishme-vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds-access" {
  name = "rds-access"
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  description = "Allow resources in VPC to access MySQL Instances"
#Allows resources to connect to RDS
  egress {
    from_port   = "3306"
    to_port     = "3306"
    protocol    = "tcp"
    cidr_blocks = ["198.18.128.0/17"]
}
}

resource "aws_security_group" "rds-security-group" {
  name = "rds-security-group"
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  description = "Security Group for RDS allowing members of rds-access access"
  #Allows members of rds-access group to connect
  ingress {
    from_port = "3306"
    to_port = "3306"
    protocol = "tcp"
    security_groups = ["${aws_security_group.rds-access.id}"]
  }
}
resource "aws_security_group" "web-inbound" {
  name = "web-inbound"
  vpc_id = "${aws_vpc.phishme-vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb-security-group" {
  name = "lb-security-group"
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  description = "Security Group for the Load Balancer"
  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    security_groups = ["${aws_security_group.asg-target-security-group.id}"]
}
  egress {
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    security_groups = ["${aws_security_group.asg-target-security-group.id}"]
}

}

resource "aws_security_group" "bastion-security-group" {
  name = "bastion-security-group"
  vpc_id = "${aws_vpc.phishme-vpc.id}"

  egress {
    from_port = 0
    protocol = "tcp"
    to_port = 0
    cidr_blocks = ["198.18.0.0/17"]
  }
}

resource "aws_network_acl" "lb-network-acl" {
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  subnet_ids = ["${aws_subnet.lb1.id}","${aws_subnet.lb2.id}","${aws_subnet.lb3.id}"]
  ingress {
    action = "allow"
    from_port = 80
    protocol = "tcp"
    rule_no = 100
    to_port = 80
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    action = "allow"
    from_port = 0
    icmp_code = 0
    protocol = "icmp"
    rule_no = 200
    to_port = 0
    cidr_block = "198.18.0.0/17"
  }

  egress {
    action = "allow"
    from_port = 1024
    protocol = "tcp"
    rule_no = 100
    to_port = 65535
    cidr_block = "0.0.0.0/0"
  }
egress {
    action = "allow"
    from_port = 80
    protocol = "tcp"
    rule_no = 200
    to_port = 80
    cidr_block = "198.18.0.0/17"
  }
  egress {
    action = "allow"
    from_port = 0
    icmp_code = -1
    protocol = "icmp"
    rule_no = 300
    to_port = 0
    cidr_block = "0.0.0.0/0"
  }

}

resource "aws_network_acl" "asg-target-network-acl" {
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  subnet_ids = ["${aws_subnet.public1.id}","${aws_subnet.public2.id}","${aws_subnet.public3.id}"]
  ingress {
    action = "allow"
    from_port = 80
    protocol = "tcp"
    rule_no = 100
    to_port = 80
    cidr_block = "198.18.0.0/17"
  }
  ingress {
    action = "allow"
    from_port = 0
    icmp_code = 0
    protocol = "icmp"
    rule_no = 200
    to_port = 0
    cidr_block = "198.18.0.0/17"
  }
  ingress {
    action = "allow"
    from_port = 22
    protocol = "tcp"
    rule_no = 400
    to_port = 22
    cidr_block = "198.18.0.0/17"
  }

  egress {
    action = "allow"
    from_port = 1024
    protocol = "tcp"
    rule_no = 100
    to_port = 65535
    cidr_block = "198.18.0.0/16"
  }
egress {
    action = "allow"
    from_port = 80
    protocol = "tcp"
    rule_no = 200
    to_port = 80
    cidr_block = "198.18.0.0/17"
  }
  egress {
    action = "allow"
    from_port = 0
    icmp_code = 8
    protocol = "icmp"
    rule_no = 300
    to_port = 0
    cidr_block = "0.0.0.0/0"
  }

}

resource "aws_security_group" "asg-target-security-group" {
  name = "asg-target-security-group"
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  description = "Security Group for the ASG Targets"
  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["198.18.0.0/16"]
  }
  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "icmp"
    cidr_blocks = ["198.18.0.0/16"]
}
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    security_groups = ["${aws_security_group.bastion-security-group.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_security_group" "efs-security-group" {
  name = "efs-security-group"
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  description = "Security Group for EFS allowing members of efs-access access"
  #Allows members of rds-access group to connect
  ingress {
    from_port = "2049"
    to_port = "2049"
    protocol = "tcp"
    security_groups = ["${aws_security_group.efs-access.id}"]
  }
}

resource "aws_security_group" "efs-access" {
  name = "efs-access"
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  description = "Allow resources in VPC to access EFS"
#Allows resources to connect to EFS
  egress {
    from_port   = "2049"
    to_port     = "2049"
    protocol    = "tcp"
    cidr_blocks = ["198.18.128.0/17"]
}
}