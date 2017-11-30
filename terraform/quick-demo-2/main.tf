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

resource "aws_autoscaling_group" "demo-asg" {
    name                 = "demo-svc-asg"
    vpc_zone_identifier  = ["${aws_subnet.svc1.id}", "${aws_subnet.svc2.id}"]
    max_size             = "${var.asg_max}"
    min_size             = "${var.asg_min}"
    desired_capacity     = "${var.asg_desired}"
    force_delete         = true
    launch_configuration = "${aws_launch_configuration.demo-lc.name}"
    health_check_type    = "EC2"
    tag {
        key                 = "Name"
        value               = "demo-svc-asg"
        propagate_at_launch = "true"
    }
}

resource "aws_launch_configuration" "demo-lc" {
    name          = "demo-lc"
    image_id      = "${lookup(var.aws_amis, var.aws_region)}"
    instance_type = "${var.instance_type}"
    associate_public_ip_address = true

    # Security group
    security_groups = ["${aws_security_group.target.id}"]
    user_data       = "${file("userdata.sh")}"
    key_name        = "${var.key_name}"
}
