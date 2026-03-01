provider "azurerm" {
  features {}
}

locals {
  prefix = "${var.environment}-${var.location}"
  common_tags = {
    environment = var.environment
    region      = var.location
    project     = "${var.project}-${var.environment}"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

module "vnet" {
  source              = "../../modules/vnet"
  name                = "${local.prefix}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    app = {
      address_prefix = "10.0.1.0/24"
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_account" "sa" {
  name                     = "${replace(local.prefix, "-", "")}stg"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

resource "azurerm_storage_container" "container" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]
  os_disk {
  caching              = "ReadWrite"
  storage_account_type = "Standard_LRS"
}

  tags = local.common_tags
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${local.prefix}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = module.vnet.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}
