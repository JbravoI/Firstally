param tags object

param keyVaultName string = '${CAFPrefix}${nameSeparator}kv01'
param privateDNSZoneNameKeyVault string
// param coreResourceGroupName string
// param coreSubscriptionId string
// param mariaUserNameValue string
// param vmUserNameValue string
// param mariaSecretName string
// param vmSecretName string
param nameSeparator string
// param mariaUserName string
// param vmUserName string
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
