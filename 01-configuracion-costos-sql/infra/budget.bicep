// Desplegar a nivel del grupo de recursos, solo cuando se configure un destinatario.
@minValue(1)
param monthlyAmount int = 10
param contactEmail string
param startDate string

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-leadutp-01'
  properties: {
    category: 'Cost'
    amount: monthlyAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
      }
      actual100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
      }
    }
  }
}
