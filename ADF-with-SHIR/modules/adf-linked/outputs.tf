output "adf_id" {
  description = "ID of the linked Azure Data Factory"
  value       = azurerm_data_factory.this.id
}

output "adf_name" {
  description = "Name of the linked Azure Data Factory"
  value       = azurerm_data_factory.this.name
}

output "linked_ir_id" {
  description = "ID of the linked integration runtime"
  value       = azurerm_data_factory_integration_runtime_self_hosted.linked.id
}
