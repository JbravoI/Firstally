param name string
param location string
param virtualNetworkId string
param pepSubnetId string
param resourceId string
param subResourceTypes array
param zoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName 
  location: 'global'
}

resource privateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${name}-dns-link'
  location: 'global'
  parent: privateDnsZone
  properties:{
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01'  = {
  name: '${name}-pep'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${name}-pep'
        properties: {
          privateLinkServiceId: resourceId
          groupIds: subResourceTypes
        }
      }
    ]
    customNetworkInterfaceName: '${name}-nic'
    subnet: {      
      id: pepSubnetId // '${virtualNetworkId}/subnets/${subnetName}'
    }
  
  }
}

resource privateEndpointDnsLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name:'${name}-pep-dns'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: zoneName 
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
output dnsZoneId string = privateDnsZone.id
