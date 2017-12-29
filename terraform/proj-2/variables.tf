variable "aws_region" {
    description = "AWS region to launch servers."
    default     = "us-east-1"
}

variable "aws_az_a" {
    description = "AWS availability zone A"
    default = "us-east-1a"
}

variable "aws_az_b" {
    description = "AWS availability zone B"
    default = "us-east-1b"
}

variable "aws_amis" {
  default = {
    "us-east-1" = "ami-da05a4a0"
  }
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "Demo"
}

variable "key_path" {
  description = "SSH key path"
}


variable "instance_type" {
  default     = "t2.medium"
  description = "AWS instance type"
}


variable "master_db_password" {
    description = "Master password for the database"
}

variable "smtp_server" {
    description = "Address of SMTP server"
}

variable "smtp_username" {
    description = "smtp username for AWS SES"
}

variable "smtp_password" {
    description = "smtp password for AWS SES"
}

variable "developer_emails" {
    description = "Admin email for developers"
}

variable "host_name" {
    description = "Host name"
}
