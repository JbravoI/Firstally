// Set the scope to the subscription
targetScope = 'tenant'

param subscriptionId string
param environmentName string = 'dev'
param location string = 'eastus2'
param customerName string = 'firstally'

param addressSpacePrefix string = '10.1'
param privateDNSZoneNameKeyVault string = 'Not Needed'
param logAnalyticsWorkspaceName string = '${CAFPrefix}${nameSeparator}lga'
param mariaUserName string = ''
param vmUserNameValue string = '${CAFPrefix}${nameSeparator}vm'
param vmUserName string = '${CAFPrefix}${nameSeparator}vm'
param administratorLogin string = '${CAFPrefix}${nameSeparator}admin'
param addressSpace string = '10.1.4.0/22'
param thirdOctet int = 4
param mariaSecretName string = 'mariaSecretName'
param vmSecretName string = 'test'

// Configure Customer Prefix
param CAFPrefix string = '${customerName}${nameSeparator}${environmentName}${nameSeparator}eus'

param nameSeparator string = '-'

// Resource Group Name
param resourceGroupName string = '${CAFPrefix}${nameSeparator}rg'

// Default Tag Set
param tags object = {
  ModifiedBy: ''
  ModifiedDateTime: ''
  Startup: 'NA'
  Shutdown: 'NA'
  AutoScale: 'NA'
  Monitor: 'NA'
  CostCategory: 'Network'
  Environment: environmentName
  Customer: customerName
}

module resourceGroup '../modules/resourceGroup.bicep' = {
  scope: subscription(subscriptionId)
  name: 'resourceGroup'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

module submodule 'submodule.bicep' = {
  scope: subscription(subscriptionId)
  name: 'submodule'
  params: {
  resourceGroupName: resourceGroupName
  nameSeparator: nameSeparator
  CAFPrefix: CAFPrefix
  addressSpacePrefix: addressSpacePrefix
  privateDNSZoneNameKeyVault: privateDNSZoneNameKeyVault
  logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  mariaUserName: mariaUserName
  vmUserNameValue: vmUserNameValue
  vmUserName: vmUserName
  administratorLogin: administratorLogin
  addressSpace: addressSpace
  mariaSecretName: mariaSecretName
  vmSecretName: vmSecretName
  location: location
  tags: tags
  thirdOctet: thirdOctet
  }
  dependsOn: [
    resourceGroup
  ]
}
