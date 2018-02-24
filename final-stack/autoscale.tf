resource "aws_launch_configuration" "agent-lc" {
    name_prefix = "launch-config-"
    image_id = "ami-97785bed"
    key_name = "${var.keypair_name}"
    instance_type = "t2.micro"
    user_data = <<-EOF
                #!/usr/bin/env bash
                yum update -y
                yum install -y docker nfs-utils
                sysctl net.ipv4.conf.all.forwarding=1
                iptables -P FORWARD ACCEPT
                service docker restart
                docker pull redmine
                mkdir /efs
                chmod go+rw /efs
                mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${aws_efs_file_system.redmine-filestore.dns_name}:/ /efs
                docker run -d -p 80:3000 --mount type=bind,source=/efs,target=/usr/src/redmine/files --env REDMINE_DB_MYSQL=${aws_rds_cluster.mysql-cluster.endpoint} --env REDMINE_DB_USERNAME=${aws_rds_cluster.mysql-cluster.master_username} --env REDMINE_DB_PASSWORD=${aws_rds_cluster.mysql-cluster.master_password} --env REDMINE_DB_DATABASE=${aws_rds_cluster.mysql-cluster.database_name} redmine

                EOF
    security_groups = ["${aws_security_group.asg-target-security-group.id}", "${aws_security_group.rds-access.id}","${aws_security_group.efs-access.id}"]
    lifecycle {
        create_before_destroy = true
    }

    root_block_device {
        volume_type = "gp2"
        volume_size = "10"
    }

  depends_on = ["aws_rds_cluster_instance.mysql_cluster_instance", "aws_efs_file_system.redmine-filestore"]
}

resource "aws_autoscaling_group" "redmin_asg" {
    #availability_zones = ["${data.aws_availability_zones.available.names[0]}","${data.aws_availability_zones.available.names[1]}","${data.aws_availability_zones.available.names[2]}"]
    name = "redmine-agent"
    max_size = "5"
    min_size = "1"
    health_check_grace_period = 300
    health_check_type = "ELB"
    desired_capacity = 2
    vpc_zone_identifier = ["${aws_subnet.public1.id}","${aws_subnet.public2.id}","${aws_subnet.public3.id}"]
    force_delete = true
    launch_configuration = "${aws_launch_configuration.agent-lc.name}"

    tag {
        key = "Name"
        value = "redmine-instance"
        propagate_at_launch = true
    }
}

resource "aws_autoscaling_policy" "agents-scale-up" {
    name = "agents-scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.redmin_asg.name}"
}

resource "aws_autoscaling_policy" "agents-scale-down" {
    name = "agents-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.redmin_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.agents-scale-up.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.redmin_asg.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "1200"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.agents-scale-down.arn}"
    ]
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.redmin_asg.name}"
    }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = "${aws_autoscaling_group.redmin_asg.id}"
  alb_target_group_arn   = "${aws_alb_target_group.alb_targets.arn}"
}