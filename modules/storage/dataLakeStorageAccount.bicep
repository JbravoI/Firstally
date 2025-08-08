param tags object

param isHnsEnabled bool = true

param location string
param pepSubnetId string
param nameSeparator string
param storageAccountSku string
param storageAccountKind string
param dataLakeStorageAccountName string
param dataLakeSubResourceNames array

param coreSubscriptionId string
param coreResourceGroupName string
param privateDnsZoneNameDfs string
param privateDnsZoneNameFile string 
param privateDnsZoneNameBlob string 
param privateDnsZoneNameTable string
param privateDnsZoneNameQueue string

param privateDnsZoneIdFile string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameFile}'
param privateDnsZoneIdBlob string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameBlob}'
param privateDnsZoneIdTable string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameTable}'
param privateDnsZoneIdQueue string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameQueue}'
param privateDnsZoneIdDfs string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameDfs}'

// Create DataLake Storage Account
resource dataLakeStorageAccounts 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: dataLakeStorageAccountName
  location: location
  tags: tags
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    isHnsEnabled: isHnsEnabled
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
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

// Create Private Endpoints for Storage Sub Resources in Core
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2021-05-01' = [for (dataLakeSubResourceName, i) in dataLakeSubResourceNames: {
  name: '${dataLakeStorageAccountName}${dataLakeSubResourceName}${nameSeparator}pep'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${dataLakeStorageAccountName}${dataLakeSubResourceName}${nameSeparator}pep'
        properties: {
          privateLinkServiceId: dataLakeStorageAccounts.id
          groupIds: [
            dataLakeSubResourceName
          ]
        }
      }
    ]
    subnet: {
      id: pepSubnetId
    }
    customNetworkInterfaceName: '${dataLakeStorageAccountName}${dataLakeSubResourceName}${nameSeparator}nic'
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: []
}]

// Private DNS Zone Groups / File Core
resource privatednszonegroupsfile 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
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
  dependsOn: [
    privateEndpoints
  ]
}

// Private DNS Zone Groups / Blob Core
resource privatednszonegroupsblob 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
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
  dependsOn: [
    privateEndpoints
  ]
}

// Private DNS Zone Groups / Table Core
resource privatednszonegroupstable 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsTable'
  parent: privateEndpoints[2]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameTable
        properties: {
          privateDnsZoneId: privateDnsZoneIdTable
        }
      }
    ]
  }
}

// Private DNS Zone Groups / Queue Core
resource privatednszonegroupsqueue 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsQueue'
  parent: privateEndpoints[3]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameQueue
        properties: {
          privateDnsZoneId: privateDnsZoneIdQueue
        }
      }
    ]
  }
}

// Private DNS Zone Groups / Queue Core
resource privatednszonegroupsdfs 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsDfs'
  parent: privateEndpoints[4]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameDfs
        properties: {
          privateDnsZoneId: privateDnsZoneIdDfs
        }
      }
    ]
  }
}

output storageAccountId string = dataLakeStorageAccounts.id
output privateEndpoints_fileId string = privateEndpoints[0].id
output privateEndpoints_blobId string = privateEndpoints[1].id
output privateEndpoints_tableId string = privateEndpoints[2].id
output privateEndpoints_queueId string = privateEndpoints[3].id
output privateEndpoints_dfsId string = privateEndpoints[4].id
