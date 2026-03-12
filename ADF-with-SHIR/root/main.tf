# -----------------------------------------------------------------------------
# Data sources - Use existing resource group
# -----------------------------------------------------------------------------
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Shared ADF with Self-Hosted Integration Runtime
# This ADF owns the SHIR; register the IR node on your on-prem/VM manually
# or use the automation from https://pl.seequality.net/terra-adf-shir/
# -----------------------------------------------------------------------------
module "adf_shared" {
  source = "../modules/adf"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = coalesce(data.azurerm_resource_group.main.location, var.location)

  adf_name = var.adf_shared.name

  create_self_hosted_ir = true
  shir_name            = var.adf_shared.shir_name
  shir_description    = try(var.adf_shared.description, "Shared self-hosted integration runtime")

  tags = {
    environment  = var.environment
    managed_by   = "terraform"
    costcentre   = var.costcentre
    workload     = var.workload
  }
}

# -----------------------------------------------------------------------------
# SHIR VM - Automated install & register of IR node on Azure VM
# Set shir_vm = null to skip (e.g. if using on-prem machine)
# -----------------------------------------------------------------------------
module "shir_vm" {
  count  = var.shir_vm != null ? 1 : 0
  source = "../modules/shir-vm"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = coalesce(data.azurerm_resource_group.main.location, var.location)

  shir_auth_key = module.adf_shared.shir_primary_authorization_key
  script_path   = abspath("${path.module}/../scripts/gatewayInstall.ps1")

  vm_admin_password      = var.shir_vm.vm_admin_password
  storage_account_prefix = try(var.shir_vm.storage_account_prefix, "stpaladfshir")
  vm_size                = try(var.shir_vm.vm_size, "Standard_D2as_v4")
  vnet_address_space     = try(var.shir_vm.vnet_address_space, "10.0.0.0/16")
  subnet_address_prefix  = try(var.shir_vm.subnet_address_prefix, "10.0.1.0/24")

  tags = {
    environment  = var.environment
    managed_by   = "terraform"
    costcentre   = var.costcentre
    workload     = var.workload
  }
}

# -----------------------------------------------------------------------------
# Wait for IR node registration (Custom Script takes ~3-5 min when using VM)
# -----------------------------------------------------------------------------
resource "time_sleep" "wait_shir_registration" {
  count = var.adf_linked != null ? 1 : 0

  create_duration = var.shir_vm != null ? "5m" : "30s"
  depends_on      = [module.shir_vm]
}

# -----------------------------------------------------------------------------
# Linked ADF (optional) - Consumes the shared IR
# Set adf_linked = null in variables to provision only the shared ADF
# -----------------------------------------------------------------------------
module "adf_linked" {
  count  = var.adf_linked != null ? 1 : 0
  source = "../modules/adf-linked"

  resource_group_name = data.azurerm_resource_group.main.name
  location            = coalesce(data.azurerm_resource_group.main.location, var.location)

  depends_on = [time_sleep.wait_shir_registration]


  adf_name = var.adf_linked.name

  shared_ir_id         = module.adf_shared.shir_id
  linked_ir_name       = var.adf_linked.linked_ir_name
  linked_ir_description = try(var.adf_linked.description, "Linked integration runtime")

  tags = {
    environment  = var.environment
    managed_by   = "terraform"
    costcentre   = var.costcentre
    workload     = var.workload
  }
}
