"""Genera un flujo Logic Apps que solo lee metadatos, no valores de secretos."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def http(uri, audience, method='GET', body=None, headers=None):
    inputs = {'uri': uri, 'method': method, 'authentication': {'type': 'ManagedServiceIdentity', 'audience': audience}}
    if body is not None:
        inputs['body'] = body
    if headers:
        inputs['headers'] = headers
    return {'type': 'Http', 'inputs': inputs}

def after(name):
    return {name: ['Succeeded']}

now_epoch = "div(sub(ticks(utcNow()),ticks('1970-01-01T00:00:00Z')),10000000)"
future_epoch = "div(sub(ticks(addDays(utcNow(),30)),ticks('1970-01-01T00:00:00Z')),10000000)"
condition = f"@and(not(equals(item()?['managed'],true)),not(equals(item()?['attributes']?['exp'],null)),not(equals(item()?['attributes']?['enabled'],false)),lessOrEquals(int(coalesce(item()?['attributes']?['exp'],4102444800)),{future_epoch}))"
list_page = http("@variables('NextUrl')", 'https://vault.azure.net')
collect = {
    'type': 'Foreach', 'foreach': "@body('List_page')?['value']", 'runAfter': after('List_page'),
    'runtimeConfiguration': {'concurrency': {'repetitions': 1}},
    'actions': {'Expiring': {'type': 'If', 'expression': condition,
        'actions': {'Collect': {'type': 'AppendToArrayVariable', 'inputs': {'name': 'Report', 'value': {
            'kind': "@items('Kinds')", 'id': "@coalesce(item()?['id'],item()?['kid'])",
            'expiresAt': "@addSeconds('1970-01-01T00:00:00Z',int(item()['attributes']['exp']))",
            'daysRemaining': f"@div(sub(int(item()['attributes']['exp']),{now_epoch}),86400.0)",
        }}}}, 'else': {'actions': {}}}},
}
pages = {
    'type': 'Until', 'expression': "@empty(variables('NextUrl'))", 'limit': {'count': 100, 'timeout': 'PT10M'},
    'runAfter': after('First_page'),
    'actions': {
        'List_page': list_page,
        'Collect_page': collect,
        'Next_page': {'type': 'SetVariable', 'runAfter': after('Collect_page'), 'inputs': {'name': 'NextUrl', 'value': "@coalesce(body('List_page')?['nextLink'],'')"}},
    },
}
kinds = {
    'type': 'Foreach', 'foreach': ['secrets', 'certificates', 'keys'], 'runAfter': after('Initialize'),
    'runtimeConfiguration': {'concurrency': {'repetitions': 1}},
    'actions': {
        'First_page': {'type': 'SetVariable', 'inputs': {'name': 'NextUrl', 'value': "@concat(parameters('vaultUri'),items('Kinds'),'?api-version=7.4&maxresults=25')"}},
        'Pages': pages,
    },
}

def metric(action_name, metric_name):
    count = f"@length(body('{action_name}'))"
    action = http("@parameters('metricsUri')", 'https://monitoring.azure.com/', 'POST', {
        'time': '@utcNow()', 'data': {'baseData': {
            'metric': metric_name, 'namespace': 'LeadUTP.KeyVault', 'dimNames': [],
            'series': [{'dimValues': [], 'min': count, 'max': count, 'sum': count, 'count': 1}],
        }},
    }, {'Content-Type': 'application/json'})
    action['runAfter'] = after('Save_report')
    return action

save = http("@parameters('reportUri')", 'https://storage.azure.com/', 'PUT', {
    'checkedAt': '@utcNow()', 'runId': "@workflow().run.name", 'items': "@variables('Report')",
    'due15': "@length(body('Due15'))", 'due30': "@length(body('Due30'))",
}, {'x-ms-version': '2023-11-03', 'x-ms-blob-type': 'BlockBlob', 'Content-Type': 'application/json'})
save['runAfter'] = after('Due30')
definition = {
    '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#',
    'contentVersion': '1.0.0.0',
    'parameters': {name: {'type': 'String'} for name in ['vaultUri','reportUri','metricsUri','firstScheduledRun']},
    'triggers': {'Daily': {'type': 'Recurrence', 'recurrence': {
        'frequency': 'Day', 'interval': 1, 'timeZone': 'SA Pacific Standard Time',
        'startTime': "@parameters('firstScheduledRun')", 'schedule': {'hours': [8], 'minutes': [0]},
    }}},
    'actions': {
        'Initialize': {'type': 'InitializeVariable', 'inputs': {'variables': [
            {'name': 'NextUrl', 'type': 'string', 'value': ''}, {'name': 'Report', 'type': 'array', 'value': []},
        ]}},
        'Kinds': kinds,
        'Due15': {'type': 'Query', 'runAfter': after('Kinds'), 'inputs': {'from': "@variables('Report')", 'where': "@lessOrEquals(item()['daysRemaining'],15)"}},
        'Due30': {'type': 'Query', 'runAfter': after('Due15'), 'inputs': {'from': "@variables('Report')", 'where': "@and(greater(item()['daysRemaining'],15),lessOrEquals(item()['daysRemaining'],30))"}},
        'Save_report': save,
        'Publish15': metric('Due15', 'Due15Days'),
        'Publish30': metric('Due30', 'Due30Days'),
    },
    'outputs': {'summary': {'type': 'Object', 'value': {'due15': "@length(body('Due15'))", 'due30': "@length(body('Due30'))"}}},
}
destination = ROOT / 'logic' / 'workflow.json'
destination.parent.mkdir(exist_ok=True)
destination.write_text(json.dumps(definition, indent=2) + '\n', encoding='utf-8')
print('Definición Logic Apps generada.')
