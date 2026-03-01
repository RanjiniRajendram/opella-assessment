output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  value = { for k, subnet in azurerm_subnet.subnet : k => subnet.id }
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
}