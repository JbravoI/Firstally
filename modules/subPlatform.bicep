targetScope = 'subscription'


param tags object
/**
param containerGroupName string
param cpuCores int = 2 
param memoryInGb int = 3 
param containerGroupsubnetId string
param containerGroupsubnetname string
param containerInstanceImageloader string
param containerInstanceImageservice string **/
param containerScaling array
param containerAppNames array
param containerAppImages array
param containerComputeConfig array
param dataLakeSubResourceNames array
param fileshareSubResourceNames array

param privateDnsZoneNameDfs string
param privateDnsZoneNameFile string
param privateDnsZoneNameBlob string
param privateDnsZoneNameTable string
param privateDnsZoneNameQueue string
//param privateDnsZoneNameVm string
param privateDnsZoneNameMariaDb string
param privateDNSZoneNameGremlin string
param privateDNSZoneNameDocuments string

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
param enableroles_ResourceGroupOwner bool
param enableredisCache bool
param enableredisCachePrivateLink bool 


param location string
param CAFPrefix string
//param vmSubnetId string
param pepSubnetId string
param keyVaultName string
param publicDNSFQDN string
param fileshareName string
param nameSeparator string
param subscriptionId string
param gatewaySubnetId string
param mariaDbSubnetId string
param certificateName string
param virtualNetworkId string
param coreKeyVaultName string
param containerRegistry string
param wafRuleSetVersion string
param resourceGroupName string
param coreSubscriptionId string
param virtualNetworkName string
param containerSubnetName string
param coreResourceGroupName string
param userAssignedIdentityId string
param coreVirtualNetworkName string
param logAnalyticsWorkspaceId string
param privateDnsZoneNameRedis string
param logAnalyticsWorkspaceName string
param containerRegistryUsername string
@secure()
param containerRegistryPassword string
param dataLakeStorageAccountName string
param userAssignedIdentityPrincipalId string

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: keyVaultName
}


// Assign Resource Group Owner to the User Assigned Identity
module roles_ResourceGroupOwner 'security/rolesResourceGroupOwner.bicep' = if (enableroles_ResourceGroupOwner == true) {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'rolesResourceGroupOwner'
  params: {
    userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
  }
  dependsOn: []
}

// Create Access Policy for Key Vault
module keyVaultAccessPolicy 'security/keyVaultAccessPolicy.bicep' =  if (enablekeyVaultAccessPolicy == true) {
  scope: resourceGroup(resourceGroupName)
  name: 'keyVaultAccessPolicy'
  params: {
    userAssignedIdentitiesPrincipalId: userAssignedIdentityPrincipalId
    keyVaultName: keyVaultName
  }
  dependsOn: [
    roles_ResourceGroupOwner
  ]
}

// MariaDB
module mariadb 'database/mariadb.bicep' =  if (enableMariaDB == true) {
  scope: resourceGroup(resourceGroupName)
  name: 'mariaDB'
  params: {
    mariaUserNameValue: keyVault.getSecret('MariaDBAdminName')
    mariaSecretName: keyVault.getSecret('MariaDBAdminPassword')
    privateDnsZoneNameMariaDb: privateDnsZoneNameMariaDb
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    mariaDbSubnetId: mariaDbSubnetId
    nameSeparator: nameSeparator
    pepSubnetId: pepSubnetId
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [ 
    keyVaultAccessPolicy
  ]
}
/**
// VirtualMachine
module VirtualMachine 'VirtualMachine/virtualMachine.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'virtualMachine'
  params: {
    vmSecretName: keyVault.getSecret('VMAdminPassword')
    vmSubnetId:vmSubnetId
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    mariadb
  ]
}
*/
/**
// VirtualMachine
module VirtualMachinetest 'VirtualMachine/virtualMachinetest.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'virtualMachinetest'
  params: {
    vmSecretName: keyVault.getSecret('VMAdminPassword')
    //vmUserNameValue: keyVault.getSecret('vmUserName')
    //privateDnsZoneNameVm: privateDnsZoneNameVm
    //coreResourceGroupName: coreResourceGroupName
    //coreSubscriptionId: coreSubscriptionId
    vmSubnetId:vmSubnetId
    nameSeparator: nameSeparator
    //pepSubnetId: pepSubnetId
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    VirtualMachine
  ]
}
*/


// CosmosDB
module cosmosdb 'database/cosmosdb.bicep' =  if (enableCosmosDB == true) {
  scope: resourceGroup(resourceGroupName)
  name: 'cosmosDB'
  params: {
    privateDNSZoneNameDocuments: privateDNSZoneNameDocuments
    privateDNSZoneNameGremlin: privateDNSZoneNameGremlin
    userAssignedIdentityId: userAssignedIdentityId
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    nameSeparator: nameSeparator
    pepSubnetId: pepSubnetId
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    mariadb
  ]
}

// Data Lake Storage
module dataLake 'storage/dataLakeStorageAccount.bicep' =  if (enableDatalake == true) {
  scope: resourceGroup(resourceGroupName)
  name: 'dataLakeSA'
  params: {
    dataLakeStorageAccountName: dataLakeStorageAccountName
    dataLakeSubResourceNames: dataLakeSubResourceNames
    privateDnsZoneNameQueue: privateDnsZoneNameQueue
    privateDnsZoneNameTable: privateDnsZoneNameTable
    privateDnsZoneNameBlob: privateDnsZoneNameBlob
    privateDnsZoneNameFile: privateDnsZoneNameFile
    privateDnsZoneNameDfs: privateDnsZoneNameDfs
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    storageAccountSku: 'Standard_LRS'
    storageAccountKind: 'StorageV2'
    nameSeparator: nameSeparator
    pepSubnetId: pepSubnetId
    location: location
    isHnsEnabled: true
    tags: tags
  }
  dependsOn: [
    cosmosdb
  ]
}

// Container Apps Environment Fileshare
module fileshare 'storage/fileshareStorageAccount.bicep' =  if (enableFileShare == true) {
  scope: resourceGroup(resourceGroupName)
  name: 'fileshareSA'
  params: {
    fileshareSubResourceNames: fileshareSubResourceNames
    privateDnsZoneNameFile: privateDnsZoneNameFile
    privateDnsZoneNameBlob: privateDnsZoneNameBlob
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    storageAccountSku: 'Standard_LRS'
    storageAccountKind: 'StorageV2'
    nameSeparator: nameSeparator
    fileshareName: fileshareName
    pepSubnetId: pepSubnetId
    CAFPrefix: CAFPrefix
    isHnsEnabled: false
    location: location
    tags: tags
  }
  dependsOn: [
    dataLake
  ]
}

// Azure Container Apps Environment
module containerAppsEnvironment 'container/containerAppsEnvironment.bicep' =  if (enableContainerAppEnvironment == true){
  scope: resourceGroup(resourceGroupName)
  name: 'acaEnvironment'
  params: {
    fileshareStorageAccountName: fileshare.outputs.storageAccountName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    AzureContainerSubnet: containerSubnetName
    virtualNetworkName: virtualNetworkName
    fileshareName: fileshareName
    nameSeparator: nameSeparator
    CAFPrefix: CAFPrefix
    location: location
    tags: tags
  }
  dependsOn: [
    fileshare
  ]
}

// Build Container Apps
module containerApps 'container/containerApps.bicep' =  if (enablecontainerApps == true) {
  scope: resourceGroup(resourceGroupName)
  name: 'containerApps'
  params: {
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.managedEnvironmentId
    containerRegistryUserAssignedIdentityId: userAssignedIdentityId
    certificateName: certificateName
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    CAFPrefix: CAFPrefix
    nameSeparator: nameSeparator
    gatewaySubnetId: gatewaySubnetId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    publicDNSFQDN: publicDNSFQDN
    coreKeyVaultName: coreKeyVaultName
    userAssignedIdentityId: userAssignedIdentityId
    wafRuleSetVersion: wafRuleSetVersion
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
    containerComputeConfig: containerComputeConfig
    containerAppImages: containerAppImages
    containerRegistry: containerRegistry
    resourceGroupName: resourceGroupName
    containerAppNames: containerAppNames
    containerScaling: containerScaling
    // keyVaultName: keyVaultName
    location: location
    tags: tags
  }
  dependsOn: [
    containerAppsEnvironment
  ]
}

/**
// Build Container Instance
module containerGroup 'container/containerinstance.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'containerGroup'
  params: {
    containerRegistryUserAssignedIdentityId: userAssignedIdentityId
    certificateName: certificateName
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    CAFPrefix: CAFPrefix
    nameSeparator: nameSeparator
    gatewaySubnetId: gatewaySubnetId
    userAssignedIdentityId: userAssignedIdentityId
    wafRuleSetVersion: wafRuleSetVersion
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
    cpuCores: cpuCores
    memoryInGb: memoryInGb
    containerInstanceImageloader: containerInstanceImageloader
    containerInstanceImageservice: containerInstanceImageservice
    containerRegistry: containerRegistry
    resourceGroupName: resourceGroupName
    containerGroupsubnetId: containerGroupsubnetId
    containerGroupName:  containerGroupName
    containerGroupsubnetname: containerGroupsubnetname
    // keyVaultName: keyVaultName
    location: location
    tags: tags
  }
  dependsOn: [
    containerApps
  ]
}
*/
// Create Access Policy for Core Key Vault
module coreKeyVaultPolicy 'security/coreKeyVaultAccessPolicy.bicep' =  if (enablecoreKeyVaultPolicy == true) {
  scope: resourceGroup(coreSubscriptionId, coreResourceGroupName)
  name: 'coreKeyVaultAccessPolicy'
  params: {
    userAssignedIdentitiesPrincipalId: userAssignedIdentityPrincipalId
    coreKeyVaultName: coreKeyVaultName
  }
  dependsOn: [
    containerApps
  ]
}

// Create Private DNS Zone A Records for @ and *
module addPrivateDNSARecords_cae 'network/dnsZonePrivateA_cae.bicep' =  if (enableaddPrivateDNSARecords_cae == true) {
  scope: resourceGroup(coreSubscriptionId, coreResourceGroupName)
  name: 'addPrivateDNSARecordsCAE'
  params: {
    managedEnvironmentDomainName: containerAppsEnvironment.outputs.managedEnvironmentDomainName
    managedEnvironmentIPAddress: containerAppsEnvironment.outputs.managedEnvironmentIp
    coreVirtualNetworkName: coreVirtualNetworkName
    virtualNetworkId: virtualNetworkId
    nameSeparator: nameSeparator
  }
  dependsOn: [
    coreKeyVaultPolicy
  ]
}

// Create Private DNS Zone A Records for @ and *
module redisCache 'redis/redis.bicep' =  if (enableredisCache == true) {
  scope: resourceGroup(resourceGroupName)
  name: 'redisCache'
  params: {
    nameSeparator: nameSeparator
    coreResourceGroupName: coreResourceGroupName
    coreSubscriptionId: coreSubscriptionId
    CAFPrefix: CAFPrefix
    location: location
    privateDnsZoneNameRedis: privateDnsZoneNameRedis
    pepSubnetId: pepSubnetId
    //containerSubnetId: containerSubnetId
    tags: tags
    virtualNetworkId: virtualNetworkId
    enableredisCachePrivateLink: enableredisCachePrivateLink
  }
  dependsOn: [
    coreKeyVaultPolicy
  ]
}

