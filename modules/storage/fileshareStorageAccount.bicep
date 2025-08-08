param tags object

param fileshareStorageAccountName string = replace(toLower('${CAFPrefix}caesa'), '-', '')
param privateDnsZoneNameFile string 
param privateDnsZoneNameBlob string 
param coreResourceGroupName string
param storageAccountKind string
param coreSubscriptionId string
param storageAccountSku string
param fileshareName string
param nameSeparator string
param pepSubnetId string
param CAFPrefix string
param location string

param fileshareSubResourceNames array

param isHnsEnabled bool = true

param privateDnsZoneIdFile string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameFile}'
param privateDnsZoneIdBlob string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameBlob}'

// Create Fileshare Storage Account
resource fileshareStorageAccounts 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: fileshareStorageAccountName
  location: location
  tags: tags
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    isHnsEnabled: isHnsEnabled
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

// Create File Services
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = {
  parent: fileshareStorageAccounts
  name: 'default'
}

// Create Fileshare
resource shares 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  parent: fileServices
  name: fileshareName
}

// Create Private Endpoints for Storage Sub Resources
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2021-05-01' = [for (fileshareSubResourceName, i) in fileshareSubResourceNames: {
  name: '${fileshareStorageAccounts.name}${fileshareSubResourceNames[i]}${nameSeparator}pep'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${fileshareStorageAccounts.name}${fileshareSubResourceName}${nameSeparator}pep'
        properties: {
          privateLinkServiceId: fileshareStorageAccounts.id
          groupIds: [
            fileshareSubResourceName
          ]
        }
      }
    ]
    subnet: {
      id: pepSubnetId
    }
    customNetworkInterfaceName: '${fileshareStorageAccounts.name}${fileshareSubResourceName}${nameSeparator}nic'
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: []
}]

// Private DNS Zone Groups / File Core
resource privatednszoneFile 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsFile'
  parent: privateEndpoints[0]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameFile
        properties: {
          privateDnsZoneId: privateDnsZoneIdFile
        }
      }
    ]
  }
  dependsOn: []
}

// Private DNS Zone Groups / Blob Core
resource privatednszoneBlob 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsBlob'
  parent: privateEndpoints[1]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameBlob
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
  dependsOn: []
}

output storageAccountId string = fileshareStorageAccounts.id
output storageAccountName string = fileshareStorageAccounts.name
output privateEndpoints_fileId string = privateEndpoints[0].id
output privateEndpoints_blobId string = privateEndpoints[1].id
