provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_vpc" "client" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags {
        Name = "client_vpc"
    }
}

resource "aws_subnet" "client" {
    vpc_id                  = "${aws_vpc.client.id}"
    cidr_block              = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_az_a}"

    tags {
        Name = "client subnet"
    }
}

resource "aws_internet_gateway" "client_gw" {
    vpc_id = "${aws_vpc.client.id}"

    tags {
        Name = "client_gw"
    }
}

resource "aws_route_table" "r_client" {
    vpc_id = "${aws_vpc.client.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.client_gw.id}"
    }

    tags {
        Name = "aws_route_table_client"
    }
}

resource "aws_route_table_association" "assoc_client" {
    subnet_id      = "${aws_subnet.client.id}"
    route_table_id = "${aws_route_table.r_client.id}"
}

resource "aws_security_group" "client" {
    name        = "client_sg"
    description = "Used in the terraform"

    vpc_id = "${aws_vpc.client.id}"

    # HTTP access from anywhere
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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

    # ensure the VPC has an Internet gateway or this step will fail
    depends_on = ["aws_internet_gateway.client_gw"]
}

resource "aws_instance" "client" {
    ami                         = "${lookup(var.aws_amis, var.aws_region)}"
    instance_type               = "${var.instance_type}"
    availability_zone           = "${var.aws_az_a}"
    associate_public_ip_address = true
    subnet_id                   = "${aws_subnet.client.id}"
    user_data                   = "${file("userdata.sh")}"
    key_name                    = "${var.key_name}"

    # Security group
    vpc_security_group_ids      = ["${aws_security_group.client.id}"]

    tags {
        Name = "ClientBenchmark"
    }
}

output "client_ip" {
  value = ["${aws_instance.client.public_ip}"]
}