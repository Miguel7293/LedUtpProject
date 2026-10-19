param location string = 'centralus'
param vmSize string = 'Standard_D2s_v3'
param adminUsername string = 'leadadmin'
@secure()
param adminPassword string
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-leadutp02-win'
  location: location
  properties: {
    securityRules: [{
      name: 'DenyInbound'
      properties: {
        priority: 100
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
      }
    }]
  }
}
resource network 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-leadutp02-win'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.23.0.0/16'] }
    subnets: [{ name: 'windows', properties: { addressPrefix: '10.23.1.0/24' } }]
  }
}
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-leadutp02-win'
  location: location
  properties: {
    networkSecurityGroup: { id: nsg.id }
    ipConfigurations: [{ name: 'private', properties: {
      privateIPAllocationMethod: 'Dynamic'
      subnet: { id: '${network.id}/subnets/windows' }
    } }]
  }
}
resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-leadutp02-win'
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: 'leadutp02win'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: { provisionVMAgent: true, enableAutomaticUpdates: true }
    }
    storageProfile: {
      imageReference: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku: '2022-datacenter-g2', version: 'latest' }
      osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'Standard_LRS' } }
    }
    networkProfile: { networkInterfaces: [{ id: nic.id }] }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
}
output vmId string = vm.id
