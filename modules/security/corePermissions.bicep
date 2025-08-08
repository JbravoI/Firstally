targetScope = 'resourceGroup'

param principalId string
param coreSubscriptionId string
param coreResourceGroupName string

@description('The type of principal to add')
@allowed([
  'ForeignGroup'
  'User'
  'Group'
  'ServicePrincipal'
])
param principalType string = 'ServicePrincipal'

@description('Built-in Role to add to resource group. Chosen from https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
@allowed([
  'Owner'
  'Contributor'
  'Reader'
  'StorageBlobDataContributor'
  'KeyVaultSecretsUser'
])
param roleName string

@description('Converter from the title of the allowed built in roles to the associated GUIDs')
var roleMap = {
  Contributor:'b24988ac-6180-42a0-ab88-20f7382dd24c'
  Owner:'8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Reader:'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  StorageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  KeyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
}
var roleGuid = roleMap[roleName]

// Resource Group for each Instance
resource resourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription(coreSubscriptionId)
  name: coreResourceGroupName
}

resource coreRoleAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroups.id, principalId, roleGuid)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
    principalId: principalId
    principalType: principalType
  }
}

