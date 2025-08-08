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
param applicationGatewayName string = '${CAFPrefix}${nameSeparator}agw'
param applicationGatewayId string = resourceId('Microsoft.Network/applicationGateways', applicationGatewayName)

// Get Existing Vault
resource vaults 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  scope: resourceGroup(coreSubscriptionId, coreResourceGroupName)
  name: coreKeyVaultName
}

// Create Public IP Address
resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${applicationGatewayName}${nameSeparator}pip'
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

// Create Application Gateway
resource applicationGateways 'Microsoft.Network/applicationGateways@2019-09-01' = {
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
    ]
    backendAddressPools: [
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
    ]
    backendHttpSettingsCollection: [
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
        name: 'publicListener1'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId}/frontendIPConfigurations/${publicIPAddresses.name}'
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, '${certificateName}')
          }
          hostName: '${publicDNSFQDN}.brado.ai'
          requireServerNameIndication: true
        }
      }
      {
        name: 'publicListener2'
        properties: {
          frontendIPConfiguration: {
            id:  '${applicationGatewayId}/frontendIPConfigurations/${publicIPAddresses.name}' //resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGwPublicFrontendIp')  //appGateway.frontendIPConfigurations[1].id
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, '${certificateName}')
          }
          hostName: '${publicDNSFQDN}-chatapi.brado.ai'
        }
      }
      {
        name: 'publicRedirect'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'publicRedirect')
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayId}/frontendIPConfigurations/${publicIPAddresses.name}'
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'publicRedirectRule'
        properties: {
          ruleType: 'Basic'
          priority: 4
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'publicRedirect')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, 'publicRedirectRule')
          }
        }
      }
      {
        name: 'publicRoutingRule1'
        properties: {
          ruleType: 'Basic'
          priority: 5
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'publicListener1')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'publicBackend1')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'backendSettings1')
          }
        }
      }
      {
        name: 'publicRoutingRule2'
        properties: {
          ruleType: 'Basic'
          priority: 40
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'publicListener2')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'publicBackend2') 
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'httpSettings2')
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
    rewriteRuleSets: []
    redirectConfigurations: [
      {
        name: 'publicRedirectRule'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'publicListener1')
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
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${applicationGatewayName}${nameSeparator}diag'
  scope: applicationGateways
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


output applicationGatewayPublicIp string = publicIPAddresses.properties.ipAddress
