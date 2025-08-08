targetScope = 'resourceGroup'
param containerApp1Name string
param containerApp2Name string 
param CAFPrefix string
param nameSeparator string
param location string






resource containerApp1 'Microsoft.App/containerApps@2022-11-01-preview' existing = {
  name: containerApp1Name
}

resource containerApp2 'Microsoft.App/containerApps@2022-11-01-preview' existing = {
  name: containerApp2Name
}


// resource applicationGateways 'Microsoft.Network/applicationGateways@2019-09-01' existing = {
//   name: '${CAFPrefix}${nameSeparator}agw'
// }

resource workspaces 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${CAFPrefix}${nameSeparator}law'
}

// Get a reference to Existing Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: '${CAFPrefix}${nameSeparator}vnet'
}

// Get a reference to Existing Subnet
resource GatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: vnet
  name: 'AzureAppGatewaySubnet'
}

// Create a User Assigned Identity
resource userAssignedIdentities 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing  = {
  name: '${CAFPrefix}${nameSeparator}id'
}


resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-02-01' existing  =  {
  name: '${CAFPrefix}${nameSeparator}agw${nameSeparator}pip'
}


output agwPublicIP string = publicIPAddresses.properties.ipAddress
output hostname1 string = replace(containerApp1.properties.configuration.ingress.fqdn, 'https://', '')
output hostname2 string = replace(containerApp2.properties.configuration.ingress.fqdn, 'https://', '')

output location string = location
output gatewaySubnetId string = GatewaySubnet.id
output userAssignedIdentityId string = userAssignedIdentities.id
output logAnalyticsWorkspaceId string = workspaces.id
