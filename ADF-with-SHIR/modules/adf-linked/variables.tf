variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "adf_name" {
  description = "Name of the linked Azure Data Factory"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "shared_ir_id" {
  description = "Resource ID of the shared self-hosted integration runtime"
  type        = string
}

variable "linked_ir_name" {
  description = "Name of the linked integration runtime"
  type        = string
  default     = "linked-on-prem"
}

variable "linked_ir_description" {
  description = "Description for the linked integration runtime"
  type        = string
  default     = ""
}
