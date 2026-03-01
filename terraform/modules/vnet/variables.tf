variable "name" {
  description = "VNet name"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    address_prefix = string
  }))
}

variable "tags" {
  type = map(string)
}

# This is an optional variable for nsg_rules
variable "nsg_rules" {
  description = "Placeholder for NSG rules; rules are not created by this module"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}
