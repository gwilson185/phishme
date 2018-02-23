resource "aws_alb" "redmine-alb" {
  name = "redmin-alb-${random_id.environment-hash.hex}"
  internal = false
  subnets = ["${aws_subnet.lb1.id}","${aws_subnet.lb2.id}","${aws_subnet.lb3.id}"]
  security_groups = ["${aws_security_group.lb-security-group.id}"]

  enable_deletion_protection = false

 /* access_logs {
    bucket = "${aws_s3_bucket.log_bucket.bucket}"
    prefix = "ALB-Logs"
  } */
}

/*resource "aws_s3_bucket_policy" "log_bucket-policy" {
  bucket = "${aws_s3_bucket.log_bucket.id}"
  policy = <<-EOF
          {
  "Id": "Policy1429136655940",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1429136633762",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.log_bucket.arn}/*",
      "Principal": {
        "AWS": [
          "127311923021"
        ]
      }
    }
  ]
}
          EOF
}*/

resource "aws_s3_bucket" "log_bucket" {
  bucket = "alb-logs-${random_id.environment-hash.hex}"

}

resource "aws_alb_target_group" "alb_targets" {
  port      = "80"
  protocol  = "HTTP"
  vpc_id    = "${aws_vpc.phishme-vpc.id}"


  stickiness {
    type = "lb_cookie"
    cookie_duration = 3600
    enabled = true
  }

  health_check {
    healthy_threshold   = 2
    interval            = 15
    path                = "/"
    timeout             = 10
    unhealthy_threshold = 2
  }

}

resource "aws_lb_listener" "web_80" {
  load_balancer_arn = "${aws_alb.redmine-alb.arn}"
  port              = "80"
  protocol          = "HTTP"


  default_action {
    target_group_arn = "${aws_alb_target_group.alb_targets.arn}"
    type             = "forward"
  }
}

output "lb_dns" {
  value = "http://${aws_alb.redmine-alb.dns_name}"
}