data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Network Security Group (Shared)
resource "azurerm_network_security_group" "nsg" {
  name                = "vnet-peering-nsg"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowICMP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# VNet 1 Resources
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet-1"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_1_prefix]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet-1"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.subnet_1_prefix]
}

resource "azurerm_subnet_network_security_group_association" "subnet1_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip1" {
  name                = "vm1-pip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic1" {
  name                = "vm1-nic"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                            = "vm-1"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = var.tags
}

# VNet 2 Resources
resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet-2"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_2_prefix]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet-2"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = [var.subnet_2_prefix]
}

resource "azurerm_subnet_network_security_group_association" "subnet2_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip2" {
  name                = "vm2-pip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic2" {
  name                = "vm2-nic"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip2.id
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                            = "vm-2"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = var.tags
}

# VNet Peering
resource "azurerm_virtual_network_peering" "peer1to2" {
  name                         = "peer-vnet1-to-vnet2"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "peer2to1" {
  name                         = "peer-vnet2-to-vnet1"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
