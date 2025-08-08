param tags object

param location string
param CAFPrefix string
param pepSubnetId string
param nameSeparator string
@secure()
param mariaSecretName string
param mariaDbSubnetId string
@secure()
param mariaUserNameValue string
param coreSubscriptionId string
param coreResourceGroupName string
param privateDnsZoneNameMariaDb string
param mariaDbName string = '${CAFPrefix}${nameSeparator}mdb'
param privateDNSZoneIdMariaDb string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameMariaDb}'

// MariaDB Server
resource mariaDbServers 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: mariaDbName
  location: location
  tags: tags
  sku: {
    name: 'GP_Gen5_2'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    size: '1024'
    capacity: 2 // Core Count: 2,4,8,16,32
  }
  properties: {
    createMode: 'Default'
    administratorLogin: mariaUserNameValue
    administratorLoginPassword: mariaSecretName
    storageProfile: {
      storageMB: 51200
      backupRetentionDays: 30
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Enabled'
    }
    version: '10.3'
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLS1_2'
    //publicNetworkAccess: 'Disabled'
  }
  resource virtualNetworkRule 'virtualNetworkRules@2018-06-01' = {
    name: 'AllowSubnet'
    properties: {
      virtualNetworkSubnetId: mariaDbSubnetId
      ignoreMissingVnetServiceEndpoint: true
    }
  }
  dependsOn: []
}

// Create Private Endpoint
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: '${mariaDbServers.name}${nameSeparator}pep'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${mariaDbServers.name}${nameSeparator}pep'
        properties: {
          privateLinkServiceId: mariaDbServers.id
          groupIds: [
            'mariadbServer'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${mariaDbServers.name}${nameSeparator}nic'
    subnet: {
      id: pepSubnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: [
  ]
}

// Private DNS Zone Groups / MariaDb
resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsVaultCore'
  parent: privateEndpoints
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameMariaDb
        properties: {
          privateDnsZoneId: privateDNSZoneIdMariaDb
        }
      }
    ]
  }
  dependsOn: [
  ]
}

// Assign Maria DB Server Contributor to Developer Group
module roles_DeveloperGroupContributor '../security/rolesDeveloperMariaContributor.bicep' = {
  name: 'rolesDeveloperMariaContributor'
  params: {
    mariadbServerId: mariaDbServers.id
  }
  dependsOn: [

  ]
}

//Create a Database in Maria DB Server
resource dataBase 'Microsoft.DBforMariaDB/servers/databases@2018-06-01' = {
  name: 'catherine'
  parent: mariaDbServers
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_unicode_ci'
  }
}
