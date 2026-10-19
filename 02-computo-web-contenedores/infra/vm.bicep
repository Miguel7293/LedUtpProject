// Laboratorio opcional de cómputo: genera costos incluso si nadie se conecta.
param location string = resourceGroup().location
param sshPublicKey string
param vmSize string = 'Standard_B1s'
param adminUsername string = 'azureuser'
resource network 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-leadutp02'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.22.0.0/16'] }
    subnets: [{ name: 'compute', properties: { addressPrefix: '10.22.1.0/24' } }]
  }
}
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-leadutp02'
  location: location
  properties: { securityRules: [] }
}
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-leadutp02'
  location: location
  properties: {
    networkSecurityGroup: { id: nsg.id }
    ipConfigurations: [{
      name: 'private'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: { id: '${network.id}/subnets/compute' }
      }
    }]
  }
}
resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-leadutp02'
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: 'leadutp02'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: { publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey }] }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'Standard_LRS' } }
    }
    networkProfile: { networkInterfaces: [{ id: nic.id }] }
  }
}
