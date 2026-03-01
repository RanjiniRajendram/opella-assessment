run "vnet_should_be_created" {

  command = apply

  variables {
    name                = "test-vnet"
    location            = "East US"
    resource_group_name = "tfstate-rg"
    address_space       = ["10.0.0.0/16"]
    subnets             = {}
    tags                = {}
  }

  assert {
    condition     = output.vnet_id != ""
    error_message = "VNET ID should not be empty"
  }
}