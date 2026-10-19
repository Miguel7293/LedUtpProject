param location string = resourceGroup().location
param prefix string = 'lead06'
param registryName string = 'acrleadutpjmas5j6rizpu4'
param registryGroup string = 'rg-leadutp-02-dev'
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
        image: '${registryName}.azurecr.io/leadutp02-api:v1'
        env: [{ name: 'APP_ENV', value: 'azure-bicep-06' }, { name: 'KEY_VAULT_URI', value: security.outputs.vaultUri }]
        resources: { cpu: json('0.25'), memory: '0.5Gi' }
        probes: [{ type: 'Readiness', httpGet: { path: '/health', port: 8000 }, initialDelaySeconds: 5, periodSeconds: 10 }]
      }]
      scale: { minReplicas: 0, maxReplicas: 1 }
    }
  }
  dependsOn: [pull]
}
output apiUrl string = 'https://${api.properties.configuration.ingress.fqdn}'
output workspaceId string = monitoring.outputs.workspaceId
output insightsId string = monitoring.outputs.insightsId
output vaultUri string = security.outputs.vaultUri
