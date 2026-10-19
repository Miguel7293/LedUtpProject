param location string = 'brazilsouth'
param workspaceName string = 'dbw-retail-andes'
resource workspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  sku: { name: 'premium' }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', 'rg-retail-databricks-managed')
    publicNetworkAccess: 'Enabled'
    parameters: { enableNoPublicIp: { value: true } }
  }
}
output workspaceId string = workspace.id
output workspaceUrl string = workspace.properties.workspaceUrl
