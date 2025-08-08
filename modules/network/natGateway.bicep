
param tags object

param publicIpName string = '${natGatewayName}${nameSeparator}pip'
param natGatewayName string = '${CAFPrefix}${nameSeparator}ngw'
param nameSeparator string
param CAFPrefix string
param location string

// Create Public IP Address
resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Create NAT Gateway
resource natGateways 'Microsoft.Network/natGateways@2022-07-01' = {
  name: natGatewayName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
  ]
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIPAddresses.id
      }
    ]
  }
  dependsOn: [
    
  ]
}

output natGatewayName string = natGateways.name

