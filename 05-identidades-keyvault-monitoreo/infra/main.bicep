param location string = 'brazilsouth'
param operatorObjectId string
param vmPrincipalId string
param alertEmail string
param firstScheduledRun string
param workflowEnabled bool = false

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-lead05-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
    accessPolicies: []
  }
}
resource operatorVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, operatorObjectId, 'kv-admin')
  scope: vault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: operatorObjectId
    principalType: 'User'
  }
}
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stlead05${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: { allowBlobPublicAccess: false, allowSharedKeyAccess: false, minimumTlsVersion: 'TLS1_2', supportsHttpsTrafficOnly: true }
}
resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = { parent: storage, name: 'default' }
resource documents 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = { parent: blobs, name: 'documents', properties: { publicAccess: 'None' } }
resource reports 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = { parent: blobs, name: 'reports', properties: { publicAccess: 'None' } }
resource reader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(documents.id, vmPrincipalId, 'vm-reader')
  scope: documents
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalId: vmPrincipalId
    principalType: 'ServicePrincipal'
  }
}
resource storageOperator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, operatorObjectId, 'operator')
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: operatorObjectId
    principalType: 'User'
  }
}
resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-keyvault-expiry'
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    state: workflowEnabled ? 'Enabled' : 'Disabled'
    definition: loadJsonContent('../logic/workflow.json')
    parameters: {
      vaultUri: { value: vault.properties.vaultUri }
      reportUri: { value: 'https://${storage.name}.blob.${environment().suffixes.storage}/reports/keyvault-expiry/latest.json' }
      metricsUri: { value: 'https://${location}.monitoring.azure.com${vault.id}/metrics' }
      firstScheduledRun: { value: firstScheduledRun }
    }
  }
}
var monitoringRoles = [
  '21090545-7ca7-4776-b22c-e363652d74d2' // Solo metadatos Key Vault.
  '3913510d-42f4-4e42-8a64-420c390055eb' // Publicar métricas en el recurso.
]
resource monitoringPermissions 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleId in monitoringRoles: {
  name: guid(vault.id, workflow.id, roleId)
  scope: vault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',roleId)
    principalId: workflow.identity.principalId
    principalType: 'ServicePrincipal'
  }
}]
resource reportsWriter 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(reports.id, workflow.id, 'reports-writer')
  scope: reports
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: workflow.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
resource email 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-keyvault-expiry'
  location: 'global'
  properties: {
    groupShortName: 'KVExpiry'
    enabled: true
    emailReceivers: [{ name: 'lab-owner', emailAddress: alertEmail, useCommonAlertSchema: true }]
  }
}
resource alerts 'Microsoft.Insights/metricAlerts@2018-03-01' = [for days in [15,30]: {
  name: 'keyvault-expiry-${days}-days'
  location: 'global'
  properties: {
    description: days == 15 ? 'Key Vault: objetos con vencimiento en 0-15 dias. Revisar reports/keyvault-expiry/latest.json.' : 'Key Vault: objetos con vencimiento en 16-30 dias. Revisar reports/keyvault-expiry/latest.json.'
    severity: days == 15 ? 1 : 2
    enabled: true
    scopes: [vault.id]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT15M'
    autoMitigate: true
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [{
        name: 'DueCount'
        metricNamespace: 'LeadUTP.KeyVault'
        metricName: 'Due${days}Days'
        timeAggregation: 'Maximum'
        operator: 'GreaterThan'
        threshold: 0
        criterionType: 'StaticThresholdCriterion'
        skipMetricValidation: true
      }]
    }
    actions: [{ actionGroupId: email.id }]
  }
}]
output vaultName string = vault.name
output storageAccount string = storage.name
output workflowName string = workflow.name
output workflowId string = workflow.id
output vaultId string = vault.id
