variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "inspection_subnet_cidr" {
  description = "CIDR block for the inspection subnet"
  type        = string
  default     = "10.0.50.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.100.0/24"
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
  default     = "CHANGE_ME"
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "allowed_mgmt_cidr" {
  description = "CIDR allowed to SSH to instances (e.g., your IP)"
  type        = string
  default     = "0.0.0.0/0"
}
