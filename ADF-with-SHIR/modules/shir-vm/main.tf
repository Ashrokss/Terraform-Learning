# -----------------------------------------------------------------------------
# Virtual Network for SHIR VM
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-adf-shir"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "main" {
  name                 = "snet-adf-shir"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_network_interface" "main" {
  name                = "nic-adf-shir"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

# -----------------------------------------------------------------------------
# Windows VM for SHIR
# -----------------------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-adf-shir"
  resource_group_name = var.resource_group_name
  location            = var.location

  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password

  size                  = var.vm_size
  patch_assessment_mode = "AutomaticByPlatform"

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    name                 = "osd-adf-shir"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

# -----------------------------------------------------------------------------
# Storage for script (VM uses managed identity to download)
# -----------------------------------------------------------------------------
resource "azurerm_storage_account" "scripts" {
  name                     = "${var.storage_account_prefix}${substr(md5(var.resource_group_name), 0, 8)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.scripts.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "gateway_script" {
  name                   = "gatewayInstall.ps1"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = var.script_path
}

# -----------------------------------------------------------------------------
# RBAC: VM managed identity can read script from storage
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "vm_storage_reader" {
  scope                = azurerm_storage_account.scripts.id
  principal_id         = azurerm_windows_virtual_machine.main.identity[0].principal_id
  role_definition_name = "Storage Blob Data Reader"
}

# -----------------------------------------------------------------------------
# Custom Script Extension: Install and register SHIR
# -----------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "gateway" {
  name = "shir-install-register"

  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  tags                       = var.tags
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = [
      "${azurerm_storage_account.scripts.primary_blob_endpoint}${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.gateway_script.name}"
    ]
  })

  protected_settings = jsonencode({
    managedIdentity  = {}
    commandToExecute = "powershell.exe -ExecutionPolicy Unrestricted -File gatewayInstall.ps1 ${var.shir_auth_key}"
  })

  depends_on = [
    azurerm_role_assignment.vm_storage_reader
  ]
}
