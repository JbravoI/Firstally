// Set the scope to the subscription
targetScope = 'subscription'

// Configure Customer Prefix
param CAFPrefix string
param nameSeparator string 
param resourceGroupName string

param addressSpacePrefix string
param mariaUserName string
param vmUserNameValue string
param mariaSecretName string
param privateDNSZoneNameKeyVault string
param logAnalyticsWorkspaceName string 
param vmUserName string
param administratorLogin string 
param addressSpace string
param vmSecretName string 
param location string
param tags object

// Increment the third octets in CIDR to account for /22 subnet subdivision
param thirdOctet int
param thirdOctet_plus2 int = thirdOctet + 2
param thirdOctet_plus3 int = thirdOctet + 3

// Convert int outputs to strings
param thirdOctetPlus_0 string = '${thirdOctet}'
param thirdOctetPlus_2 string = '${thirdOctet_plus2}'
param thirdOctetPlus_3 string = '${thirdOctet_plus3}'

// Subnets
param subnets array = [
  // Subnet [0]
  {
    name: 'AzureContainerSubnet'
    subnetPrefix: '${addressSpacePrefix}.${thirdOctetPlus_0}.0/23'
  }
  // Subnet [1]
  {
    name: 'AzureCosmosDBSubnet'
    subnetPrefix: '${addressSpacePrefix}.${thirdOctetPlus_2}.0/27'
  }
  // Subnet [2]
  {
    name: 'AzureMariaDBSubnet'
    subnetPrefix: '${addressSpacePrefix}.${thirdOctetPlus_2}.32/27'
  }
  // Subnet [3]
  {
    name: 'AzurePrivateEndpointSubnet'
    subnetPrefix: '${addressSpacePrefix}.${thirdOctetPlus_2}.192/27'
  }
  // Subnet [4]
  {
    name: 'AzureSubnet'
    subnetPrefix: '${addressSpacePrefix}.${thirdOctetPlus_2}.224/27'
  }
  // Subnet [5]
  {
    name: 'AzureAppGatewaySubnet'
    subnetPrefix: '${addressSpacePrefix}.${thirdOctetPlus_3}.0/24'
  }
  // Subnet [6]
/** {
    name: 'AzureContainerGroupSubnet'
    subnetPrefix: '${addressSpacePrefix}.${thirdOctetPlus_2}.64/28'
  } */ 
]

// Log Analytics Workspace for each Instance
module logAnalyticsWorkspace '../modules/shared/logAnalytics.bicep' =  {
  scope: resourceGroup(resourceGroupName)
  name: 'logAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    
  ]
}

// Create User Assigned Managed Identity for CAE
module userAssignedIdentity '../modules/security/managedIdentity.bicep' =   {
  scope: resourceGroup(resourceGroupName)
  name: 'userAssignedIdentity'
  params: {
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}


// NAT Gateway
module natGateway '../modules/network/natGateway.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'natGateway'
  params: {
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    userAssignedIdentity
  ]
}


// Virtual Network
module virtualNetwork '../modules/network/virtualNetwork.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'virtualNetwork'
  params: {
    natGatewayName: natGateway.outputs.natGatewayName
    addressSpacePrefix: addressSpacePrefix
    nameSeparator: nameSeparator
    addressSpace: addressSpace
    CAFPrefix: CAFPrefix
    location: location
    subnets: subnets
    tags: tags
  }
  dependsOn: [
    natGateway
  ]
}


// Key Vault
module keyVault '../modules/security/keyVault.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'keyVault'
  params: {
    privateDNSZoneNameKeyVault: privateDNSZoneNameKeyVault
    pepSubnetId: virtualNetwork.outputs.pepSubnetId
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    virtualNetwork
  ]
}


module generateSecret '../modules/VirtualMachine/keyvaultpassword.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'Secretgnerator'
  params: {
    location: location
    keyVaultName: keyVault.outputs.keyVaultName
    vmSecretName: vmSecretName
  }
}

module sqldatabase '../modules/database/sqldatabase.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'sqldatabase'
  params: {
    location: location
    CAFPrefix: CAFPrefix
    nameSeparator: nameSeparator
    tags: tags
    administratorLoginPassword: generateSecret.outputs.value
    administratorLogin: administratorLogin
  }
  dependsOn: [
    VirtualMachine
  ]
}

// VirtualMachine
module VirtualMachine '../modules/VirtualMachine/virtualMachinefirstally.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'virtualMachine'
  params: {
    virtualMachineName: vmUserName
    vmUserNameValue: vmUserName
    vmSubnetId: virtualNetwork.outputs.vmSubnetId 
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    vmSecretName: generateSecret.outputs.value
    tags: tags
  }
  dependsOn: [
    generateSecret
  ]
}


// VirtualMachine
module appservice '../modules/VirtualMachine/appservice.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'appservice'
  params: {
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    VirtualMachine
  ]
}

