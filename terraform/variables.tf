variable "rds_username" {
  default = "admin"
}

variable "rds_password" {
  default = "AdminPassword123!"
}


variable "vpc_security_group_ids" {
  type        = list(string)
  default     = ["sg-0bf7076d52690eeb7"] # replace with your SG ID
}

variable "subnet_ids" {
  type        = list(string)
  default     = ["subnet-0dacc388a97abaddc", "subnet-00692cd2e049e48f8"] 
}

variable "db_subnet_group_name" {
  description = "RDS subnet group name"
  type        = string
  default     = "iaac-task-db-subnet" # replace if you have a custom DB subnet group
}

