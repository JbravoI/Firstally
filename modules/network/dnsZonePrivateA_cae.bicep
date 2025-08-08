param managedEnvironmentDomainName string
param managedEnvironmentIPAddress string
param coreVirtualNetworkName string
param virtualNetworkId string
param nameSeparator string

// Get existing Core Virtual Network
resource coreVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: coreVirtualNetworkName
}

// Identify Existing DNS Zone Location
resource dnszones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: managedEnvironmentDomainName
  location: 'Global'

}

// Add * A Record
resource A1 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: dnszones
  name: '*'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: managedEnvironmentIPAddress
      }
    ]
  }
}

// Add @ A Record and 
resource A2 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: dnszones
  name: '@'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: managedEnvironmentIPAddress
      }
    ]
  }
}

// Create a private DNS zone link in Customer Network
resource virtualNetworkLinks_customer 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnszones
  name: '${managedEnvironmentDomainName}${nameSeparator}cust${nameSeparator}link'
  location: 'Global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
  dependsOn: [
  ]
}

// Create a private DNS zone link in Core Network
resource virtualNetworkLinks_core 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnszones
  name: '${managedEnvironmentDomainName}${nameSeparator}core${nameSeparator}link'
  location: 'Global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: coreVirtualNetwork.id
    }
  }
  dependsOn: [
  ]
}
