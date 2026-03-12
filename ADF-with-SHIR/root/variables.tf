variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment tag (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "costcentre" {
  description = "Cost centre tag (required by policy)"
  type        = string
}

variable "workload" {
  description = "Workload tag (required by policy)"
  type        = string
}

# Shared ADF (owns the self-hosted IR)
variable "adf_shared" {
  description = "Configuration for the shared ADF (owns SHIR)"
  type = object({
    name        = string
    shir_name   = optional(string, "shir-on-prem")
    description = optional(string, "Shared self-hosted integration runtime")
  })
}

# SHIR VM automation (install & register IR node on Azure VM)
variable "shir_vm" {
  description = "Create VM with automated SHIR installation. Set to null to skip."
  type = object({
    vm_admin_password      = string
    storage_account_prefix = optional(string, "stpaladfshir")
    vm_size                = optional(string, "Standard_D2as_v4")
    vnet_address_space     = optional(string, "10.0.0.0/16")
    subnet_address_prefix  = optional(string, "10.0.1.0/24")
  })
  default = null
}

# Linked ADF (consumes shared IR)
variable "adf_linked" {
  description = "Configuration for the linked ADF (consumes shared IR). Set to null to skip."
  type = object({
    name         = string
    linked_ir_name = optional(string, "linked-on-prem")
    description  = optional(string, "Linked integration runtime")
  })
  default = null
}
