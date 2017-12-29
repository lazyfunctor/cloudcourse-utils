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

variable "master_db_password" {
    description = "Master password for the database"
}