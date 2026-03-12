output "adf_id" {
  description = "ID of the Azure Data Factory"
  value       = azurerm_data_factory.this.id
}

output "adf_name" {
  description = "Name of the Azure Data Factory"
  value       = azurerm_data_factory.this.name
}

output "principal_id" {
  description = "Principal ID of the Data Factory's system-assigned managed identity"
  value       = azurerm_data_factory.this.identity[0].principal_id
}

output "shir_id" {
  description = "ID of the self-hosted integration runtime"
  value       = var.create_self_hosted_ir ? azurerm_data_factory_integration_runtime_self_hosted.this[0].id : null
}

output "shir_primary_authorization_key" {
  description = "Primary authorization key for registering the SHIR node"
  value       = var.create_self_hosted_ir ? azurerm_data_factory_integration_runtime_self_hosted.this[0].primary_authorization_key : null
  sensitive   = true
}
