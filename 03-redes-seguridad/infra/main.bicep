param location string = 'centralus'
param sshPublicKey string
param adminIPv4 string
param adminUsername string = 'azureuser'
param vmSize string = 'Standard_B2pts_v2'
param imageSku string = 'server-arm64'
param createNetworkWatcher bool = true

var vmNames = ['VM01', 'VM02']
var subnetNames = ['frontend', 'backend']
var privateAddresses = ['10.30.1.4', '10.30.2.4']

resource watcher 'Microsoft.Network/networkWatchers@2024-05-01' = if (createNetworkWatcher) {
  name: 'nw-leadutp03'
  location: location
  properties: {}
}

resource nsgs 'Microsoft.Network/networkSecurityGroups@2024-05-01' = [for i in range(0, 2): {
  name: 'nsg-leadutp03-${i + 1}'
  location: location
  properties: {
    securityRules: concat(i == 0 ? [
      {
        name: 'AllowAdminSSH'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '${adminIPv4}/32'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowAdminWeb'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['80', '443']
          sourceAddressPrefix: '${adminIPv4}/32'
          destinationAddressPrefix: '*'
        }
      }
    ] : [
      {
        name: 'AllowFrontendWeb'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['80', '443']
          sourceAddressPrefix: privateAddresses[0]
          destinationAddressPrefix: '*'
        }
      }
    ], [
      {
        name: 'DenyOtherVnetInbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyRdpInternetOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ])
  }
}]

resource network 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'VNet01'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.30.0.0/16'] }
    subnets: [for i in range(0, 2): {
      name: subnetNames[i]
      properties: {
        addressPrefix: '10.30.${i + 1}.0/24'
        networkSecurityGroup: { id: nsgs[i].id }
        defaultOutboundAccess: false
      }
    }]
  }
}
// Una IP pública por VM proporciona salida explícita sin NAT Gateway.
// Los NSG limitan la entrada; VM02 no acepta tráfico público entrante.
resource publicIps 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for i in range(0, 2): {
  name: 'pip-leadutp03-${i + 1}'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}]
resource interfaces 'Microsoft.Network/networkInterfaces@2024-05-01' = [for i in range(0, 2): {
  name: 'nic-leadutp03-${i + 1}'
  location: location
  properties: {
    ipConfigurations: [{
      name: 'primary'
      properties: {
        privateIPAllocationMethod: 'Static'
        privateIPAddress: privateAddresses[i]
        subnet: { id: '${network.id}/subnets/${subnetNames[i]}' }
        publicIPAddress: { id: publicIps[i].id }
      }
    }]
  }
}]
resource machines 'Microsoft.Compute/virtualMachines@2024-07-01' = [for i in range(0, 2): {
  name: vmNames[i]
  location: location
  tags: { project: 'leadutp-03', environment: 'lab' }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: toLower(vmNames[i])
      adminUsername: adminUsername
      customData: base64(loadTextContent('cloud-init.yaml'))
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: { publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey }] }
      }
    }
    storageProfile: {
      imageReference: { publisher: 'Canonical', offer: 'ubuntu-24_04-lts', sku: imageSku, version: 'latest' }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: { storageAccountType: 'Standard_LRS' }
      }
    }
    networkProfile: { networkInterfaces: [{ id: interfaces[i].id }] }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
}]
output privateIps array = privateAddresses
output publicAddresses array = [for i in range(0, 2): publicIps[i].properties.ipAddress]
output resourceGroup string = resourceGroup().name
