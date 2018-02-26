########################
## Variables
########################

# Declare the data source
data "aws_availability_zones" "available" {}
#availability_zones = ["${data.aws_availability_zones.available.names}"]


########################
## Cluster
########################

resource "aws_rds_cluster" "mysql-cluster" {

    cluster_identifier            = "redmine-mysql-cluster"
    database_name                 = "mydb"
    master_username               = "mysql_admin"
    master_password               = "${random_string.mysql_password.result}"
    #iam_database_authentication_enabled = true
    engine                        = "aurora"
    engine_version                = "5.6.34"
    backup_retention_period       = 1
    preferred_backup_window       = "02:00-03:00"
    preferred_maintenance_window  = "wed:03:00-wed:04:00"
    availability_zones            = ["${data.aws_availability_zones.available.names[0]}","${data.aws_availability_zones.available.names[1]}","${data.aws_availability_zones.available.names[2]}"]
    db_subnet_group_name          = "${aws_db_subnet_group.mysql_subnet_group.name}"
    skip_final_snapshot           = true
    vpc_security_group_ids        = ["${aws_security_group.rds-security-group.id}"]

    tags {
        Name         = "redmine-mysql-DB-Cluster"
        VPC          = "${aws_vpc.phishme-vpc.id}"
        ManagedBy    = "terraform"

    }
}

resource "aws_rds_cluster_instance" "mysql_cluster_instance" {

    count                 = 2

    identifier            = "mysql-cluster-instance-${count.index}"
    cluster_identifier    = "${aws_rds_cluster.mysql-cluster.id}"
    instance_class        = "db.t2.small"
    db_subnet_group_name  = "${aws_db_subnet_group.mysql_subnet_group.name}"
    publicly_accessible   = false


    tags {
        Name         = "Mysql-DB-Instance-${count.index}"
        VPC          = "${aws_vpc.phishme-vpc.id}"
        ManagedBy    = "terraform"
    }
}

resource "aws_db_subnet_group" "mysql_subnet_group" {

    name          = "mysql_db_subnet_group"
    description   = "subnets for DB cluster instances"
    subnet_ids    = ["${aws_subnet.rds1.id}","${aws_subnet.rds2.id}","${aws_subnet.rds3.id}"]

    tags {
        Name         = "Mysql-DB-Subnet-Group"
        VPC          = "${aws_vpc.phishme-vpc.id}"
        ManagedBy    = "terraform"
    }

}

########################
## Output
########################

output "cluster_address" {
    value = "${aws_rds_cluster.mysql-cluster.endpoint}"}