targetScope = 'resourceGroup'
param tags object
param CAFPrefix string
//param resourceGroupName string
param location string
param nameSeparator string
param pepSubnetId string


 
param redisCacheName string = '${CAFPrefix}${nameSeparator}redis'
param redisCacheSku string = 'Standard'
param redisCacheSize int = 1
param virtualNetworkId string
param privateEndpointName string = '${redisCacheName}${nameSeparator}pep'
param coreSubscriptionId string
param coreResourceGroupName string
param privateDnsZoneNameRedis string 
param enableredisCachePrivateLink bool 
param privateDNSZoneIdRedis string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameRedis}'


resource redisCache 'Microsoft.Cache/redis@2022-06-01'= {
  name: redisCacheName
  location: location
  tags: tags
  properties: {
    sku: {
      name: redisCacheSku
      family: 'C'
      capacity: redisCacheSize
    }
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    enableNonSslPort: false
  }
}

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: redisCache.id
          groupIds: [
            'redisCache'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${redisCache.name}${nameSeparator}nic'
    subnet: {
      id: pepSubnetId
    }
    ipConfigurations: []
    customDnsConfigs: []

  }
}

// Private DNS Zone Groups / RedisCache
resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-11-01' = {
  name: 'privateDNSZoneGroupsVaultCore'
  parent: privateEndpoints
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameRedis
        properties: {
          privateDnsZoneId: privateDNSZoneIdRedis
        }
      }
    ]
  }
  dependsOn:[
    
  ]
}


//This should be turned to true when you want the pep to be in the same rg and not the core
module redisCachePrivateLink '../VirtualMachine/private-endpoint.bicep' = if (enableredisCachePrivateLink == true) {
  name: 'redisCachePrivateLink'
  params:{
    location:location
    name: redisCache.name
    virtualNetworkId: virtualNetworkId
    pepSubnetId: pepSubnetId 
    zoneName: privateDnsZoneNameRedis 
    subResourceTypes:[
       'redisCache'
    ]
    resourceId: redisCache.id
  }
}


output redisCacheHostName string = redisCache.properties.hostName
output redisCachePort int = redisCache.properties.port
output redisCacheSslPort int = redisCache.properties.sslPort
output coreSubscriptionId string =coreSubscriptionId
output coreResourceGroupName string =coreResourceGroupName
output privateDnsZoneNameRedis string =privateDnsZoneNameRedis
output virtualNetworkId string =virtualNetworkId
