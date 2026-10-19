param location string = resourceGroup().location
param prefix string

module workspace 'br/public:avm/res/operational-insights/workspace:0.11.1' = {
  name: 'workspace-avm'
  params: {
    name: 'log-${prefix}'
    location: location
    skuName: 'PerGB2018'
    dataRetention: 30
    dailyQuotaGb: 1
    enableTelemetry: false
    forceCmkForQuery: false
    // La integración Log Analytics del entorno Express requiere autenticación por clave.
    features: { disableLocalAuth: false }
  }
}
resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${prefix}'
  location: location
  kind: 'web'
  properties: { Application_Type: 'web', WorkspaceResourceId: workspace.outputs.resourceId }
}
output workspaceId string = workspace.outputs.resourceId
output customerId string = workspace.outputs.logAnalyticsWorkspaceId
output insightsId string = insights.id


output workspaceName string = workspace.outputs.name
