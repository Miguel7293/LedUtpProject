targetScope = 'subscription'
param location string = 'brazilsouth'
param groupName string = 'rg-leadutp-06-dev'
param alertEmail string
param budgetStart string = utcNow('yyyy-MM-01T00:00:00Z')
resource group 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: groupName
  location: location
  tags: { project: 'leadutp-06', environment: 'dev' }
}
module platform 'platform.bicep' = {
  name: 'platform-06'
  scope: group
  params: { location: location }
}
output apiUrl string = platform.outputs.apiUrl
output workspaceId string = platform.outputs.workspaceId
output insightsId string = platform.outputs.insightsId
output vaultUri string = platform.outputs.vaultUri
module budget 'budget.bicep' = {
  name: 'budget-06'
  scope: group
  params: { contactEmail: alertEmail, startDate: budgetStart, monthlyAmount: 10 }
}
