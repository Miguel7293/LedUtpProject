param location string = resourceGroup().location
param prefix string = 'lead06'
param registryName string = 'acrleadutpjmas5j6rizpu4'
param registryGroup string = 'rg-leadutp-02-dev'
param apiImage string = '${registryName}.azurecr.io/leadutp06-api@sha256:09e04ef06c4e0a306b839234a84b7942adcff46f27b8e7744f7c82be775d1e7b'
module monitoring 'br:acrleadutpjmas5j6rizpu4.azurecr.io/bicep/leadutp/observability:1.0.2' = {
  name: 'monitoring'
  params: { location: location, prefix: prefix }
}
module security 'br:acrleadutpjmas5j6rizpu4.azurecr.io/bicep/leadutp/security:1.0.0' = {
  name: 'security'
  params: { location: location, prefix: prefix }
}
module pull 'registry-access.bicep' = {
  name: 'registry-access-06'
  scope: resourceGroup(registryGroup)
  params: { registryName: registryName, principalId: security.outputs.principalId }
}
resource logs 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = { name: 'log-${prefix}' }
resource insights 'Microsoft.Insights/components@2020-02-02' existing = { name: 'appi-${prefix}' }
resource apiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = { name: 'id-${prefix}' }
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = { name: 'kv-${prefix}-${uniqueString(resourceGroup().id)}' }
// Valor sintético: demuestra lectura de configuración sin exponer credenciales reales.
resource label 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'catalog-label'
  properties: { value: 'Catalogo educativo LEAD UTP' }
  dependsOn: [security]
}
resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-${prefix}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: monitoring.outputs.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
  }
}
resource api 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${prefix}-api'
  location: location
  identity: { type: 'UserAssigned', userAssignedIdentities: { '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', 'id-${prefix}')}': {} } }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: { external: true, targetPort: 8000, allowInsecure: false }
      registries: [{ server: '${registryName}.azurecr.io', identity: security.outputs.identityId }]
    }
    template: {
      containers: [{
        name: 'catalog'
        image: apiImage
        env: [
          { name: 'APP_ENV', value: 'azure-bicep-06' }
          { name: 'KEY_VAULT_URI', value: security.outputs.vaultUri }
          { name: 'AZURE_CLIENT_ID', value: apiIdentity.properties.clientId }
          { name: 'OTEL_SERVICE_NAME', value: 'leadutp06-catalog' }
          { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: insights.properties.ConnectionString }
        ]
        resources: { cpu: json('0.25'), memory: '0.5Gi' }
        probes: [{ type: 'Readiness', httpGet: { path: '/health', port: 8000 }, initialDelaySeconds: 5, periodSeconds: 10 }]
      }]
      scale: { minReplicas: 0, maxReplicas: 1 }
    }
  }
  dependsOn: [pull, label]
}
output apiUrl string = 'https://${api.properties.configuration.ingress.fqdn}'
output workspaceId string = monitoring.outputs.workspaceId
output insightsId string = monitoring.outputs.insightsId
output vaultUri string = security.outputs.vaultUri
