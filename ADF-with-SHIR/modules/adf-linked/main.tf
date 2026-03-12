# -----------------------------------------------------------------------------
# Linked Azure Data Factory
# Uses system-assigned managed identity (required for azurerm linked IR support)
# -----------------------------------------------------------------------------
resource "azurerm_data_factory" "this" {
  name                = var.adf_name
  resource_group_name = var.resource_group_name
  location            = var.location

  public_network_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Share: Grant Contributor on shared IR to linked ADF's managed identity
# Reference: https://pl.seequality.net/terra-adf-shared/
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "shared_ir_contributor" {
  scope                = var.shared_ir_id
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
  role_definition_name = "Contributor"
}

# -----------------------------------------------------------------------------
# Link: Create linked IR referencing the shared IR
# -----------------------------------------------------------------------------
resource "azurerm_data_factory_integration_runtime_self_hosted" "linked" {
  name            = var.linked_ir_name
  description     = var.linked_ir_description
  data_factory_id = azurerm_data_factory.this.id

  rbac_authorization {
    resource_id = var.shared_ir_id
  }

  depends_on = [azurerm_role_assignment.shared_ir_contributor]
}
