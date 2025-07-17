variable "name" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "key_name" {}
variable "security_group_ids" {
  type = list(string)
}
variable "associate_public_ip" {
  type = bool
}
variable "user_data" {
  default = ""
}

variable "role" {
  type        = string
}

variable "private_key_path" {
  type        = string
}

variable "app_dir" {
  type        = string
  default     = "" # Optional if not needed for proxy
}

variable "bastion_host" {
  type        = string
  default     = null
}