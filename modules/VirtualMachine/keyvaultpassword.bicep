targetScope = 'resourceGroup'
param location string
param keyVaultName string
param vmSecretName string 

// Existing Key Vault
resource vaults 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}


// Create Virtual Machine Admin Password
resource secretsVMPassword 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: vaults
  name: vmSecretName
  properties: {
    value: deploymentScript.properties.outputs.password //vmSecretName
  }
}



// Generate Password - this will create a Deployment Script artifact, the pipeline YML will delete it
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deploymentScript'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '11.0'
    retentionInterval: 'P1D' // PT1M
    scriptContent: loadTextContent('./passwordgenerator.ps1')
  }
}



output value string =  deploymentScript.properties.outputs.password
