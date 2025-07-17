variable "name" {
  description = "Name for the ALB and related resources"
  type        = string
}

variable "internal" {
  description = "Whether the ALB is internal"
  type        = bool
}

variable "subnets" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the ALB and TG will be created"
  type        = string
}

variable "target_port" {
  description = "Port for the target group"
  type        = number
}

variable "listener_port" {
  description = "Port on which the ALB listens"
  type        = number
}

variable "instance_ids" {
  description = "Map of EC2 instance IDs to register to the target group"
  type        = map(string)
}
