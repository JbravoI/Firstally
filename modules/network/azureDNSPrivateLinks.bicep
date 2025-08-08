param virtualNetworkId string
param virtualNetworkName string
param privatelinkDnsZoneNames array

// Create a private DNS zone link for each privatelink DNS zone
resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for privatelinkDnsZoneName in privatelinkDnsZoneNames: {
  name: '${privatelinkDnsZoneName}/${virtualNetworkName}link'
  location: 'Global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
  dependsOn: []
}]
