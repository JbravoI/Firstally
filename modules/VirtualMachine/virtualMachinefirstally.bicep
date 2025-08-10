//targetScope = 'resourceGroup'

param tags object

//param keyVaultName string
@secure()
param vmSecretName string 
param vmUserNameValue string


param location string

param CAFPrefix string
param vmSubnetId string
param nameSeparator string

//VM Parameters
param vmSizeSet string = 'Standard_B1ms' 
param virtualMachineName string = '${CAFPrefix}${nameSeparator}vm'
param networkInterfaceNmae string = '${virtualMachineName}${nameSeparator}ni'
param computervmName string = '${CAFPrefix}${nameSeparator}Server'
param osDiskType string = 'Standard_LRS'

param osVersion string = 'Windows-2022'
var imageReference = {
  'Windows-2022': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-g2'
    version: 'latest'
  }
}

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

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
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
      imageReference: imageReference[osVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: take(virtualMachineName, 15)
      adminUsername: vmUserNameValue
      adminPassword: vmSecretName
    }
  }
}
