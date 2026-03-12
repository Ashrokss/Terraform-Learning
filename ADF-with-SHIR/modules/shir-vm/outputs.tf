output "vm_id" {
  description = "ID of the SHIR VM"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_private_ip" {
  description = "Private IP of the SHIR VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}
