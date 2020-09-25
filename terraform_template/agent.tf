# Create a subnet within the vnet
resource "azurerm_subnet" "k8s_asubnet" {
  name                 = "k8s-agent-subnet"
  resource_group_name  = azurerm_resource_group.k8s_infra.name
  virtual_network_name = azurerm_virtual_network.k8s_vnet.name
  address_prefixes       = ["172.17.0.0/16"]
}

resource "azurerm_network_security_group" "k8s_ansg" {
  name                = "k8s-agent-nsg"
  location            = azurerm_resource_group.k8s_infra.location
  resource_group_name = azurerm_resource_group.k8s_infra.name
  
}



resource "azurerm_subnet_network_security_group_association" "k8s_asubnet_nsg" {
  subnet_id                 = azurerm_subnet.k8s_asubnet.id
  network_security_group_id = azurerm_network_security_group.k8s_ansg.id
}



resource "azurerm_virtual_machine_scale_set" "k8s_a" {
  name                = "k8s-agent"
  location            = azurerm_resource_group.k8s_infra.location
  resource_group_name = azurerm_resource_group.k8s_infra.name

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
    computer_name_prefix = "k8s-agent"
    admin_username       = "testshuang"
    admin_password       = "WorldPeace2020"
  }

  network_profile {
    name    = "k8s-agent-np"
    primary = true

    ip_configuration {
      name                                   = "k8s-agent-ic"
      primary                                = true
      subnet_id                              = azurerm_subnet.k8s_asubnet.id
    }
  }
 
  identity {
    type = "UserAssigned"
    identity_ids = ["/subscriptions/886ee2a4-e790-43c5-bfa4-5c8db2e433f6/resourceGroups/k8s-infra/providers/Microsoft.ManagedIdentity/userAssignedIdentities/k8s-uai"]
  }
}
