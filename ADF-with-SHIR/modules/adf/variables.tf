variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "adf_name" {
  description = "Name of the Azure Data Factory"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "public_network_enabled" {
  description = "Whether public network access is enabled"
  type        = bool
  default     = true
}

# Self-hosted IR (shared) configuration
variable "create_self_hosted_ir" {
  description = "Create self-hosted integration runtime (owner of shared IR)"
  type        = bool
  default     = false
}

variable "shir_name" {
  description = "Name of the self-hosted integration runtime"
  type        = string
  default     = "shir-on-prem"
}

variable "shir_description" {
  description = "Description for the self-hosted integration runtime"
  type        = string
  default     = ""
}
