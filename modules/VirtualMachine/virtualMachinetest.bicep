targetScope = 'resourceGroup'

param tags object

//param keyVaultName string
@secure()
param password string
@secure()
//param sshKey object//string


//param adminPasswordOrKey string = vmadminPassword

param vmUserNameValue string    //= '${CAFPrefix}${nameSeparator}vm'
param location string


param CAFPrefix string
param vmSubnetId string
param nameSeparator string

//VM Parameters
param vmSizeSet string = 'Standard_F8s_V2' //'Standard_F8s_V2'
//param privateDnsZoneNameVm string
param virtualMachineName string
//param privateDNSZoneIdVm string = '/subscriptions/${coreSubscriptionId}/resourceGroups/${coreResourceGroupName}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneNameVm}'
param networkInterfaceNmae string = '${virtualMachineName}${nameSeparator}ni'
param computervmName string = '${CAFPrefix}${nameSeparator}Server'
param osDiskType string = 'StandardSSD_LRS' //'Standard_LRS'
//param securityType string = 'Standard'
param sshKeySecretName string = 'Vmkey'
// param sshKeyVaultName string
// param sshKeyVaultResourceGroup string
// param keyVaultId string
param keyVaultName string



resource sshKeySecret 'Microsoft.KeyVault/vaults/keys@2021-06-01-preview' = {
  name: '${keyVaultName}/${sshKeySecretName}'
  properties: {
    kty: 'RSA'
  }
}

param authenticationType string = 'sshKey' //'password'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmUserNameValue}/.ssh/authorized_keys'
        keyData: sshKeySecret
      }
    ]
  }
}

/**
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
*/

param ubuntuOSVersion string = 'Ubuntu-2204'
var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

/**
// Create Private Endpoint
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: '${virtualMachine.name}${nameSeparator}pep'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${virtualMachine.name}${nameSeparator}pep'
        properties: {
          privateLinkServiceId: virtualMachine.id
          groupIds: [
            'virtualMachine'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${virtualMachine.name}${nameSeparator}nic'
    subnet: {
      id: pepSubnetId
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
  dependsOn: [
  ]
}



resource privateEndpoints 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: '${virtualMachine.name}${nameSeparator}pep'
  location: location
  properties: {
    subnet: {
      id: pepSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${virtualMachine.name}${nameSeparator}pep'
        properties: {
          privateLinkServiceId:  virtualMachine.id   //'/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/${vmName}'
          groupIds: [
            'blob'
          ]
    requestMessage: {
            'allowedDNSSuffixes': 'privatelink.azure.com'
          }  
        }
      }
    ]
  }
}


// Private DNS Zone Groups 
resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'privateDNSZoneGroupsVaultCore'
  parent: privateEndpoints
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneNameVm
        properties: {
          privateDnsZoneId: privateDNSZoneIdVm
        }
      }
    ]
  }
  dependsOn: [
  ]
}
 */  

// // Assign VM Server Contributor to Developer Group
// module roles_DeveloperGroupContributor '../security/rolesDeveloperVmContributor.bicep' = {
//   name: 'rolesDeveloperVmContributor'
//   params: {
//     virtualMachineId: virtualMachine.id
//   }
//   dependsOn: [

//   ]
// }

//Network interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: networkInterfaceNmae
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
  ]
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: virtualMachineName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSizeSet
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: computervmName
      adminUsername: vmUserNameValue
      adminPassword: password //vmSecretName//eploymentScript.properties.outputs.password //vmSecretName
    linuxConfiguration: ((authenticationType == 'sshKey') ? null : linuxConfiguration)
    }
    //securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}




//output resourceGroupName string = resourceGroupName


