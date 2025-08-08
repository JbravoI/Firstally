param tags object

param internal bool = true

param location string
param CAFPrefix string
param nameSeparator string
param fileshareName string
param virtualNetworkName string
param AzureContainerSubnet string
param logAnalyticsWorkspaceName string
param fileshareStorageAccountName string
param managedEnvironmentName string = '${CAFPrefix}${nameSeparator}cae'

// Get a reference to the existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

// Get a Reference to the Existing Storage
resource storageAccounts 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: fileshareStorageAccountName
}

// Get a reference to Existing Virtual Network
resource virtualNetworks 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: virtualNetworkName
}

// Get a reference to Existing Subnet
resource containerSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  parent: virtualNetworks
  name: AzureContainerSubnet
}

// Create Managed Environment
resource managedEnvironments 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: managedEnvironmentName
  location: location
  sku: {
    name: 'Consumption'
  }
  tags: tags
  properties: {
    vnetConfiguration: {
      internal: internal
      infrastructureSubnetId: containerSubnet.id
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
    customDomainConfiguration: {
      dnsSuffix: ''
      certificatePassword: ''
      certificateValue: ''
    }
  }
  dependsOn: [

  ]
}

// Configure Fileshare
resource storages 'Microsoft.App/managedEnvironments/storages@2022-10-01' = {
  parent: managedEnvironments
  name: 'fileshare'
  properties: {
    azureFile: {
      accountKey: storageAccounts.listKeys('2021-06-01').keys[0].value
      accountName: storageAccounts.name
      shareName: fileshareName
      accessMode: 'ReadWrite'
    }
  }
  dependsOn: [

  ]
}

output managedEnvironmentIp string = managedEnvironments.properties.staticIp
output managedEnvironmentDomainName string = managedEnvironments.properties.defaultDomain
output managedEnvironmentId string = managedEnvironments.id
