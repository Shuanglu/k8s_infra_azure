provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.20.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the infra resource group."
  default = "k8s-infra"
}


variable "location" {
  type        = string
  description = "The location of the resources."
  default = "West US 2"
}

variable "user_assigned_identity" {
  type        = string
  description = "The name of the user assigned identity."
  default = "k8s-uai"
}

variable "vnet" {
  type        = string
  description = "The name of the Vnet."
  default = "k8s-vnet"
}

variable "address_space" {
  type        = list(string)
  description = "The address space of the VNet including master,agent,bastion."
  default = ["172.15.0.0/16","172.16.0.0/16", "172.17.0.0/16"]
}

variable "admin_username" {
  type        = string
  description = "The name of the admin user. Username requirement: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-username-requirements-when-creating-a-vm"
  default = "azureuser"
}

variable "admin_password" {
  type        = string
  description = "The password of the admin user. Password requirement: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm"
  default = "WorldPeace2020"
}

variable "storageAccount" {
  type        = string
  description = "The name of the StorageAccount."
  default = "k8sinfra"
}

# Create a resource group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  name = var.user_assigned_identity
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = var.address_space
}

resource "azurerm_role_assignment" "user_assigned_identity_roleassignment" {
  scope                = azurerm_resource_group.resource_group.id
  role_definition_name = "owner"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
}

resource "azurerm_storage_account" "storageaccount" {
  name                     = var.storageAccount
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}
