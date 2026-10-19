param location string
param administratorObjectId string
param administratorLogin string
param tenantId string

resource server 'Microsoft.Sql/servers@2023-08-01' = {
  name: 'sql-leadutp-${uniqueString(resourceGroup().id, location)}'
  location: location
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: administratorLogin
      sid: administratorObjectId
      tenantId: tenantId
      azureADOnlyAuthentication: true
    }
  }
}

// Sin reglas de firewall: el acceso público queda bloqueado hasta autorizar una IP.
resource database 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: server
  name: 'sqldb-leadutp'
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 2
  }
  properties: {
    sampleName: 'AdventureWorksLT'
    maxSizeBytes: 34359738368
    minCapacity: json('0.5')
    autoPauseDelay: 60
    useFreeLimit: true
    freeLimitExhaustionBehavior: 'AutoPause'
    requestedBackupStorageRedundancy: 'Local'
  }
}

output serverName string = server.name
output endpoint string = server.properties.fullyQualifiedDomainName
output databaseName string = database.name
