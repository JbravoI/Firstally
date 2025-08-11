
param tags object
param location string
param CAFPrefix string
param nameSeparator string

param appServicePlanName string = '${CAFPrefix}${nameSeparator}asp'
param webAppName string =  '${CAFPrefix}${nameSeparator}app221'
param skuName string = 'F1'
param runtimeStack string = 'NODE|18-lts' 
param osType string = 'windows' 

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    tier: skuName 
    capacity: 1
  }
  kind: osType
  properties: {
    reserved: osType == 'windows' 
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: osType
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: osType == 'linux' ? runtimeStack : null
      windowsFxVersion: osType == 'windows' ? runtimeStack : null
      alwaysOn: true
    }
    httpsOnly: true
  }
}

output appServicePlanId string = appServicePlan.id
output webAppUrl string = 'https://${webAppName}.azurewebsites.net'
