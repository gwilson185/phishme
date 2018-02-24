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

resource "aws_subnet" "lb1" {
  vpc_id     = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.4.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags {
    Name = "lb_1"
  }
}

resource "aws_subnet" "lb2" {
  vpc_id     = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.5.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  tags {
    Name = "lb_2"
  }
}

resource "aws_subnet" "lb3" {
  vpc_id     = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.6.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
  tags {
    Name = "lb_3"
  }
}
resource "aws_subnet" "public1" {
  vpc_id     = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags {
    Name = "public_1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  tags {
    Name = "public_2"
  }
}

resource "aws_subnet" "public3" {
  vpc_id     = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
  tags {
    Name = "public_3"
  }
}

resource "aws_subnet" "rds1" {
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.128.0/25"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags {
    Name = "rds_1"
    Service = "RDS"
  }
}
resource "aws_subnet" "rds2" {
    vpc_id = "${aws_vpc.phishme-vpc.id}"
    cidr_block = "198.18.128.128/25"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    tags {
      Name = "rds_2"
      Service = "RDS"
    }
  }
resource "aws_subnet" "rds3" {
  vpc_id = "${aws_vpc.phishme-vpc.id}"
  cidr_block = "198.18.129.0/25"
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
  tags {
    Name = "rds_3"
    Service = "RDS"
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

resource "aws_route_table_association" "igw_rt_assoc-2" {
  subnet_id      = "${aws_subnet.public2.id}"
  route_table_id = "${aws_route_table.igw_rt.id}"
}

resource "aws_route_table_association" "igw_rt_assoc-3" {
  subnet_id      = "${aws_subnet.public3.id}"
  route_table_id = "${aws_route_table.igw_rt.id}"
}

resource "aws_route_table_association" "igw_rt_assoc-lb" {
  subnet_id      = "${aws_subnet.lb1.id}"
  route_table_id = "${aws_route_table.igw_rt.id}"
}

resource "aws_route_table_association" "igw_rt_assoc-lb2" {
  subnet_id      = "${aws_subnet.lb2.id}"
  route_table_id = "${aws_route_table.igw_rt.id}"
}

resource "aws_route_table_association" "igw_rt_assoc-lb3" {
  subnet_id      = "${aws_subnet.lb3.id}"
  route_table_id = "${aws_route_table.igw_rt.id}"
}


######VPC Flow Logs#########
resource "aws_cloudwatch_log_group" "subnet-flow-log-grp" {
  name = "asg-subnets"
  retention_in_days = 7
}

data "aws_iam_policy_document" "flowlog-logging-policy" {
  statement {
    actions = [
        "sts:AssumeRole"
    ]

    principals {
      identifiers = ["vpc-flow-logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "route53-query-logging-policy" {
  policy_document = "${data.aws_iam_policy_document.flowlog-logging-policy.json}"
  policy_name     = "flow-log-policy"
}
resource "aws_iam_role" "flow-log-role" {
  name = "flow-log-role"
  assume_role_policy = "${data.aws_iam_policy_document.flowlog-logging-policy.json}"
}

resource "aws_iam_role_policy" "flowlog_policy" {
  name = "flowlog_policy"
  role = "${aws_iam_role.flow-log-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_flow_log" "subnet-pub1-flow-log" {
  iam_role_arn = "${aws_iam_role.flow-log-role.arn}"
  log_group_name = "${aws_cloudwatch_log_group.subnet-flow-log-grp.name}"
  traffic_type = "ALL"
  subnet_id = "${aws_subnet.public1.id}"
}

resource "aws_flow_log" "subnet-pub2-flow-log" {
  iam_role_arn = "${aws_iam_role.flow-log-role.arn}"
  log_group_name = "${aws_cloudwatch_log_group.subnet-flow-log-grp.name}"
  traffic_type = "ALL"
  subnet_id = "${aws_subnet.public2.id}"
}

resource "aws_flow_log" "subnet-pub3-flow-log" {
  iam_role_arn = "${aws_iam_role.flow-log-role.arn}"
  log_group_name = "${aws_cloudwatch_log_group.subnet-flow-log-grp.name}"
  traffic_type = "ALL"
  subnet_id = "${aws_subnet.public3.id}"
}