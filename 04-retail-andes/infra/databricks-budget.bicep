targetScope = 'subscription'
param contactEmail string
param startDate string
param monthlyAmount int = 10
resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-retail-andes-total'
  properties: {
    category: 'Cost'
    amount: monthlyAmount
    timeGrain: 'Monthly'
    timePeriod: { startDate: startDate }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: ['rg-leadutp-04-dev', 'rg-retail-databricks-managed']
      }
    }
    notifications: {
      actual80: { enabled: true, operator: 'GreaterThanOrEqualTo', threshold: 80, thresholdType: 'Actual', contactEmails: [contactEmail] }
      actual100: { enabled: true, operator: 'GreaterThanOrEqualTo', threshold: 100, thresholdType: 'Actual', contactEmails: [contactEmail] }
    }
  }
}
