variable "vpc_id" {
  type = string
}

variable "subnet_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "igw_id" {
  default = null
}

variable "natgw_id" {
  default = null
}

variable "name" {
  type = string
}