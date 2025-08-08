targetScope = 'resourceGroup'

param CAFPrefix string
//param resourceGroupName string
param location string
param applicationGatewaySubnetId string
param applicationGatewayName string = '${CAFPrefix}${nameSeparator}api${nameSeparator}agw'
//param certificateName string
param nameSeparator string
param publicDNSFQDN string
param coreKeyVaultName string
param certificateName string
param coreSubscriptionId string
param coreResourceGroupName string
param containerApp1FQDN string
param wafRuleSetVersion string
param containerApp2FQDN string
var publicIPAddressName = '${applicationGatewayName}${nameSeparator}pip'
param webApplicationFirewallId string
//param applicationGatewayLogAnalyticsWorkspaceId string
param applicationGatewayUserAssignedIdentityId string
//param applicationGatewayId string = resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)


// Get Existing Vault
resource vaults 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  scope: resourceGroup(coreSubscriptionId, coreResourceGroupName)
  name: coreKeyVaultName
}


// Create Public IP Address
resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: []
}

resource applicationGatewaysApi 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: applicationGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
     '${applicationGatewayUserAssignedIdentityId}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: applicationGatewaySubnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: certificateName
        properties: {
          keyVaultSecretId: 'https://${vaults.name}${environment().suffixes.keyvaultDns}/secrets/brado-ai-cert'
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${publicIPAddressName}')
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'httpsPort2'
        properties: {
          port: 8443
        }
      }
      {
        name: 'httpsPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool1'
        properties: {
          backendAddresses: [
            {
              fqdn: containerApp1FQDN
            }
          ]
        }
      }
      {
        name: 'backendPool2'
        properties: {
          backendAddresses: [
            {
              fqdn: containerApp2FQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings1'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          probeEnabled: true
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'publicHealthProbe1')
          }
        }
      }
      {
        name: 'httpSettings2'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          probeEnabled: true
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'publicHealthProbe2')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener1'
        properties: {
          frontendIPConfiguration: {
            id:   resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGwPublicFrontendIp') //'${applicationGatewayId}/frontendIPConfigurations/${publicIPAddresses.name}'  //applicationGatewaysApi.frontendIPConfigurations[0].id
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'httpsPort') //applicationGatewaysApi.frontendPorts//[0].id
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, '${certificateName}')
          }
          hostName: '${publicDNSFQDN}-ui.brado.ai'
          requireServerNameIndication: true
        }
      }
      {
        name: 'httpListener2'
        properties: {
          frontendIPConfiguration: {
            id:  resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGwPublicFrontendIp')  //appGateway.frontendIPConfigurations[1].id
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'httpsPort')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, '${certificateName}')
          }
          hostName: '${publicDNSFQDN}-chatapi.brado.ai'
          //requireServerNameIndication: true
        }
      }
   ]
    requestRoutingRules: [
      {
        name: 'httpRule1'
        properties: {
          ruleType: 'Basic'
          priority: 5
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpListener1')//appGateway.httpListeners[0].id
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'backendPool1') //appGateway.backendAddressPools[0].id
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'httpSettings1') //appGateway.backendHttpSettingsCollection[0].id
          }
        }
      }
      {
        name: 'httpRule2'
        properties: {
          ruleType: 'Basic'
          priority: 40
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpListener2')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'backendPool2') 
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'httpSettings1')
          }
        }
      }
    ]
    probes: [
      {
        name: 'publicHealthProbe1'
        properties: {
          protocol: 'Https'
          host: containerApp1FQDN
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'publicHealthProbe2'
        properties: {
          protocol: 'Https'
          host: containerApp2FQDN
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-499'
            ]
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: wafRuleSetVersion
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    enableHttp2: false
    firewallPolicy: {
      id: webApplicationFirewallId
    }
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 3
    }
  }
}


// // Link Application Gateway to Log Analytics
// resource diagnosticSettingsApi 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${applicationGatewayName}${nameSeparator}api${nameSeparator}diag'
//   scope: applicationGatewaysApi
//   properties: {
//     workspaceId: applicationGatewayLogAnalyticsWorkspaceId
//     logs: [
//       {
//         categoryGroup: 'allLogs'
//         enabled: true
//         retentionPolicy: {
//           enabled: false
//           days: 30
//         }
//       }
//     ]
//     metrics: [
//       {
//         category: 'AllMetrics'
//         enabled: false
//         retentionPolicy: {
//           enabled: false
//           days: 30
//         }
//       }
//     ]
//   }
//   dependsOn: [
//     publicIPAddresses
//   ]
// }

output appGatewayName string = applicationGatewaysApi.name
output appGatewayId string = applicationGatewaysApi.id
output applicationGatewayPublicIp string = publicIPAddresses.properties.ipAddress
