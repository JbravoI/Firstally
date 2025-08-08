param tags object

param keyVaultName string = '${CAFPrefix}${nameSeparator}kv01'
param privateDNSZoneNameKeyVault string
// param coreResourceGroupName string
// param coreSubscriptionId string
param mariaUserNameValue string
param vmUserNameValue string
@secure()
param mariaSecretName string
param vmSecretName string
param nameSeparator string
param mariaUserName string
param vmUserName string
param pepSubnetId string
param CAFPrefix string
param location string

// param privateDNSZoneIdKeyVault string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDNSZoneNameKeyVault}'

// Create Key Vault
resource vaults 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: 'bba1cee1-66b5-49fd-8f45-be029ddcfcb6' // This is the Brado platformAdmin Group in AAD
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'GetRotationPolicy'
            'SetRotationPolicy'
            'Rotate'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: false
    vaultUri: 'https://${keyVaultName}${environment().suffixes.keyvaultDns}'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
    }
  }
}

// Create MariaDb Admin User
resource secretsMariaUser 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: vaults
  name: mariaUserName
  properties: {
    value: mariaUserNameValue
  }
}

// Create MariaDb Admin User
resource secretsvmUser 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: vaults
  name: vmUserName
  properties: {
    value: vmUserNameValue
  }
}


module generateSecret 'keyVaultGenerateSecret.bicep' = {
  name: 'mariaSecret'
  params: {
    mariaSecretName: mariaSecretName
    vmSecretName: vmSecretName
    keyVaultName: keyVaultName
    location: location
  }
  dependsOn: [
    secretsMariaUser
    vaults
  ]
}

// Create Private Endpoint in Core
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${keyVaultName}${nameSeparator}pep'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${keyVaultName}${nameSeparator}pep'
        properties: {
          privateLinkServiceId: vaults.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: pepSubnetId
    }
    customNetworkInterfaceName: '${keyVaultName}${nameSeparator}nic'
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: []
}

// // Private DNS Zone Groups / Vault Core
// resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
//   name: 'privateDNSZoneGroupsVaultCore'
//   parent: privateEndpoints
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: privateDNSZoneNameKeyVault
//         properties: {
//           privateDnsZoneId: privateDNSZoneIdKeyVault
//         }
//       }
//     ]
//   }
// }

output keyVaultName string = vaults.name
output keyVaultId string = vaults.id
