param tags object

param location string
param CAFPrefix string
param pepSubnetId string
param nameSeparator string
param coreSubscriptionId string
param coreResourceGroupName string
param userAssignedIdentityId string
param privateDNSZoneNameGremlin string
param privateDNSZoneNameDocuments string
param cosmosDbName string = '${CAFPrefix}${nameSeparator}cdb'

var graphName = 'BradoGraph'
var databaseName = 'BradoDatabase'
param privateDnsZoneIdCosmosDb string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDNSZoneNameGremlin}'
param privateDnsZoneIdDocuments string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDNSZoneNameDocuments}'

// Cosmos DB
resource databaseAccounts 'Microsoft.DocumentDB/databaseAccounts@2022-11-15' = {
  tags: tags
  name: cosmosDbName
  location: location
  kind: 'GlobalDocumentDB'

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {

    publicNetworkAccess: 'Disabled'
    networkAclBypass: 'AzureServices'
    virtualNetworkRules: []
    minimalTlsVersion: 'Tls12'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
    ]
    cors: []

    capabilities: [
      {
        name: 'EnableGremlin'
      }
      {
        name: 'EnableServerless'
      }
    ]
    databaseAccountOfferType: 'Standard'
    ipRules: []
    backupPolicy: {
      type: 'Continuous'
    }
  }
}

// Create Database
resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases@2022-05-15' = {
  parent: databaseAccounts
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

// Create Graph Database
resource graph 'Microsoft.DocumentDb/databaseAccounts/gremlinDatabases/graphs@2022-05-15' = {
  parent: accountName_databaseName
  name: graphName
  properties: {
    resource: {
      id: graphName
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/myPathToNotIndex/*'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/myPartitionKey'
        ]
        kind: 'Hash'
      }
    }
  }
}

// Create Private Endpoint
resource privateEndpoints_Gremlin 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${cosmosDbName}${nameSeparator}pep_gremlin'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${cosmosDbName}${nameSeparator}pep_gremlin'
        properties: {
          privateLinkServiceId: databaseAccounts.id
          groupIds: [
            'Gremlin'
          ]
        }
      }
    ]
    subnet: {
      id: pepSubnetId
    }
    customNetworkInterfaceName: '${cosmosDbName}${nameSeparator}gremlin${nameSeparator}nic'
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: []
}

// Create Private Endpoint
resource privateEndpoints_Documents 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${cosmosDbName}${nameSeparator}pep_documents'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${cosmosDbName}${nameSeparator}pep_documents'
        properties: {
          privateLinkServiceId: databaseAccounts.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
    subnet: {
      id: pepSubnetId
    }
    customNetworkInterfaceName: '${cosmosDbName}${nameSeparator}documents${nameSeparator}nic'
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: []
}

// Private Dns Zone Groups
resource privateDnsZoneGroupsGremlin 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDnsZoneGroupsGremlin'
  //  name: '${privateEndpoints_Gremlin}/privateDnsZoneGroupsGremlin'
  parent: privateEndpoints_Gremlin
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.gremlin.cosmos.azure.com' // privateDnsZoneNameCosmosDb
        properties: {
          privateDnsZoneId: privateDnsZoneIdCosmosDb
        }
      }
    ]
  }
}

// Private Dns Zone Groups
resource privateDnsZoneGroupsDocuments 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDnsZoneGroupsDocuments'
  parent: privateEndpoints_Documents
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.documents.azure.com' // privateDnsZoneNameDocuments
        properties: {
          privateDnsZoneId: privateDnsZoneIdDocuments
        }
      }
    ]
  }
}
