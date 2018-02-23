provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/Users/georgewilson/.aws/credentials"
  profile                 = "tc-speed"
}


####### Security Groups ########

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_security_group" "web-inbound" {
  name = "web-inbound"
  vpc_id = "${aws_vpc.phishme-vpc.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

##### Redmine App #########
resource "aws_instance" "redmine" {
  # Using AMazon Linux latest AMI
  ami = "ami-97785bed"
  instance_type = "t2.micro"
  key_name = "tc-gwilson"
  subnet_id = "${aws_subnet.public1.id}"
  vpc_security_group_ids = [ "${aws_security_group.ssh-inbound.id}","${aws_security_group.web-inbound.id}"]

  connection {
     Type = "ssh"
    user = "ec2-user"
     private_key = "${file("../tc-gwilson.pem")}"
  }

  provisioner "remote-exec" {
                inline = [ "sudo yum install -y docker",
                          "sudo service docker restart",
                          "sudo docker run -d -p 80:3000 redmine"]
  }
}


##### Outputs ##########
output "web_server" {
  value = "${aws_instance.redmine.public_dns}"
}