targetScope = 'resourceGroup'

param location string
param CAFPrefix string
param nameSeparator string
param publicDNSFQDN string
param certificateName string
@secure()
param coreKeyVaultName string
param wafRuleSetVersion string
param containerApp1FQDN string
param containerApp2FQDN string
param coreSubscriptionId string
param coreResourceGroupName string
param webApplicationFirewallId string
param applicationGatewaySubnetId string
param applicationGatewayUserAssignedIdentityId string
param applicationGatewayLogAnalyticsWorkspaceId string
//param applicationGatewayName string = '${CAFPrefix}${nameSeparator}agw'
param applicationGatewayName2 string = '${CAFPrefix}${nameSeparator}api${nameSeparator}agw'
//param applicationGatewayId string = resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)
param applicationGatewayId2 string = resourceId('Microsoft.Network/applicationGateways', applicationGatewayName2)



// Get Existing Vault
resource vaults 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  scope: resourceGroup(coreSubscriptionId, coreResourceGroupName)
  name: coreKeyVaultName
}

// Create Public IP Address
resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${applicationGatewayName2}${nameSeparator}pip'
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

/**
// Create Public IP Address for API
resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${applicationGatewayName2}${nameSeparator}api${nameSeparator}pip'
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
*/
// Create Application Gateway for API------------------------------------------------------------------------------------------
resource applicationGatewaysApi 'Microsoft.Network/applicationGateways@2019-09-01' = {
  name: '${CAFPrefix}${nameSeparator}api${nameSeparator}agw'
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
        name: 'applicationGatewayIpConfig'
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
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: publicIPAddresses.name
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses.id
          }
        }
      }
/**     {
        name: publicIPAddresses.name
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses.id
          }
        }
      } */ 
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_8080'
        properties: {
          port: 8080
        }
      }
      {
        name: 'port_53'
        properties: {
          port: 53
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'publicBackend2'
        properties: {
          backendAddresses: [
            {
              fqdn: containerApp2FQDN
            }
          ]
        }
      }
      {
        name: 'publicBackend1'
        properties: {
          backendAddresses: [
            {
              fqdn: containerApp1FQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendSettings2'
        properties: {
          port: 8080
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName2, 'publicHealthProbe2')
          }
        }
      }
      {
        name: 'backendSettings1'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName2, 'publicHealthProbe1')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'publicListener2'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId2}/frontendIPConfigurations/${publicIPAddresses.name}'
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName2, 'port_8080')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName2, '${certificateName}')
          }
          hostName: '${publicDNSFQDN}-api.brado.ai'
          requireServerNameIndication: true
        }
      }
      {
        name: 'publicRedirect2'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicRedirect2')
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId2}/frontendIPConfigurations/${publicIPAddresses.name}'
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName2, 'port_53')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'publicListener1'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId2}/frontendIPConfigurations/${publicIPAddresses.name}'
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName2, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName2, '${certificateName}')
          }
          hostName: '${publicDNSFQDN}.brado.ai'
          requireServerNameIndication: true
        }
      }
      {
        name: 'publicRedirect1'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicRedirect1')
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId2}/frontendIPConfigurations/${publicIPAddresses.name}'
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName2, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'publicRedirectRule2'
        properties: {
          ruleType: 'Basic'
          priority: 4
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicRedirect2')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName2, 'publicRedirectRule2')
          }
        }
      }
      {
        name: 'publicRoutingRule2'
        properties: {
          ruleType: 'Basic'
          priority: 5
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicListener2')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName2, 'publicBackend2')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName2, 'backendSettings2')
          }
        }
      }
      {
        name: 'publicRedirectRule1'
        properties: {
          ruleType: 'Basic'
          priority: 6
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicRedirect1')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName2, 'publicRedirectRule1')
          }
        }
      }
      {
        name: 'publicRoutingRule1'
        properties: {
          ruleType: 'Basic'
          priority: 7
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicListener1')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName2, 'publicBackend1')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName2, 'backendSettings1')
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
              '200-399'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: [
      {
        name: 'publicRedirectRule1'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicListener1')
          }
          includePath: false
          includeQueryString: false
        }
      }
      {
        name: 'publicRedirectRule2'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName2, 'publicListener2')
          }
          includePath: false
          includeQueryString: false
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
  dependsOn: []
}

// Link Application Gateway to Log Analytics
resource diagnosticSettingsApi 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${applicationGatewayName2}${nameSeparator}api${nameSeparator}diag'
  scope: applicationGatewaysApi
  properties: {
    workspaceId: applicationGatewayLogAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: false
        retentionPolicy: {
          enabled: false
          days: 30
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddresses
  ]
}

//output applicationGatewayPublicIp string = publicIPAddresses.properties.ipAddress
output applicationGatewayApiPublicIp string = publicIPAddresses.properties.ipAddress
