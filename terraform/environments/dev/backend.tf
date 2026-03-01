terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstategepassessment"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
