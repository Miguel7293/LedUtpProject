param location string = 'brazilsouth'
param adfPrincipalId string
param accountName string = 'stretail57cyqpixoehss'
param vaultName string = 'kv-retail-andes-7293'
resource lakeIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-retail-databricks-lake'
  location: location
}
resource connector 'Microsoft.Databricks/accessConnectors@2023-05-01' = {
  name: 'ac-retail-andes'
  location: location
  identity: { type: 'SystemAssigned, UserAssigned', userAssignedIdentities: { '${lakeIdentity.id}': {} } }
  properties: {}
}
resource account 'Microsoft.Storage/storageAccounts@2023-05-01' existing = { name: accountName }
// UC emite credenciales temporales: la delegación se concede en la cuenta,
// mientras lectura/escritura de datos se limita a Bronze/Silver abajo.
resource delegator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(account.id, lakeIdentity.id, 'blob-delegator')
  scope: account
  properties: {
    principalId: lakeIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','db58b8e5-c6ad-4a2a-8342-4190687cbf4a')
  }
}
resource connectorReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(connector.id, 'self-reader')
  scope: connector
  properties: {
    principalId: connector.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}
resource lakeIdentityReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(lakeIdentity.id, 'self-reader')
  scope: lakeIdentity
  properties: {
    principalId: lakeIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}
resource lakeConnectorReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(connector.id, lakeIdentity.id, 'reader')
  scope: connector
  properties: {
    principalId: lakeIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}
resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = { parent: account, name: 'default' }
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' existing = [for name in ['bronze','silver']: { parent: blobs, name: name }]
resource access 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (name, index) in ['bronze','silver']: {
  name: guid(lakeIdentity.id, containers[index].id, 'data-contributor')
  scope: containers[index]
  properties: {
    principalId: lakeIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  }
}]
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    accessPolicies: []
  }
}
resource policy 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'silver-expected-sales'
  properties: { value: '4' }
}
resource reader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, adfPrincipalId, 'secrets-user')
  scope: vault
  properties: {
    principalId: adfPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','4633458b-17de-408a-b874-0445c86b69e6')
  }
}
output connectorId string = connector.id
output vaultUri string = vault.properties.vaultUri
