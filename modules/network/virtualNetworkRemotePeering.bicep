param coreVirtualNetworkName string
param virtualNetworksName string
param resourceGroupName string
param subscriptionId string

// Remote Core to Customer Peer - Existing Virtual Network
resource remoteVirtualNetworks 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: coreVirtualNetworkName
}

// Remote Core to Customer Peer
resource remoteVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: 'core-to-${virtualNetworksName}'
  parent: remoteVirtualNetworks
  properties: {
    allowVirtualNetworkAccess: true
    allowGatewayTransit: true
    allowForwardedTraffic: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(subscriptionId, resourceGroupName, 'Microsoft.Network/virtualNetworks', virtualNetworksName)
    }
  }
}
