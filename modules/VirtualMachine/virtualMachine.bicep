//targetScope = 'resourceGroup'

param tags object

//param keyVaultName string
@secure()
param vmSecretName string 

param vmUserNameValue string = '${CAFPrefix}${nameSeparator}vm'


param location string

param CAFPrefix string
param vmSubnetId string
param nameSeparator string

//VM Parameters
param vmSizeSet string = 'Standard_NV8as_v4' 
param virtualMachineName string = '${CAFPrefix}${nameSeparator}vm'
param networkInterfaceNmae string = '${virtualMachineName}${nameSeparator}ni'
param computervmName string = '${CAFPrefix}${nameSeparator}Server'
param osDiskType string = 'Standard_LRS'

param ubuntuOSVersion string = 'Ubuntu-2204'
var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
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
      adminPassword: vmSecretName
    }
  }
}
