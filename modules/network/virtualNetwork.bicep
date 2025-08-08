param tags object

// param coreResourceGroupName string
// param coreSubscriptionId string
param addressSpacePrefix string
// param resourceGroupName string
// param subscriptionId string
param natGatewayName string
param nameSeparator string
param addressSpace string
param CAFPrefix string
param location string

param subnets array

var dnsServers = [
  '10.24.2.4'
]

// Create Network Security Groups for each subnet
resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2019-02-01' = [for (subnet, i) in subnets: if (subnet.name != 'AzureAppGatewaySubnet') {
  name: '${toLower(subnet.name)}${nameSeparator}nsg'
  location: location
  tags: tags
  properties: {
    securityRules: ((subnet.name == 'AzureContainerSubnet') ? [
      {
        name: 'Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_UDP'
        properties: {
          description: 'internal AKS secure connection between underlying nodes and control plane..'
          protocol: 'UDP'
          sourcePortRange: '*'
          destinationPortRange: '1194'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud.${location}'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow_Internal_AKS_Connection_Between_Nodes_And_Control_Plane_TCP'
        properties: {
          description: 'internal AKS secure connection between underlying nodes and control plane..'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '9000'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud.${location}'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow_Azure_Monitor'
        properties: {
          description: 'Allows outbound calls to Azure Monitor.'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud.${location}'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow_Outbound_443'
        properties: {
          description: 'Allowing all outbound on port 443 provides a way to allow all FQDN based outbound dependencies that don\'t have a static IP'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow_NTP_Server'
        properties: {
          description: 'NTP server'
          protocol: 'UDP'
          sourcePortRange: '*'
          destinationPortRange: '123'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Allow_Container_Apps_control_plane'
        properties: {
          description: 'Container Apps control plane'
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 150
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '5671'
            '5672'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'CustomerInboundAllow'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: addressSpace
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: [
            '${addressSpace}' // Current Customer Address Space
            '${addressSpacePrefix}.0.0/22' // Core Environment
          ]
          destinationAddressPrefixes: []
        }
      }
      //adding rule for Virtual Machine NSG
      {
        name: 'VMInboundAllow'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 170
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: [
            '${addressSpace}' // Current Customer Address Space
            '${addressSpacePrefix}.0.0/22' // Core Environment
          ]
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'CustomerInboundDeny'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '${addressSpacePrefix}.0.0/16' // Network Address Space
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 101
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    // else
    ] : [{
        name: 'CustomerInboundAllow'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: ''
          destinationAddressPrefix: addressSpace
          access: 'Allow'
          priority: 100
          sourceApplicationSecurityGroups: []
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: [
            '${addressSpace}' // Current Customer Address Space
            '${addressSpacePrefix}.0.0/22' // Core Environment
          ]
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'CustomerInboundDeny'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '${addressSpacePrefix}.0.0/16' // Network Address Space
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 101
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ])
  }
  dependsOn: []
}]

// Create Virtual Network
resource virtualNetworks 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: '${CAFPrefix}${nameSeparator}vnet'
  location: location
  tags: tags
  properties: {
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: subnet.name == 'AzureContainerSubnet' ? {
        networkSecurityGroup: {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', '${subnet.name}${nameSeparator}nsg')
        }
        addressPrefix: subnet.subnetPrefix
        delegations: []
        // else 
      } : subnet.name == 'AzureAppGatewaySubnet' ? {
        addressPrefix: subnet.subnetPrefix
        delegations: []
        serviceEndpoints: [
          {
            service: 'Microsoft.KeyVault'
            locations: [ location ]
          }
        ]
        // else 
      } : subnet.name == 'AzureMariaDBSubnet' ? {
        networkSecurityGroup: {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', '${subnet.name}${nameSeparator}nsg')
        }
        addressPrefix: subnet.subnetPrefix
        delegations: []
        serviceEndpoints: [
          {
            service: 'Microsoft.Sql'
            locations: [ location ]
          }
        ]
        // else 
   /**   } : subnet.name == 'AzureContainerGroupSubnet' ? {
        networkSecurityGroup: {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', '${subnet.name}${nameSeparator}nsg')
        }
        addressPrefix: subnet.subnetPrefix
        delegations: 'Microsoft.ContainerInstance'
*/
      // else
      } : {
        networkSecurityGroup: {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', '${subnet.name}${nameSeparator}nsg')
        }
        addressPrefix: subnet.subnetPrefix
        natGateway: {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/natGateways', natGatewayName)
        }
      }
    }]
    dhcpOptions: {
      dnsServers: dnsServers
    }
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
  }
  dependsOn: [
    networkSecurityGroups
  ]
}

// Setup Fixed Core Variables
var coreVirtualNetworkName = 'platform-core-eus-vnet'

// // Remote Core to Customer Peer - Existing Virtual Network
// resource remoteVirtualNetworks 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
//   scope: resourceGroup(coreSubscriptionId, coreResourceGroupName)
//   name: coreVirtualNetworkName
// }

// // Customer to Core Peer
// resource localVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
//   name: 'core-to-${remoteVirtualNetworks.name}'
//   parent: virtualNetworks
//   properties: {
//     allowVirtualNetworkAccess: true
//     allowGatewayTransit: true
//     allowForwardedTraffic: true
//     useRemoteGateways: true
//     remoteVirtualNetwork: {
//       id: resourceId(coreSubscriptionId, coreResourceGroupName, 'Microsoft.Network/virtualNetworks', coreVirtualNetworkName)
//     }
//   }
// }

// // Virtual Network
// module virtualNetworkRemotePeering 'virtualNetworkRemotePeering.bicep' = {
//   scope: resourceGroup(coreSubscriptionId, coreResourceGroupName)
//   name: 'remotePeering'
//   params: {
//     coreVirtualNetworkName: coreVirtualNetworkName
//     virtualNetworksName: virtualNetworks.name
//     resourceGroupName: resourceGroupName
//     subscriptionId: subscriptionId
//   }
//   dependsOn: []
// }

output virtualNetworkName string = virtualNetworks.name
output virtualNetworkId string = virtualNetworks.id
output containerSubnetName string = virtualNetworks.properties.subnets[0].name
output containerSubnetId string = virtualNetworks.properties.subnets[0].id
output vmSubnetName string = virtualNetworks.properties.subnets[0].name
output vmSubnetId string = virtualNetworks.properties.subnets[0].id
output mariaSubnetName string = virtualNetworks.properties.subnets[2].name
output mariaSubnetId string = virtualNetworks.properties.subnets[2].id
output pepSubnetName string = virtualNetworks.properties.subnets[3].name
output pepSubnetId string = virtualNetworks.properties.subnets[3].id
output gatewaySubnetName string = virtualNetworks.properties.subnets[5].name
output gatewaySubnetId string = virtualNetworks.properties.subnets[5].id
/**
output containerGroupSubnetName string = virtualNetworks.properties.subnets[6].name
output containerGroupSubnetId string = virtualNetworks.properties.subnets[6].id
*/
