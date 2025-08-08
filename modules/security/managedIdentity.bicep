param tags object

param managedIdentityName string = '${CAFPrefix}${nameSeparator}id'
param nameSeparator string
param CAFPrefix string
param location string

// Create a User Assigned Identity
resource userAssignedIdentities 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

output userAssignedIdentityName string = userAssignedIdentities.name
output userAssignedIdentityId string = userAssignedIdentities.id
output userAssignedIdentityType string = userAssignedIdentities.type
output userAssignedIdentityPrincipalId string = userAssignedIdentities.properties.principalId
output userAssignedIdentityTenantId string = userAssignedIdentities.properties.tenantId
output userAssignedIdentityClientId string = userAssignedIdentities.properties.clientId
