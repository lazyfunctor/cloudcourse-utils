provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_vpc" "dc_vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags {
        Name = "discourse_vpc"
    }
}

resource "aws_subnet" "dc_net1" {
    vpc_id                  = "${aws_vpc.dc_vpc.id}"
    cidr_block              = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_az_a}"

    tags {
        Name = "discourse subnet1"
    }
}

resource "aws_subnet" "dc_net2" {
    vpc_id                  = "${aws_vpc.dc_vpc.id}"
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_az_b}"
  
    tags {
        Name = "discourse subnet2"
    }
}

resource "aws_internet_gateway" "dc_gw" {
    vpc_id = "${aws_vpc.dc_vpc.id}"

    tags {
        Name = "discourse gw"
    }
}

resource "aws_route_table" "dc_r" {
    vpc_id = "${aws_vpc.dc_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.dc_gw.id}"
    }

    tags {
        Name = "discourse route table public"
    }
}

resource "aws_route_table_association" "dc_a1" {
    subnet_id      = "${aws_subnet.dc_net1.id}"
    route_table_id = "${aws_route_table.dc_r.id}"
}

resource "aws_route_table_association" "dc_a2" {
    subnet_id      = "${aws_subnet.dc_net2.id}"
    route_table_id = "${aws_route_table.dc_r.id}"
}

resource "aws_security_group" "dc_server" {
    name        = "discourse_server_sg"
    description = "Security group for discourse server app"
    vpc_id      = "${aws_vpc.dc_vpc.id}"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
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


resource "aws_security_group" "dc_db" {
    name        = "discourse_db_sg"
    description = "Security group for discourse database"
    vpc_id      = "${aws_vpc.dc_vpc.id}"

    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        security_groups = ["${aws_security_group.dc_server.id}"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "dc_ec" {
    name        = "discourse_ec_sg"
    description = "Security group for discourse elastic cache"
    vpc_id      = "${aws_vpc.dc_vpc.id}"

    ingress {
        from_port   = 6379
        to_port     = 6379
        protocol    = "tcp"
        security_groups = ["${aws_security_group.dc_server.id}"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_db_subnet_group" "dc_db_subnet_grp" {
  name       = "dc-db-subnet-grp"
  subnet_ids = ["${aws_subnet.dc_net1.id}", "${aws_subnet.dc_net2.id}"]

  tags {
    Name = "Discourse DB subnet group"
  }

}

resource "aws_db_instance" "dc_db" {
  identifier          = "discourse-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "9.6.3"
  instance_class       = "db.t2.micro"
  name                 = "discourse"
  username             = "root"
  password             = "${var.master_db_password}"
  db_subnet_group_name = "${aws_db_subnet_group.dc_db_subnet_grp.name}"
  publicly_accessible  = false
  skip_final_snapshot  = true
  vpc_security_group_ids = ["${aws_security_group.dc_db.id}"]
  timeouts {
    create = "30m"
    delete = "2h"
  }
}


resource "aws_elasticache_subnet_group" "dc_cache_subgrp" {
  name       = "dc-cache-subgrp"
  subnet_ids = ["${aws_subnet.dc_net1.id}", "${aws_subnet.dc_net2.id}"]
}

resource "aws_elasticache_cluster" "dc_cache" {
  cluster_id           = "discourse-cache"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  subnet_group_name    = "${aws_elasticache_subnet_group.dc_cache_subgrp.name}"
  security_group_ids   = ["${aws_security_group.dc_ec.id}"]
}

data "template_file" "discourse_config" {
  template     = "${file("discourse.conf")}"
  depends_on   = ["aws_elasticache_cluster.dc_cache", "aws_db_instance.dc_db"]

  vars {
    host_name = "${var.host_name}"
    developer_emails = "${var.developer_emails}"
    smtp_server = "${var.smtp_server}"
    smtp_username = "${var.smtp_username}"
    smtp_password = "${var.smtp_password}"
    db_name = "discourse"
    db_username = "${aws_db_instance.dc_db.username}"
    db_password = "${var.master_db_password}"
    db_host     = "${element(split(":", aws_db_instance.dc_db.endpoint), 0)}"
    redis_host  = "${aws_elasticache_cluster.dc_cache.cache_nodes.0.address}"
  }
}

resource "aws_instance" "dc_server" {
    ami                         = "${lookup(var.aws_amis, var.aws_region)}"
    instance_type               = "${var.instance_type}"
    availability_zone           = "${var.aws_az_a}"
    associate_public_ip_address = true
    subnet_id                   = "${aws_subnet.dc_net1.id}"
    user_data                   = "${file("userdata.sh")}"
    key_name                    = "${var.key_name}"
    root_block_device           = {
        volume_type = "gp2"
        volume_size = "50"
    }

    # Security group
    vpc_security_group_ids      = ["${aws_security_group.dc_server.id}"]
    depends_on                  = ["aws_elasticache_cluster.dc_cache", "aws_db_instance.dc_db"]

    connection={
        user="ubuntu"
        private_key="${file("${var.key_path}")}"
    }

    provisioner "file" {
        content     = "${data.template_file.discourse_config.rendered}"
        destination = "/home/ubuntu/app.yml"
    }

    provisioner "remote-exec" {
        inline = [
            # "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
            # "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
            # "sudo apt-get update",
            # "sudo apt-get install -y docker-ce",
            # "sudo usermod -aG docker ubuntu",
            # "sudo su - $USER",
            "while [ ! -f /tmp/signal ]; do sleep 2; done",
            "sudo mkdir /var/docker",
            "sudo git clone https://github.com/discourse/discourse_docker.git /var/docker",
            "cd /var/docker",
            "sudo cp /home/ubuntu/app.yml containers/app.yml",
            "sudo ./launcher bootstrap app",
            "sudo ./launcher start app"
        ]
    }

    tags {
        Name = "Discourse App 2"
    }
}
