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
  
  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "k8s_asubnet_nsg" {
  subnet_id                 = azurerm_subnet.k8s_asubnet.id
  network_security_group_id = azurerm_network_security_group.k8s_ansg.id
}

resource "azurerm_public_ip" "k8s_apip" {
  name                = "k8s-agent-pip"
  location            = azurerm_resource_group.k8s_infra.location
  resource_group_name = azurerm_resource_group.k8s_infra.name
  allocation_method   = "Static"
  domain_name_label   = "k8s-apip"
}

resource "azurerm_lb" "k8s_alb" {
  name                = "k8s-agent-lb"
  location            = azurerm_resource_group.k8s_infra.location
  resource_group_name = azurerm_resource_group.k8s_infra.name

  frontend_ip_configuration {
    name                 = "k8s-agent-pip"
    public_ip_address_id = azurerm_public_ip.k8s_apip.id
  }
}

resource "azurerm_lb_backend_address_pool" "k8s_alb_bep" {
  resource_group_name = azurerm_resource_group.k8s_infra.name
  loadbalancer_id     = azurerm_lb.k8s_alb.id
  name                = "k8s-agent-lb-bep"
}

resource "azurerm_lb_probe" "k8s_alb_p" {
  resource_group_name = azurerm_resource_group.k8s_infra.name
  loadbalancer_id     = azurerm_lb.k8s_alb.id
  name                = "k8s-agent-lb-p"
  protocol            = "tcp"
  port                = 6443
}

resource "azurerm_lb_rule" "k8s_lbr" {
  resource_group_name            = azurerm_resource_group.k8s_infra.name
  loadbalancer_id                = azurerm_lb.k8s_alb.id
  name                           = "k8s-agent-lb-r"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 6443
  frontend_ip_configuration_name = "k8s-agent-pip"
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
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/testshuang/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  network_profile {
    name    = "k8s-agent-np"
    primary = true

    ip_configuration {
      name                                   = "k8s-agent-ic"
      primary                                = true
      subnet_id                              = azurerm_subnet.k8s_asubnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.k8s_alb_bep.id]
    }
  }
 
  identity {
    type = "UserAssigned"
    identity_ids = ["/subscriptions/886ee2a4-e790-43c5-bfa4-5c8db2e433f6/resourceGroups/k8s-infra/providers/Microsoft.ManagedIdentity/userAssignedIdentities/k8s-uai"]
  }
}

