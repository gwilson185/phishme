provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/Users/georgewilson/.aws/credentials"
  profile                 = "tc-speed"
}

variable "keypair_name" {
  default = "tc-gwilson"
}

resource "random_id" "environment-hash" {
  byte_length = 8
}

resource random_string "mysql_password"
{ length = 20
  special = false
}

 /*data "null_data_source" "credstash-mysql_admin-password" {

  has_computed_default = "${module.credstash.put_cmd} mysql_admin ${random_string.mysql_password.result}"
}
*/

resource "aws_iam_user" "redmine_user" {
  name = "redmine-${random_id.environment-hash.hex}"
}

/* resource "aws_iam_policy" "rds_policy" {
  name        = "rds_policy"
  path        = "/"
  description = "RDS access policy"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
             "rds-db:connect"
         ],
         "Resource": [
${aws_rds_cluster.mysql-cluster.id},
             "arn:aws:rds-db:us-west-2:123456789012:dbuser:cluster-CO4FHMOYDKJ7CVBEJS2UWDQX7I/jane_doe"
         ]
      }
   ]
}
EOF
}
*/

resource "aws_instance" "bastion-host" {
  # Using AMazon Linux latest AMI
  ami = "ami-97785bed"
  instance_type = "t2.micro"
  key_name = "${var.keypair_name}"
  subnet_id = "${aws_subnet.public1.id}"
  vpc_security_group_ids = [ "${aws_security_group.ssh-inbound.id}", "${aws_security_group.bastion-security-group.id}"]

  connection {
     Type = "ssh"
    user = "ec2-user"
     private_key = "${file("../tc-gwilson.pem")}"
  }

  user_data = "sudo yum update -y\n,sudo reboot\n"
tags {
  Name  = "Bastion-host"
}
}

##### Outputs ##########
output "bastion-host" {
  value = "ssh://${aws_instance.bastion-host.public_dns}"
}

output "mysql_admin_password" {
  value = "${random_string.mysql_password.result}"
}