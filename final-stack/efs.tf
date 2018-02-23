

resource "aws_efs_file_system" "redmine-filestore" {
  creation_token = "redmine-${random_id.environment-hash.hex}"
  performance_mode = "generalPurpose"

  tags {
    ManagedBy = "terraform"
  }
}

resource "aws_efs_mount_target" "mount-a" {
  file_system_id = "${aws_efs_file_system.redmine-filestore.id}"
  subnet_id      = "${aws_subnet.rds1.id}"
  security_groups = ["${aws_security_group.efs-security-group.id}"]
}

resource "aws_efs_mount_target" "mount-b" {
  file_system_id = "${aws_efs_file_system.redmine-filestore.id}"
  subnet_id      = "${aws_subnet.rds2.id}"
  security_groups = ["${aws_security_group.efs-security-group.id}"]
}

resource "aws_efs_mount_target" "mount-c" {
  file_system_id = "${aws_efs_file_system.redmine-filestore.id}"
  subnet_id      = "${aws_subnet.rds3.id}"
  security_groups = ["${aws_security_group.efs-security-group.id}"]
}