param location string = resourceGroup().location
param catalogApiUrl string
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-leadutp02-free'
  location: location
  kind: 'linux'
  sku: { name: 'F1', tier: 'Free' }
  properties: { reserved: true }
}
resource web 'Microsoft.Web/sites@2023-12-01' = {
  name: 'web-leadutp02-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [{ name: 'CatalogApiUrl', value: catalogApiUrl }]
    }
  }
}
output webName string = web.name
output webUrl string = 'https://${web.properties.defaultHostName}'
