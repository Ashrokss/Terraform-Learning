variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "shir_auth_key" {
  description = "Authorization key from the self-hosted integration runtime"
  type        = string
  sensitive   = true
}

variable "script_path" {
  description = "Path to gatewayInstall.ps1 script"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_size" {
  description = "VM size for the SHIR host"
  type        = string
  default     = "Standard_D2as_v4"
}

variable "vm_admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
  default     = "shiradmin"
}

variable "vm_admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  sensitive   = true
}

variable "storage_account_prefix" {
  description = "Prefix for storage account name (must be unique globally, 3-24 chars total)"
  type        = string
  default     = "stpaladfshir"
}
