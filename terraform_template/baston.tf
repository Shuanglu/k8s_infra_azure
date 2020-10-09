variable "baston_domain_name_label" {
  type        = string
  description = "The name of the apiserver fqdn. Please follow the link https://docs.microsoft.com/en-us/rest/api/virtualnetwork/checkdnsnameavailability/checkdnsnameavailability to check the availability"
  default = "k8s-baston-pip"
}

variable "publickey_path" {
  type        = string
  description = "The path of the public key."
  default = "~/.ssh/id_rsa.pub"
}

variable "baston_vm_name" {
  type        = string
  description = "The name of the baston vm. Name requirement: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftcompute"
  default = "k8s-baston"

}

# Create a subnet within the vnet
resource "azurerm_subnet" "baston_subnet" {
  name                 = format("%s-subnet", var.baston_vm_name)
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [element(var.address_space,2)]
}

# Create a NSG for baston
resource "azurerm_network_security_group" "baston_nsg" {
  name                = format("%s-nsg", var.baston_vm_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  
}

resource "azurerm_network_security_rule" "baston_nsgr" {
  name                       = "SSH"
  priority                   = 101
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.baston_nsg.name
}

resource "azurerm_public_ip" "baston_pip" {
  name                = format("%s-pip", var.baston_vm_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = var.baston_domain_name_label
}

#Create a network interface for the baston VM
resource "azurerm_network_interface" "baston_nic" {
  name                = format("%s-nic", var.baston_vm_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.baston_subnet.id
	  private_ip_address_allocation = "Dynamic"
	  public_ip_address_id          = azurerm_public_ip.baston_pip.id
  }
}

resource "azurerm_subnet_network_security_group_association" "baston_subnet_nsg" {
  subnet_id                 = azurerm_subnet.baston_subnet.id
  network_security_group_id = azurerm_network_security_group.baston_nsg.id
}

#Create a baston VM
resource "azurerm_linux_virtual_machine" "baston" {
  name                = var.baston_vm_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_B1ls"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.baston_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.publickey_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

