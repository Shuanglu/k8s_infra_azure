
variable "resource_group_name" {
  type        = string
  description = "The name of the infra resource group."
  default = ["k8s_infra"]
}

variable "location" {
  type        = string
  description = "The location of the resources."
  default = ["West US 2"]
}

