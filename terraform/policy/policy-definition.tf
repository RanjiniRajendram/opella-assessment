resource "azurerm_policy_definition" "inherit_tags_from_rg" {
  name         = "inherit-environment-region-from-rg"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Inherit environment and region tags from Resource Group"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "tags['environment']"
          exists = "false"
        },
        {
          field  = "tags['region']"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "modify"
      details = {
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/4a9ae827-6dc8-4573-8ac7-8239d42aa03f"
        ]
        operations = [
          {
            operation = "addOrReplace"
            field     = "tags['environment']"
            value     = "[resourceGroup().tags['environment']]"
          },
          {
            operation = "addOrReplace"
            field     = "tags['region']"
            value     = "[resourceGroup().tags['region']]"
          }
        ]
      }
    }
  })
}