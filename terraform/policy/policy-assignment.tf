resource "azurerm_policy_assignment" "inherit_tags_assignment" {
  name                 = "inherit-env-region-tags"
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.inherit_tags_from_rg.id

  identity {
    type = "SystemAssigned"
  }
}