param publicDNSFQDN string
param dnsApiIPAddress string

var dnsZonesName = 'brado.ai'

// Identify Public DNS Zone
resource dnsZones 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZonesName
  location: 'global'
}

// Create B Records
resource B 'Microsoft.Network/dnszones/A@2018-05-01' = {
  parent: dnsZones
  name: '${publicDNSFQDN}-chatapi'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: dnsApiIPAddress
      }
    ]
    targetResource: {}
  }
}


// // Create A Records
// resource A 'Microsoft.Network/dnszones/A@2018-05-01' = {
//   parent: dnsZones
//   name: '${publicDNSFQDN}-ui'
//   properties: {
//     TTL: 3600
//     ARecords: [
//       {
//         ipv4Address: dnsApiIPAddress
//       }
//     ]
//     targetResource: {}
//   }
// }

