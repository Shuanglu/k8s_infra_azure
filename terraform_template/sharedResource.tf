provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.20.0"
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "k8s_infra" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_user_assigned_identity" "k8s_uai" {
  resource_group_name = azurerm_resource_group.k8s_infra.name
  location            = azurerm_resource_group.k8s_infra.location
  name = "k8s-uai"
}

resource "azurerm_virtual_network" "k8s_vnet" {
  name                = "k8s-vnet"
  resource_group_name = azurerm_resource_group.k8s_infra.name
  location            = azurerm_resource_group.k8s_infra.location
  address_space       = ["172.15.0.0/16","172.16.0.0/16", "172.17.0.0/16"]
}
