param userAssignedIdentityPrincipalId string

// Owner RBAC Role Definition Id
var roleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

// Give User Assigned Identity Owner on the Resource Group
resource RoleAssignment_ResourceGroupOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentityPrincipalId, roleDefinitionId, resourceGroup().id)
  properties: {
    principalId: userAssignedIdentityPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
  dependsOn: [
    
  ]
}
