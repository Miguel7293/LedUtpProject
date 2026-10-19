param location string = 'brazilsouth'
param image string
param alertEmail string
param budgetStart string = utcNow('yyyy-MM-01T00:00:00Z')

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'sthero07${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: { allowBlobPublicAccess: false, allowSharedKeyAccess: false, minimumTlsVersion: 'TLS1_2', supportsHttpsTrafficOnly: true }
}
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = { parent: storage, name: 'default' }
var stages = ['staging', 'production']
resource tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = [for stage in stages: { parent: tableService, name: 'votes${stage}' }]
resource identities 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = [for stage in stages: { name: 'id-hero07-${stage}', location: location }]
resource writers 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (stage, i) in stages: {
  name: guid(tables[i].id, identities[i].id, 'table-voter')
  scope: tables[i]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
    principalId: identities[i].properties.principalId
    principalType: 'ServicePrincipal'
  }
}]
module pulls 'registry-access.bicep' = [for (stage, i) in stages: {
  name: 'hero07-pull-${stage}'
  scope: resourceGroup('rg-leadutp-02-dev')
  params: { principalId: identities[i].properties.principalId }
}]
resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-hero07'
  location: location
  properties: {}
}
resource apps 'Microsoft.App/containerApps@2024-03-01' = [for (stage, i) in stages: {
  name: 'ca-hero07-${stage}'
  location: location
  identity: { type: 'UserAssigned', userAssignedIdentities: { '${identities[i].id}': {} } }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: { external: true, targetPort: 3000, allowInsecure: false }
      registries: [{ server: 'acrleadutpjmas5j6rizpu4.azurecr.io', identity: identities[i].id }]
    }
    template: {
      containers: [{
        name: 'web'
        image: image
        env: [
          { name: 'APP_ENV', value: stage }
          { name: 'TABLE_ACCOUNT', value: storage.name }
          { name: 'TABLE_NAME', value: 'votes${stage}' }
          { name: 'AZURE_CLIENT_ID', value: identities[i].properties.clientId }
        ]
        resources: { cpu: json('0.25'), memory: '0.5Gi' }
        probes: [{ type: 'Readiness', httpGet: { path: '/health', port: 3000 }, initialDelaySeconds: 10, periodSeconds: 30, failureThreshold: 6 }]
      }]
      scale: { minReplicas: 0, maxReplicas: 1 }
    }
  }
  dependsOn: [writers, pulls]
}]
output environments array = [for (stage, i) in stages: { name: stage, appName: apps[i].name, url: 'https://${apps[i].properties.configuration.ingress.fqdn}' }]
output storageName string = storage.name
module budget 'budget.bicep' = {
  name: 'budget-07'
  params: { contactEmail: alertEmail, startDate: budgetStart, monthlyAmount: 10 }
}
