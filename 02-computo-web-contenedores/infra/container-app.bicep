param location string = resourceGroup().location
param registryServer string
param identityId string
param imageTag string = 'v1'

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-leadutp02'
  location: location
  properties: {}
}
resource api 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-leadutp02-api'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${identityId}': {} }
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        allowInsecure: false
      }
      registries: [{ server: registryServer, identity: identityId }]
    }
    template: {
      containers: [{
        name: 'catalog'
        image: '${registryServer}/leadutp02-api:${imageTag}'
        env: [{ name: 'APP_ENV', value: 'azure' }]
        resources: { cpu: json('0.25'), memory: '0.5Gi' }
        probes: [{
          type: 'Readiness'
          httpGet: { path: '/health', port: 8000 }
          initialDelaySeconds: 5
          periodSeconds: 10
        }]
      }]
      scale: {
        minReplicas: 0
        maxReplicas: 2
        rules: [{
          name: 'http'
          http: { metadata: { concurrentRequests: '20' } }
        }]
      }
    }
  }
}
output apiUrl string = 'https://${api.properties.configuration.ingress.fqdn}'
