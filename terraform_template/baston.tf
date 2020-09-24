# Create a subnet within the vnet
resource "azurerm_subnet" "k8s_bsubnet" {
  name                 = "k8s-baston-subnet"
  resource_group_name  = azurerm_resource_group.k8s_infra.name
  virtual_network_name = azurerm_virtual_network.k8s_vnet.name
  address_prefixes       = ["172.15.0.0/16"]
}

# Create a NSG for baston
resource "azurerm_network_security_group" "k8s_bnsg" {
  name                = "k8s-baston-nsg"
  location            = azurerm_resource_group.k8s_infra.location
  resource_group_name = azurerm_resource_group.k8s_infra.name
  
}

resource "azurerm_network_security_rule" "k8s_bnsgr" {
  name                       = "SSH"
  priority                   = 101
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.k8s_infra.name
  network_security_group_name = azurerm_network_security_group.k8s_bnsg.name
}

resource "azurerm_public_ip" "k8s_bpip" {
  name                = "k8s_baston-pip"
  location            = azurerm_resource_group.k8s_infra.location
  resource_group_name = azurerm_resource_group.k8s_infra.name
  allocation_method   = "Static"
  domain_name_label   = "k8s-baston-pip"
}

#Create a network interface for the baston VM
resource "azurerm_network_interface" "k8s_baston_nic" {
  name                = "k8s-baston-nic"
  location            = azurerm_resource_group.k8s_infra.location
  resource_group_name = azurerm_resource_group.k8s_infra.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.k8s_bsubnet.id
	private_ip_address_allocation = "Dynamic"
	public_ip_address_id          = azurerm_public_ip.k8s_bpip.id
  }
}

resource "azurerm_subnet_network_security_group_association" "k8s_bsubnet_nsg" {
  subnet_id                 = azurerm_subnet.k8s_bsubnet.id
  network_security_group_id = azurerm_network_security_group.k8s_bnsg.id
}

#Create a baston VM
resource "azurerm_linux_virtual_machine" "k8s_baston" {
  name                = "k8s-baston"
  resource_group_name = azurerm_resource_group.k8s_infra.name
  location            = azurerm_resource_group.k8s_infra.location
  size                = "Standard_B1ls"
  admin_username      = "testshuang"
  network_interface_ids = [
    azurerm_network_interface.k8s_baston_nic.id
  ]

  admin_ssh_key {
    username   = "testshuang"
    public_key = file("~/.ssh/id_rsa.pub")
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

