
variable "vpc_id" {}

variable "region" {}

variable "environment" {}

variable "tags" {}

variable "subnet_ids" {}

variable "route_table_ids" {}

variable "ingress_sgs" {
  default = []
}

variable "ingress_cidrs" {
  default = []
}

variable "vpc_endpoints" {}

variable "extra_sgs" {
  default = []
}