# -----------------------------------------------------------------------------
# Azure Data Factory
# -----------------------------------------------------------------------------
resource "azurerm_data_factory" "this" {
  name                = var.adf_name
  resource_group_name = var.resource_group_name
  location            = var.location

  public_network_enabled = var.public_network_enabled

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Self-Hosted Integration Runtime (Shared IR)
# Referenced by linked ADFs via RBAC
# -----------------------------------------------------------------------------
resource "azurerm_data_factory_integration_runtime_self_hosted" "this" {
  count = var.create_self_hosted_ir ? 1 : 0

  name            = var.shir_name
  description     = var.shir_description
  data_factory_id = azurerm_data_factory.this.id
}
