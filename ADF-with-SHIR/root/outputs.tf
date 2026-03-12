output "adf_shared_id" {
  description = "ID of the shared Azure Data Factory"
  value       = module.adf_shared.adf_id
}

output "adf_shared_name" {
  description = "Name of the shared Azure Data Factory"
  value       = module.adf_shared.adf_name
}

output "shir_id" {
  description = "ID of the shared self-hosted integration runtime (use this for linked ADFs)"
  value       = module.adf_shared.shir_id
}

output "adf_linked_id" {
  description = "ID of the linked Azure Data Factory"
  value       = var.adf_linked != null ? module.adf_linked[0].adf_id : null
}

output "adf_linked_name" {
  description = "Name of the linked Azure Data Factory"
  value       = var.adf_linked != null ? module.adf_linked[0].adf_name : null
}

output "shir_vm_private_ip" {
  description = "Private IP of the SHIR VM (when shir_vm automation is enabled)"
  value       = var.shir_vm != null ? module.shir_vm[0].vm_private_ip : null
}
