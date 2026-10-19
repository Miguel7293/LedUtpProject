param location string = 'brazilsouth'
param operatorObjectId string
param sqlServerName string = 'sql-leadutp-epf457eti6toe'
param sqlDatabase string = 'sqldb-leadutp'

resource lake 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stretail${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    isHnsEnabled: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
  }
}
resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: lake
  name: 'default'
}
resource bronze 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobs
  name: 'bronze'
  properties: { publicAccess: 'None' }
}
resource silver 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobs
  name: 'silver'
  properties: { publicAccess: 'None' }
}
resource factory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: 'adf-retail-${uniqueString(resourceGroup().id)}'
  location: location
  identity: { type: 'SystemAssigned' }
  properties: { publicNetworkAccess: 'Enabled' }
}
resource writer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(bronze.id, factory.id, 'blob-writer')
  scope: bronze
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: factory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
resource operator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(lake.id, operatorObjectId, 'operator')
  scope: lake
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: operatorObjectId
    principalType: 'User'
  }
}
resource sql 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: factory
  name: 'LS_Sql'
  properties: {
    type: 'AzureSqlDatabase'
    typeProperties: {
      server: '${sqlServerName}${environment().suffixes.sqlServerHostname}'
      database: sqlDatabase
      authenticationType: 'SystemAssignedManagedIdentity'
      encrypt: 'mandatory'
      trustServerCertificate: false
      pooling: false
    }
  }
}
resource storage 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: factory
  name: 'LS_Lake'
  properties: {
    type: 'AzureBlobFS'
    typeProperties: { url: 'https://${lake.name}.dfs.${environment().suffixes.storage}' }
  }
}
resource source 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: factory
  name: 'DS_Sql'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: { referenceName: sql.name, type: 'LinkedServiceReference' }
    parameters: {
      schemaName: { type: 'String', defaultValue: 'etl' }
      tableName: { type: 'String', defaultValue: 'LoadConfig' }
    }
    typeProperties: {
      schema: { value: '@dataset().schemaName', type: 'Expression' }
      table: { value: '@dataset().tableName', type: 'Expression' }
    }
    schema: []
  }
}
resource target 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: factory
  name: 'DS_Bronze'
  properties: {
    type: 'Parquet'
    linkedServiceName: { referenceName: storage.name, type: 'LinkedServiceReference' }
    parameters: { folderPath: { type: 'String' } }
    typeProperties: {
      compressionCodec: 'snappy'
      location: {
        type: 'AzureBlobFSLocation'
        fileSystem: 'bronze'
        folderPath: { value: '@dataset().folderPath', type: 'Expression' }
        fileName: 'data.parquet'
      }
    }
    schema: []
  }
}
resource loadTable 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: factory
  name: 'LoadTable'
  properties: loadJsonContent('../adf/load-table.json')
  dependsOn: [source, target]
}
resource master 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: factory
  name: 'RetailAndes'
  properties: loadJsonContent('../adf/master.json')
  dependsOn: [loadTable]
}
output factoryName string = factory.name
output principalId string = factory.identity.principalId
output storageAccount string = lake.name
output pipelineName string = master.name
