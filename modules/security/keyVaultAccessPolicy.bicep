targetScope = 'resourceGroup'

param keyVaultName string
param userAssignedIdentitiesPrincipalId string

// Identify Exisitng Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Add User Assigned Identity to Core Key Vault
resource accessPolicies_mngdId 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: userAssignedIdentitiesPrincipalId
        tenantId: tenant().tenantId        
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
          ]
        }
      }
      {
        objectId: '37fe131d-a74d-4859-830d-7b5b88da227c'
        tenantId: tenant().tenantId
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
          ]
        }
      }
      {
        objectId: '65515ccb-2c29-483e-87bb-98edadba6d0e'
        tenantId: tenant().tenantId
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
          ]
        }
      }
    ]
  }
}

output accessPoliciesOutput object = { accessPolicies: keyVault.properties.accessPolicies }
