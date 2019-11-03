provider "azurerm" {

}

variable "prefix" {
  default = "tfdev"
}

variable "location" {
  default = "uksouth"
}

variable "owner" {

}

variable "environment" {

}

variable "vm_user" {
  default = "azureuser"
}

variable "vm_hostname" {
}

variable vm_ssh_rsa_pubkey {
  default = "~/.ssh/id_rsa.pub"
}


locals {
  common_tags = {
    environment = var.environment
    owner       = var.owner
  }
}

resource "azurerm_resource_group" "default" {
  name     = "${var.prefix}-resources"
  location = var.location

  tags = local.common_tags
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name

  tags = local.common_tags
}

resource "azurerm_subnet" "default" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "default" {
  name                = "${var.prefix}-publicip"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Dynamic"

  tags = local.common_tags
}

resource "azurerm_network_security_group" "default" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name


  tags = local.common_tags
}

resource "azurerm_network_security_rule" "ssh" {
  name                       = "SSH"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  network_security_group_name = azurerm_network_security_group.default.name
  resource_group_name         = azurerm_resource_group.default.name
}

resource "azurerm_network_security_rule" "mosh" {
  name                       = "Mosh"
  priority                   = 1010
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Udp"
  source_port_range          = "*"
  destination_port_ranges    = ["60000-61000"]
  source_address_prefix      = "*"
  destination_address_prefix = "*"

  network_security_group_name = azurerm_network_security_group.default.name
  resource_group_name         = azurerm_resource_group.default.name
}

resource "azurerm_network_interface" "default" {
  name                      = "${var.prefix}-nic"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.default.name
  network_security_group_id = azurerm_network_security_group.default.id

  ip_configuration {
    name                          = "${var.prefix}NicConfiguration"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.default.id}"
  }

  tags = local.common_tags
}

resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.default.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "default" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.default.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags = local.common_tags
}

resource "azurerm_virtual_machine" "default" {
  name                  = "${var.prefix}-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.default.name
  network_interface_ids = [azurerm_network_interface.default.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.vm_hostname
    admin_username = var.vm_user
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.vm_user}/.ssh/authorized_keys"
      key_data = file(var.vm_ssh_rsa_pubkey)
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.default.primary_blob_endpoint
  }

  tags = local.common_tags
}

output "public_ip_address" {
  value = azurerm_public_ip.default.ip_address
}

output "ssh_connect" {
  value = "${var.vm_user}@${azurerm_public_ip.default.ip_address}"
}
