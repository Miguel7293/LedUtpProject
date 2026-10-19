targetScope = 'subscription'

param location string = 'brazilsouth'
param resourceGroupLocation string = 'eastus2'
param resourceGroupName string = 'rg-leadutp-01-dev'
param administratorObjectId string
param administratorLogin string
param tenantId string = subscription().tenantId

resource lab 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: {
    project: 'leadutp-01'
    environment: 'dev'
    purpose: 'learning'
  }
}

module sql 'sql.bicep' = {
  name: 'sql-free'
  scope: lab
  params: {
    location: location
    administratorObjectId: administratorObjectId
    administratorLogin: administratorLogin
    tenantId: tenantId
  }
}

output resourceGroup string = lab.name
output serverName string = sql.outputs.serverName
output endpoint string = sql.outputs.endpoint
output databaseName string = sql.outputs.databaseName
