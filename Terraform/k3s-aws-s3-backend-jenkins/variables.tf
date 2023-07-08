variable "aws-region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "aws-zone" {
  type        = string
  description = "AWS zone"
  default     = "ap-south-1a"
}


variable "ami" {
  type        = string
  description = "AMI ID"
  default     = "ami-03d3eec31be6ef6f9"
}

variable "type" {
  type        = string
  description = "Instance type"
  default     = "t2.micro"
}

variable "root_block_device" {
  type        = number
  description = "Root block device size"
  default     = 10
}

variable "ssh_user" {
  type        = string
  description = "SSH user"
  default     = "ubuntu"
}

variable "cluster-pod-cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "cluster-service-cidr" {
  type    = string
  default = "10.43.0.0/16"
}

variable "token" {
  type    = string
  default = "dfXagzaueZM8Ye"
}