variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "instance_type" {
  description = "EC2 size for Jenkins"
  type        = string
  default     = "t3.micro"

}

variable "your_ip" {
  description = "Your local IP for SSH and Jenkins access"
  type        = string
  # get your IP from https://checkip.amazonaws.com
  # then set it in terraform.tfvars like:
  # your_ip = "203.45.67.89/32"
}

variable "key_pair_name" {
  description = "AWS key pair name for SSH into EC2"
  type        = string
  # set in terraform.tfvars like:
  # key_pair_name = "my-aws-key"
}