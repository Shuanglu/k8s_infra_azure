variable "agent_vmss_name" {
  type        = string
  description = "The name of the agent vmss. Name requirement: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftcompute"
  default = "k8s-agent"

}


# Create a subnet within the vnet
resource "azurerm_subnet" "agent_subnet" {
  name                 = format("%s-subnet", var.agent_vmss_name)
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = [element(var.address_space,1)]
}

resource "azurerm_network_security_group" "agent_nsg" {
  name                = format("%s-nsg", var.agent_vmss_name)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  
}



resource "azurerm_subnet_network_security_group_association" "agent_subnet_nsg" {
  subnet_id                 = azurerm_subnet.agent_subnet.id
  network_security_group_id = azurerm_network_security_group.agent_nsg.id
}



resource "azurerm_virtual_machine_scale_set" "agent" {
  name                = var.agent_vmss_name
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
    computer_name_prefix = var.agent_vmss_name
    admin_username       = var.admin_username
	  admin_password       = var.admin_password
  }

  network_profile {
    name    = format("%s-np", var.agent_vmss_name)
    primary = true

    ip_configuration {
      name                                   = format("%s-ic", var.agent_vmss_name)
      primary                                = true
      subnet_id                              = azurerm_subnet.agent_subnet.id
    }
  }
 
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_assigned_identity.id] 
  }
}
