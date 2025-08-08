targetScope = 'resourceGroup'

param logAnalyticsWorkspaceName string = '${CAFPrefix}${nameSeparator}law'
param nameSeparator string
param CAFPrefix string
param location string
param tags object

@allowed([
  'AgentHealthAssessment'
  'AntiMalware'
  'AzureActivity'
  'ChangeTracking'
  'Security'
  'SecurityInsights'
  'ServiceMap'
  'SQLAssessment'
  'Updates'
  'VMInsights'
])
@description('Solutions that will be added to the Log Analytics Workspace. - DEFAULT VALUE: [AgentHealthAssessment, AntiMalware, AzureActivity, ChangeTracking, Security, SecurityInsights, ServiceMap, SQLAssessment, Updates, VMInsights]')
param logAnalyticsWorkspaceSolutions array = [
  'AzureActivity'
  'ChangeTracking'
  'Security'
  'SecurityInsights'
  'ServiceMap'
]

// Create Log Analytics Workspace
resource workspaces 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
}

// Deploy Log Analytics Workspace Solutions
resource resLogAnalyticsWorkspaceSolutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for solution in logAnalyticsWorkspaceSolutions: if (!empty(logAnalyticsWorkspaceSolutions)) {
  name: '${solution}(${workspaces.name})'
  location: location
  properties: {
    workspaceResourceId: workspaces.id
  }
  plan: {
    name: '${solution}(${workspaces.name})'
    product: 'OMSGallery/${solution}'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}]

output logAnalyticsWorkspaceId string = workspaces.id
output logAnalyticsWorkspaceName string = workspaces.name
