@secure()
param mariaSecretName string
param vmSecretName string
param keyVaultName string
param location string

// Generate Password - this will create a Deployment Script artifact, the pipeline YML will delete it
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deploymentScript'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '3.0'
    retentionInterval: 'P1D' // PT1M
    scriptContent: loadTextContent('../../scripts/azure-password.ps1')
  }
}

// Existing Key Vault
resource vaults 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

// Create Mariadb Admin Password
resource secretsMariaPassword 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: vaults
  name: mariaSecretName
  properties: {
    value: deploymentScript.properties.outputs.password
  }
}


// Create Virtual Machine Admin Password
resource secretsVMPassword 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: vaults
  name: vmSecretName
  properties: {
    value: deploymentScript.properties.outputs.password
  }
}
