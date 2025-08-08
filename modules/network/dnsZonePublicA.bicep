param dnsIPAddress string
param publicDNSFQDN string

var dnsZonesName = 'brado.ai'

// Identify Public DNS Zone
resource dnsZones 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZonesName
  location: 'global'
}

// Create A Records
resource A 'Microsoft.Network/dnszones/A@2018-05-01' = {
  parent: dnsZones
  name: publicDNSFQDN
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: dnsIPAddress
      }
    ]
    targetResource: {}
  }
}
