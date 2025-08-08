param mariadbServerId string

// Contributor RBAC Role Definition Id
var roleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
// Developer Group Id
var developerGroupId = 'af21c90c-2d8c-49de-89c6-9cf0dd9121b4'

// Give User Assigned Identity Owner on the Resource Group
resource RoleAssignment_ResourceGroupOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(developerGroupId, roleDefinitionId, mariadbServerId)
  properties: {
    principalId: developerGroupId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
  dependsOn: []
}
