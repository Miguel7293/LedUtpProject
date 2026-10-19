resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = { name: 'kv-lead05-fnihwkcijj322' }
resource group 'Microsoft.Insights/actionGroups@2023-01-01' existing = { name: 'ag-keyvault-expiry' }
resource check 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'keyvault-delivery-check'
  location: 'global'
  properties: {
    description: 'Prueba de entrega LEAD UTP con auditoría real. Retirar después de comprobar.'
    severity: 3
    enabled: true
    scopes: [vault.id]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    autoMitigate: true
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [{ name: 'ActualDueItems', metricNamespace: 'LeadUTP.KeyVault', metricName: 'Due15Days', timeAggregation: 'Maximum', operator: 'GreaterThan', threshold: 0, criterionType: 'StaticThresholdCriterion', skipMetricValidation: true }]
    }
    actions: [{ actionGroupId: group.id }]
  }
}
