terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" "test" {
  features {}
}

run "setup_test_environment" {
  command = plan

  module {
    source = "../"
  }

  variables {
    name                = "test-vnet"
    location            = "eastus"
    resource_group_name = "test-rg"
    address_space       = ["10.0.0.0/16"]
    subnets = {
      app = { address_prefix = "10.0.1.0/24" }
    }
    tags = {
      environment = "test"
      project     = "terraform-test"
    }
    # nsg_rules are not created by this module in tests; kept as a placeholder
  }

  providers = {
    azurerm = azurerm.test
  }
}

run "validate_vnet_creation" {
  command = plan

  module {
    source = "../"
  }

  variables {
    name                = "test-vnet"
    location            = "eastus"
    resource_group_name = "test-rg"
    address_space       = ["10.0.0.0/16"]
    subnets = {
      app  = { address_prefix = "10.0.1.0/24" }
      db   = { address_prefix = "10.0.2.0/24" }
      misc = { address_prefix = "10.0.3.0/24" }
    }
    tags = {
      environment = "test"
      project     = "terraform-test"
    }
  }

  providers = {
    azurerm = azurerm.test
  }

  assert {
    condition     = can(module.module.vnet_id)
    error_message = "Module must output vnet_id"
  }

  assert {
    condition     = can(module.module.subnet_ids)
    error_message = "Module must output subnet_ids"
  }

  assert {
    condition     = can(module.module.nsg_id)
    error_message = "Module must output nsg_id"
  }

  assert {
    condition     = length(module.module.subnet_ids) == 3
    error_message = "Expected 3 subnets in output"
  }

  assert {
    condition     = contains(keys(module.module.subnet_ids), "app")
    error_message = "Expected 'app' subnet in subnet_ids output"
  }
}
