output "vnet_id" {
  description = "The ID of the virtual network created by the module"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs created by the module"
  value       = { for k, subnet in azurerm_subnet.subnet : k => subnet.id }
}

output "nsg_id" {
  description = "ID of the network security group associated with the VNet"
  value       = azurerm_network_security_group.nsg.id
}