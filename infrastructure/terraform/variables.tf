variable "availability_zones" {
  type = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "aws_key_name" {
  type = string
  description = "panda-core-7"
}

variable "ssh_key_path" {
  type = string
  description = "/home/panda/panda-core-7.pem"
}