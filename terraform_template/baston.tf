variable "bastion_domain_name_label" {
  type        = string
  description = "The name of the apiserver fqdn. Please follow the link https://docs.microsoft.com/en-us/rest/api/virtualnetwork/checkdnsnameavailability/checkdnsnameavailability to check the availability"
  default = "k8s-bastion-pip"
}

variable "publickey_path" {
  type        = string
  description = "The path of the public key."
  default = "~/.ssh/id_rsa.pub"
}

variable "bastion_vm_name" {
  type        = string
  description = "The name of the bastion vm. Name requirement: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftcompute"
  default = "k8s-bastion"

}

# Create a subnet within the vnet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = format("%s-subnet", var.bastion_vm_name)
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [element(var.address_space,2)]
}

# Create a NSG for bastion
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = format("%s-nsg", var.bastion_vm_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  
}

resource "azurerm_network_security_rule" "bastion_nsgr" {
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
  network_security_group_name = azurerm_network_security_group.bastion_nsg.name
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = format("%s-pip", var.bastion_vm_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = var.bastion_domain_name_label
}

#Create a network interface for the bastion VM
resource "azurerm_network_interface" "bastion_nic" {
  name                = format("%s-nic", var.bastion_vm_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.bastion_subnet.id
	  private_ip_address_allocation = "Dynamic"
	  public_ip_address_id          = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion_subnet_nsg" {
  subnet_id                 = azurerm_subnet.bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

#Create a bastion VM
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = var.bastion_vm_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_B1ls"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id
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

