output "vm1_public_ip" {
  value = azurerm_public_ip.pip1.ip_address
}

output "vm1_private_ip" {
  value = azurerm_network_interface.nic1.private_ip_address
}

output "vm2_public_ip" {
  value = azurerm_public_ip.pip2.ip_address
}

output "vm2_private_ip" {
  value = azurerm_network_interface.nic2.private_ip_address
}
