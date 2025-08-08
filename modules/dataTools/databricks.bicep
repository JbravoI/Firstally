param tags object

param managedResourceGroupId string = '${subscription().id}/resourceGroups/${managedResourceGroupName}'
param managedResourceGroupName string = '${managedResourceGroupClean}${nameSeparator}mrg'
param managedResourceGroupClean string = replace(resourceGroupName, '-rg', '')
param databricksName string = '${CAFPrefix}${nameSeparator}adb'
param nsgName string = '${databricksName}${nameSeparator}nsg'
param privateDNSZoneNameDatabricks string
param coreResourceGroupName string
param coreSubscriptionId string
param resourceGroupName string
param virtualNetworkId string
param nameSeparator string
param pepSubnetId string
param CAFPrefix string
param location string

param privateDNSZoneIdDatabricks string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDNSZoneNameDatabricks}'



// Create a Databricks Workspace
resource workspaces 'Microsoft.Databricks/workspaces@2022-04-01-preview' = {
  name: databricksName
  location: location
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    requiredNsgRules: 'NoAzureDatabricksRules' // 'AllRules' = Public, 'NoAzureDatabricksRules' = Private, 'NoAzureServiceRules' = MSFT Internal Only
    parameters: {
      enableNoPublicIp: {
        value: true
      }
      customVirtualNetworkId: {
        value: virtualNetworkId
      }
      customPublicSubnetName: {
        value: 'AzureDatabricksPublicSubnet'
      }
      customPrivateSubnetName: {
        value: 'AzureDatabricksPrivateSubnet'
      }
    }
    publicNetworkAccess: 'Disabled'
  }
  tags: tags
}

// Create a Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  location: location
  name: nsgName
  tags: tags
}

// Create a Private Endpoint
resource privateEndpoint_ui 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${databricksName}${nameSeparator}ui${nameSeparator}pep'
  location: location
  properties: {
    subnet: {
      id: pepSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${databricksName}${nameSeparator}ui${nameSeparator}nic'
        properties: {
          privateLinkServiceId: workspaces.id
          groupIds: [
            'databricks_ui_api'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Groups / Databricks
resource privateDnsZoneGroups_ui 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsDatabricks_ui'
  parent: privateEndpoint_ui
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDNSZoneNameDatabricks
        properties: {
          privateDnsZoneId: privateDNSZoneIdDatabricks
        }
      }
    ]
  }
}

// Create a Private Endpoint
resource privateEndpoint_webauth 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${databricksName}${nameSeparator}webauth${nameSeparator}pep'
  location: location
  properties: {
    subnet: {
      id: pepSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${databricksName}${nameSeparator}webauth${nameSeparator}nic'
        properties: {
          privateLinkServiceId: workspaces.id
          groupIds: [
            'browser_authentication'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Groups / Databricks
resource privateDnsZoneGroups_webauth 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsDatabricks_webauth'
  parent: privateEndpoint_webauth
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDNSZoneNameDatabricks
        properties: {
          privateDnsZoneId: privateDNSZoneIdDatabricks
        }
      }
    ]
  }
}
