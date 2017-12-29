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

resource "aws_security_group" "sourcedb" {
    name        = "sourcedb_sg"
    description = "Demo - Security group for source databases"
    vpc_id      = "${aws_vpc.svc.id}"

    # SSH access from anywhere
    ingress {
        from_port   = 3306
        to_port     = 3306
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

resource "aws_db_parameter_group" "default" {
  name   = "mysql-56"
  family = "mysql5.6"

  parameter {
    name  = "binlog_format"
    value = "ROW"
    apply_method = "immediate"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

resource "aws_db_subnet_group" "src_subnet_grp" {
  name       = "src-subnet-grp"
  subnet_ids = ["${aws_subnet.svc1.id}", "${aws_subnet.svc2.id}"]

  tags {
    Name = "DB subnet group"
  }

}

resource "aws_db_instance" "source_db" {
  identifier          = "src-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.6.37"
  instance_class       = "db.t2.micro"
  username             = "root"
  password             = "${var.master_db_password}"
  parameter_group_name = "${aws_db_parameter_group.default.name}"
  db_subnet_group_name = "src-subnet-grp"
  publicly_accessible  = true
  skip_final_snapshot  = true
  vpc_security_group_ids = ["${aws_security_group.sourcedb.id}"]
  depends_on = ["aws_db_subnet_group.src_subnet_grp"]
  timeouts {
    create = "30m"
    delete = "2h"
  }
}


##### Target database


resource "aws_vpc" "tgt" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags {
        Name = "tgt_db"
    }
}

resource "aws_subnet" "tgt1" {
    vpc_id                  = "${aws_vpc.tgt.id}"
    cidr_block              = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_az_a}"

    tags {
        Name = "tgt1"
    }
}

resource "aws_subnet" "tgt2" {
    vpc_id                  = "${aws_vpc.tgt.id}"
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_az_b}"
  
    tags {
        Name = "tgt2"
    }
}

resource "aws_internet_gateway" "tgt_gw" {
    vpc_id = "${aws_vpc.tgt.id}"

    tags {
        Name = "tgt_gw"
    }
}

resource "aws_route_table" "tgt_r" {
    vpc_id = "${aws_vpc.tgt.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.tgt_gw.id}"
    }

    tags {
        Name = "aws_route_table_tgt"
    }
}

resource "aws_route_table_association" "tgt_a1" {
    subnet_id      = "${aws_subnet.tgt1.id}"
    route_table_id = "${aws_route_table.tgt_r.id}"
}

resource "aws_route_table_association" "tgt_a2" {
    subnet_id      = "${aws_subnet.tgt2.id}"
    route_table_id = "${aws_route_table.tgt_r.id}"
}

resource "aws_security_group" "tgtdb" {
    name        = "tgtdb_sg"
    description = "Security group for target databases"
    vpc_id      = "${aws_vpc.tgt.id}"

    # SSH access from anywhere
    ingress {
        from_port   = 5432
        to_port     = 5432
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

resource "aws_db_subnet_group" "tgt_subnet_grp" {
  name       = "tgt-subnet-grp"
  subnet_ids = ["${aws_subnet.tgt1.id}", "${aws_subnet.tgt2.id}"]

  tags {
    Name = "DB target subnet group"
  }

}

resource "aws_db_instance" "target_db" {
  identifier          = "target-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "9.6.3"
  instance_class       = "db.t2.micro"
  name                 = "employees"
  username             = "root"
  password             = "${var.master_db_password}"
  db_subnet_group_name = "tgt-subnet-grp"
  publicly_accessible  = true
  skip_final_snapshot  = true
  vpc_security_group_ids = ["${aws_security_group.tgtdb.id}"]
  depends_on = ["aws_db_subnet_group.tgt_subnet_grp"]
  timeouts {
    create = "30m"
    delete = "2h"
  }
}


output "source_db" {
  value = ["${aws_db_instance.source_db.endpoint}"]
}

output "target_db" {
  value = ["${aws_db_instance.target_db.endpoint}"]
}