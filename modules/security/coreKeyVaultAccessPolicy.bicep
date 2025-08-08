targetScope = 'resourceGroup'

param coreKeyVaultName string
param userAssignedIdentitiesPrincipalId string

// Identify Exisitng Key Vault in Core Subscription
resource coreKeyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: coreKeyVaultName
}

// Add User Assigned Identity to Core Key Vault
resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: 'add'
  parent: coreKeyVault
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: userAssignedIdentitiesPrincipalId
        permissions: {
          keys: [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'List'
          ]
          certificates: [
            'Get'
            'List'
            'GetIssuers'
            'ListIssuers'
          ]
        }
      }
    ]
  }
}

output coreAccessPoliciesOutput object = { accessPolicies: coreKeyVault.properties.accessPolicies }
