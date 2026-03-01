run "validate_required_outputs" {
  command = plan

  module {
    source = "../"
  }

  variables = {
    name                = "uat-vnet"
    location            = "westus"
    resource_group_name = "uat-rg"
    address_space       = ["172.16.0.0/16"]

    subnets = {
      frontend = { address_prefix = "172.16.1.0/24" }
    }

    tags = {
      environment = "uat"
    }
  }

  assert {
    condition     = length(output.subnet_ids) > 0
    error_message = "Module must return at least one subnet ID"
  }

  assert {
    condition     = length(output.vnet_id) > 0
    error_message = "VNet ID should not be empty"
  }
}

run "validate_address_space" {
  command = plan

  module {
    source = "../"
  }

  variables = {
    name                = "prod-vnet"
    location            = "eastus"
    resource_group_name = "prod-rg"
    address_space       = ["10.0.0.0/8"]

    subnets = {
      web  = { address_prefix = "10.1.0.0/24" }
      api  = { address_prefix = "10.2.0.0/24" }
      data = { address_prefix = "10.3.0.0/24" }
    }

    tags = {
      environment = "production"
      team        = "devops"
    }
  }

  assert {
    condition     = length(output.subnet_ids) == 3
    error_message = "Expected exactly 3 subnets"
  }
}