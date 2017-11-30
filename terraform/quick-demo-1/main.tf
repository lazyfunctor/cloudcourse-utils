provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_vpc" "svc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags {
        Name = "demo_svc"
    }
}

resource "aws_subnet" "svc1" {
    vpc_id                  = "${aws_vpc.svc.id}"
    cidr_block              = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_az_a}"

    tags {
        Name = "svc1"
    }
}

resource "aws_subnet" "svc2" {
    vpc_id                  = "${aws_vpc.svc.id}"
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_az_b}"
  
    tags {
        Name = "svc2"
    }
}

resource "aws_internet_gateway" "svc_gw" {
    vpc_id = "${aws_vpc.svc.id}"

    tags {
        Name = "svc_gw"
    }
}

resource "aws_route_table" "r" {
    vpc_id = "${aws_vpc.svc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.svc_gw.id}"
    }

    tags {
        Name = "aws_route_table_svc"
    }
}

resource "aws_route_table_association" "a1" {
    subnet_id      = "${aws_subnet.svc1.id}"
    route_table_id = "${aws_route_table.r.id}"
}

resource "aws_route_table_association" "a2" {
    subnet_id      = "${aws_subnet.svc2.id}"
    route_table_id = "${aws_route_table.r.id}"
}


resource "aws_security_group" "target" {
    name        = "target_group_sg"
    description = "Demo - Security group for target group"
    vpc_id      = "${aws_vpc.svc.id}"

    # SSH access from anywhere
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # HTTP access from anywhere
    ingress {
        from_port   = 4500
        to_port     = 4500
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "elb" {
    name        = "elb_sg"
    description = "Used in the terraform"

    vpc_id = "${aws_vpc.svc.id}"

    # HTTP access from anywhere
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # outbound internet access
    egress {
        from_port   = 4500
        to_port     = 4500
        protocol    = "tcp"
        security_groups = ["${aws_security_group.target.id}"]
    }

    # ensure the VPC has an Internet gateway or this step will fail
    depends_on = ["aws_internet_gateway.svc_gw"]
}

resource "aws_alb_target_group" "demo" {
    name     = "demo"
    port     = 4500
    protocol = "HTTP"
    vpc_id   = "${aws_vpc.svc.id}"
    health_check {
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        matcher             = 200
    }
}

resource "aws_instance" "instance1" {
    ami           = "${lookup(var.aws_amis, var.aws_region)}"
    instance_type = "t2.micro"
    subnet_id     = "${aws_subnet.svc1.id}"
    vpc_security_group_ids = ["${aws_security_group.target.id}"]
    associate_public_ip_address = true
    user_data                   = "${file("userdata.sh")}"
    key_name                    = "${var.key_name}"

    tags {
        Name = "Instance1"
    }
}

resource "aws_instance" "instance2" {
    ami           = "${lookup(var.aws_amis, var.aws_region)}"
    instance_type = "t2.micro"
    subnet_id     = "${aws_subnet.svc2.id}"
    vpc_security_group_ids = ["${aws_security_group.target.id}"]
    associate_public_ip_address = true
    user_data                   = "${file("userdata.sh")}"
    key_name                    = "${var.key_name}"

    tags {
        Name = "Instance2"
    }
}

resource "aws_alb_target_group_attachment" "instance1" {
  target_group_arn = "${aws_alb_target_group.demo.arn}"
  target_id        = "${aws_instance.instance1.id}"
}

resource "aws_alb_target_group_attachment" "instance2" {
  target_group_arn = "${aws_alb_target_group.demo.arn}"
  target_id        = "${aws_instance.instance2.id}"
}

resource "aws_alb" "demo" {
    name            = "demo"
    subnets         = ["${aws_subnet.svc1.id}", "${aws_subnet.svc2.id}"]
    security_groups = ["${aws_security_group.elb.id}"]
    idle_timeout    = 240
}

resource "aws_alb_listener" "demo" {
  load_balancer_arn = "${aws_alb.demo.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.demo.arn}"
    type             = "forward"
  }
}
