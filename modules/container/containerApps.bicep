targetScope = 'resourceGroup'

param tags object

//param keyVaultName string
param containerScaling array
param containerAppNames array
param containerAppImages array
param containerRegistry string
param containerComputeConfig array

param location string
param resourceGroupName string
param containerRegistryUsername string
@secure()
param containerRegistryPassword string
param containerAppsEnvironmentId string
param containerRegistryUserAssignedIdentityId string

param CAFPrefix string
param publicDNSFQDN string
param nameSeparator string
param gatewaySubnetId string
param certificateName string
param coreKeyVaultName string
param wafRuleSetVersion string
param coreSubscriptionId string
param coreResourceGroupName string
param userAssignedIdentityId string
param logAnalyticsWorkspaceId string

// Build Container Apps
resource containerApps 'Microsoft.App/containerApps@2022-10-01' = [for (containerAppName, i) in containerAppNames: {
  name: containerAppName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerRegistryUserAssignedIdentityId}': {}
    }
  }
  properties: {
    configuration: {
      activeRevisionsMode: 'Multiple'
      ingress: {
        allowInsecure: false
        external: true
        targetPort: 80
        transport: 'auto'
      }
      registries: [
        {
          server: '${containerRegistry}${environment().suffixes.acrLoginServer}'
          username: containerRegistryUsername
          passwordSecretRef: 'container-registry-password'
        }
      ]
      secrets: [
        {
          name: 'container-registry-password'
          value: containerRegistryPassword
        }
      ]
    }
    environmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: containerAppName
          image: containerAppImages[i]
          resources: {
            cpu: json('${containerComputeConfig[i].cpu}')
            memory: '${containerComputeConfig[i].memory}'
          }
        }

      ]
      scale: {
        minReplicas: containerScaling[i].min
        maxReplicas: containerScaling[i].max
      }
    }
  }
}]


output location string = location
output CAFPrefix string = CAFPrefix
output publicDNSFQDN string = publicDNSFQDN
output nameSeparator string = nameSeparator
output gatewaySubnetId string = gatewaySubnetId
output certificateName string = certificateName
output coreKeyVaultName string = coreKeyVaultName
output wafRuleSetVersion string = wafRuleSetVersion
output resourceGroupName string = resourceGroupName
output coreSubscriptionId string = coreSubscriptionId
output coreResourceGroupName string = coreResourceGroupName
output userAssignedIdentityId string = userAssignedIdentityId
output logAnalyticsWorkspaceId string = logAnalyticsWorkspaceId
output containerApp1FQDN string = replace(containerApps[0].properties.configuration.ingress.fqdn, 'https://', '')
output containerApp2FQDN string = replace(containerApps[1].properties.configuration.ingress.fqdn, 'https://', '')
