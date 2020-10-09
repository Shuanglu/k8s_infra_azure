variable "master_domain_name_label" {
  type        = string
  description = "The name of the apiserver fqdn. Please follow the link https://docs.microsoft.com/en-us/rest/api/virtualnetwork/checkdnsnameavailability/checkdnsnameavailability to check the availability"
  default = "k8s-master-pip"
}

variable "master_vmss_name" {
  type        = string
  description = "The name of the master vmss. Name requirement: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftcompute"
  default = "k8s-master"

}

# Create a subnet within the vnet
resource "azurerm_subnet" "master_subnet" {
  name                 = format("%s-subnet", var.master_vmss_name)
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [element(var.address_space,0)]
}

# Create a NSG for master
resource "azurerm_network_security_group" "master_nsg" {
  name                = format("%s-nsg", var.master_vmss_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

}


resource "azurerm_network_security_rule" "master_nsgr" {
  name                       = "HTTPS"
  priority                   = 101
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "6443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.master_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "master_subnet_nsg" {
  subnet_id                 = azurerm_subnet.master_subnet.id
  network_security_group_id = azurerm_network_security_group.master_nsg.id
}


resource "azurerm_public_ip" "master_pip" {
  name                = format("%s-pip", var.master_vmss_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = var.master_domain_name_label
}

resource "azurerm_lb" "master_lb" {
  name                = format("%s-lb", var.master_vmss_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  frontend_ip_configuration {
    name                 = format("%s-pip", var.master_vmss_name)
    public_ip_address_id = azurerm_public_ip.master_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "master_lb_bep" {
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id     = azurerm_lb.master_lb.id
  name                = format("%s-lb-bep", var.master_vmss_name)
}

resource "azurerm_lb_probe" "master_lb_p" {
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id     = azurerm_lb.master_lb.id
  name                = format("%s-lb-p", var.master_vmss_name)
  protocol            = "tcp"
  port                = 6443
}

resource "azurerm_lb_rule" "master_lb_r" {
  resource_group_name            = azurerm_resource_group.resource_group.name
  loadbalancer_id                = azurerm_lb.master_lb.id
  name                           = format("%s-lb-r", var.master_vmss_name)
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 6443
  frontend_ip_configuration_name = format("%s-pip", var.master_vmss_name)
  probe_id                       = azurerm_lb_probe.master_lb_p.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.master_lb_bep.id
}


resource "azurerm_virtual_machine_scale_set" "master" {
  name                = var.master_vmss_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_A2_v2"
    tier     = "Standard"
    capacity = 1
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = var.master_vmss_name
    admin_username       = var.admin_username
	  admin_password       = var.admin_password
  }

  network_profile {
    name    = format("%s-np", var.master_vmss_name)
    primary = true

    ip_configuration {
      name                                   = format("%s-ic", var.master_vmss_name)
      primary                                = true
      subnet_id                              = azurerm_subnet.master_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.master_lb_bep.id]
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_assigned_identity.id] 
  }
}
