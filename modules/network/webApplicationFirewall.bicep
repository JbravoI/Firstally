
param wafPolicyName string = '${CAFPrefix}${nameSeparator}waf'
param wafRuleSetVersion string
param nameSeparator string
param CAFPrefix string
param location string

// Create WAF policy
resource wafpolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2022-09-01' = {
  name: wafPolicyName
  location: location
  properties: {
    customRules: [
      {
        name: 'DenyNonUSVisitors'
        priority: 1
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            negationConditon: true
            matchValues: [
              'US'
            ]
            transforms: []
          }
        ]
        state: 'Enabled'
      }
    ]
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Detection'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: wafRuleSetVersion
          ruleGroupOverrides: []
        }
      ]
      exclusions: []
    }
  }
}

output webApplicationFirewallId string = wafpolicy.id
