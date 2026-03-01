resource "azurerm_role_assignment" "policy_tag_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Tag Contributor"
  principal_id         = azurerm_policy_assignment.inherit_tags_assignment.identity[0].principal_id
}