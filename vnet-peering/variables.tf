variable "resource_group_name" {
  type    = string
  default = "Pal-RG"
}

variable "location" {
  type    = string
  default = "Central India"
}

variable "subscription_id" {
  type    = string
  default = "<YOUR_SUBSCRIPTION_ID>"
}

variable "vnet_1_prefix" {
  type    = string
  default = "10.1.0.0/16"
}

variable "subnet_1_prefix" {
  type    = string
  default = "10.1.1.0/24"
}

variable "vnet_2_prefix" {
  type    = string
  default = "10.2.0.0/16"
}

variable "subnet_2_prefix" {
  type    = string
  default = "10.2.1.0/24"
}

variable "admin_username" {
  type    = string
  default = "adminuser"
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = "P@ssw0rd1234!" # For demo purposes only; better to use input or key vault
}

variable "tags" {
  type = map(string)
  default = {
    costcentre = "12345"
    workload   = "VNet Peering"
  }
}
