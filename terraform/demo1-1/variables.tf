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

variable "aws_az_c" {
    description = "AWS availability zone C"
    default = "us-east-1c"
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

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "2"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "2"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "2"
}