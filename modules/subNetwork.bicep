// Set the scope to the subscription
targetScope = 'subscription'

param tags object

param fileshareSubResourceNames array
param dataLakeSubResourceNames array
param containerComputeConfig array
param containerAppImages array
param containerAppNames array
param containerScaling array
/**
param containerInstanceImageloader string
param containerInstanceImageservice string
param containerGroupName string **/


//enable resouces to deploy
param enablekeyVaultAccessPolicy bool
param enableMariaDB bool
param enableCosmosDB bool
param enableDatalake bool
param enableFileShare bool
param enableContainerAppEnvironment bool
param enablecontainerApps bool
param enablecoreKeyVaultPolicy bool
param enableaddPrivateDNSARecords_cae bool
param enablelogAnalyticsWorkspace bool
param enableuserAssignedIdentity bool
param enableredisCache bool
param enablenatGateway bool
param enablevirtualNetwork bool
param enablekeyVault bool
param enableroles_ResourceGroupOwner bool
param enableredisCachePrivateLink bool 


param privateDnsZoneNameDfs string
param privateDnsZoneNameRedis string
param privateDnsZoneNameFile string
//param privateDnsZoneNameVm string
param privateDnsZoneNameBlob string
param privateDnsZoneNameTable string
param privateDnsZoneNameQueue string
param privateDnsZoneNameMariaDb string
param privateDNSZoneNameKeyVault string
param privateDNSZoneNameGremlin string
param privateDNSZoneNameDocuments string

param dataLakeStorageAccountName string
param logAnalyticsWorkspaceName string
param containerRegistryUsername string
@secure()
param containerRegistryPassword string
param containerRegistry string
param coreVirtualNetworkName string
param coreResourceGroupName string
param addressSpacePrefix string
param coreSubscriptionId string
param certificateName string
param mariaUserNameValue string
param vmUserNameValue string
param wafRuleSetVersion string
param resourceGroupName string
param coreKeyVaultName string
param subscriptionId string
param nameSeparator string
param publicDNSFQDN string
param mariaUserName string
param vmUserName string
param fileshareName string
param addressSpace string
@secure()
param mariaSecretName string
param vmSecretName string
param CAFPrefix string
param location string

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
module logAnalyticsWorkspace 'shared/logAnalytics.bicep' =  if (enablelogAnalyticsWorkspace == true)  {
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
module userAssignedIdentity 'security/managedIdentity.bicep' =   if (enableuserAssignedIdentity == true)  {
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
module natGateway 'network/natGateway.bicep' = if (enablenatGateway == true)  {
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
module virtualNetwork 'network/virtualNetwork.bicep' = if (enablevirtualNetwork == true)  {
  scope: resourceGroup(resourceGroupName)
  name: 'virtualNetwork'
  params: {
    natGatewayName: natGateway.outputs.natGatewayName
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    addressSpacePrefix: addressSpacePrefix
    resourceGroupName: resourceGroupName
    subscriptionId: subscriptionId
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
module keyVault 'security/keyVault.bicep' = if (enablekeyVault == true)  {
  scope: resourceGroup(resourceGroupName)
  name: 'keyVault'
  params: {
    privateDNSZoneNameKeyVault: privateDNSZoneNameKeyVault
    pepSubnetId: virtualNetwork.outputs.pepSubnetId
    coreResourceGroupName: coreResourceGroupName
    mariaUserNameValue: mariaUserNameValue
    vmUserNameValue: vmUserNameValue
    coreSubscriptionId: coreSubscriptionId
    mariaSecretName: mariaSecretName
    vmSecretName: vmSecretName
    mariaUserName: mariaUserName
    vmUserName: vmUserName
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Data Platform
module subDataPlatform 'subPlatform.bicep' = {
  name: 'subdataplatform'
  params: {
    privateDNSZoneNameDocuments: privateDNSZoneNameDocuments
    privateDNSZoneNameGremlin: privateDNSZoneNameGremlin
    privateDnsZoneNameMariaDb: privateDnsZoneNameMariaDb
    privateDnsZoneNameTable: privateDnsZoneNameTable
    privateDnsZoneNameQueue: privateDnsZoneNameQueue
    privateDnsZoneNameFile: privateDnsZoneNameFile
    privateDnsZoneNameBlob: privateDnsZoneNameBlob
    privateDnsZoneNameDfs: privateDnsZoneNameDfs
    //privateDnsZoneNameVm: privateDnsZoneNameVm
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    userAssignedIdentityId: userAssignedIdentity.outputs.userAssignedIdentityId
    containerSubnetName: virtualNetwork.outputs.containerSubnetName
    //containerSubnetId: virtualNetwork.outputs.containerSubnetId
    virtualNetworkName: virtualNetwork.outputs.virtualNetworkName
    virtualNetworkId: virtualNetwork.outputs.virtualNetworkId
    gatewaySubnetId: virtualNetwork.outputs.gatewaySubnetId
    dataLakeStorageAccountName: dataLakeStorageAccountName
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
    mariaDbSubnetId: virtualNetwork.outputs.mariaSubnetId
    fileshareSubResourceNames: fileshareSubResourceNames
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    dataLakeSubResourceNames: dataLakeSubResourceNames
    privateDnsZoneNameRedis: privateDnsZoneNameRedis
    pepSubnetId: virtualNetwork.outputs.pepSubnetId
    containerComputeConfig: containerComputeConfig
    coreVirtualNetworkName: coreVirtualNetworkName
    coreResourceGroupName: coreResourceGroupName
    keyVaultName: keyVault.outputs.keyVaultName
    coreSubscriptionId: coreSubscriptionId
    containerAppImages: containerAppImages
    containerRegistry: containerRegistry
    wafRuleSetVersion: wafRuleSetVersion
    resourceGroupName: resourceGroupName
    containerAppNames: containerAppNames
    containerScaling: containerScaling
    coreKeyVaultName: coreKeyVaultName
    certificateName: certificateName
    subscriptionId: subscriptionId
    fileshareName: fileshareName
    publicDNSFQDN: publicDNSFQDN
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
    enablekeyVaultAccessPolicy: enablekeyVaultAccessPolicy
    enableMariaDB: enableMariaDB
    enableredisCache: enableredisCache
    enableCosmosDB: enableCosmosDB
    enableDatalake: enableDatalake
    enableFileShare: enableFileShare
    enableContainerAppEnvironment: enableContainerAppEnvironment
    enablecontainerApps: enablecontainerApps
    enablecoreKeyVaultPolicy: enablecoreKeyVaultPolicy
    enableaddPrivateDNSARecords_cae: enableaddPrivateDNSARecords_cae
    enableroles_ResourceGroupOwner: enableroles_ResourceGroupOwner
    enableredisCachePrivateLink: enableredisCachePrivateLink
    //vmSubnetId: virtualNetwork.outputs.vmSubnetId

/** containerInstanceImageloader: containerInstanceImageloader
    containerInstanceImageservice: containerInstanceImageservice
    containerGroupName: containerGroupName
    containerGroupsubnetId: virtualNetwork.outputs.containerGroupSubnetId
    containerGroupsubnetname: virtualNetwork.outputs.containerGroupSubnetName **/
  }
  dependsOn: [
    keyVault
  ]
}
