run "setup_test_environment" {
  command = plan

  module {
    source = "../"
  }

  variables = {
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
  }
}

run "validate_vnet_creation" {
  command = plan

  module {
    source = "../"
  }

  variables = {
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

  assert {
    condition     = length(output.vnet_id) > 0
    error_message = "Module must output vnet_id"
  }

  assert {
    condition     = length(output.subnet_ids) == 3
    error_message = "Expected 3 subnets in output"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "app")
    error_message = "Expected 'app' subnet in subnet_ids output"
  }
}