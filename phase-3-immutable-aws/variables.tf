variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-1"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR, e.g. 1.2.3.4/32"
  type        = string
}

variable "app_version" {
  description = "Version marker shown on the web page"
  type        = string
  default     = "1"
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH access"
  type        = string
  default     = null
}
