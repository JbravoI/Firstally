targetScope = 'resourceGroup'
param tags object
param location string
param containerInstanceImageloader string
param containerInstanceImageservice string //= 'mcr.microsoft.com/azuredocs/aci-helloworld'
param portnumber int = 80
param cpuCores int //#int = 2
param memoryInGb int //= 3
param containerGroupsubnetId string
param containerGroupsubnetname string

param containerGroupName string
param containerRegistry string
//param containerGroupNames array
param resourceGroupName string
@secure()
param containerRegistryPassword string
param containerRegistryUsername string
param containerRegistryUserAssignedIdentityId string

param CAFPrefix string
param nameSeparator string
param gatewaySubnetId string
param certificateName string
param wafRuleSetVersion string
param coreSubscriptionId string
param coreResourceGroupName string
param userAssignedIdentityId string

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Always'

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' =  {
  name: containerGroupName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerRegistryUserAssignedIdentityId}': {}
    }
  }
  properties: {
    containers: [
      {
        name: '${containerGroupName}-svc'
        properties: {
          image: containerInstanceImageservice
          ports: [
            {
              port: 443
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
              gpu: {
                count: 1
                sku: 'K80'
              }
            }
          }
          environmentVariables: [
          {
            name: 'REGISTRY_SERVER'
            value: containerRegistry
          }
          {
            name: 'REGISTRY_USERNAME'
            value: containerRegistryUsername
          }
          {
            name: 'REGISTRY_PASSWORD'
            secureValue: containerRegistryPassword
          }
        ]
        }
      }
      {
        name: '${containerGroupName}-ldr'
        properties: {
          image: containerInstanceImageloader
          ports: [
            {
              port: portnumber
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
              gpu: {
                count: 1
                sku: 'K80'
              }
            }
          }
          environmentVariables: [
          {
            name: 'REGISTRY_SERVER'
            value: containerRegistry
          }
          {
            name: 'REGISTRY_USERNAME'
            value: containerRegistryUsername
          }
          {
            name: 'REGISTRY_PASSWORD'
            secureValue: containerRegistryPassword
          }
        ]
        }
      }
  ]
    imageRegistryCredentials: [
      {
        server: '${containerRegistry}${environment().suffixes.acrLoginServer}'
        username: containerRegistryUsername
        password: containerRegistryPassword
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
    subnetIds: [
      {
        id: containerGroupsubnetId
        name: containerGroupsubnetname
      }
    ]
  }
}


output location string = location
output CAFPrefix string = CAFPrefix
output nameSeparator string = nameSeparator
output gatewaySubnetId string = gatewaySubnetId
output certificateName string = certificateName
output wafRuleSetVersion string = wafRuleSetVersion
output resourceGroupName string = resourceGroupName
output coreSubscriptionId string = coreSubscriptionId
output coreResourceGroupName string = coreResourceGroupName
output userAssignedIdentityId string = userAssignedIdentityId
//output containerIPv4Address string = containerGroup.properties.ipAddress.ip
