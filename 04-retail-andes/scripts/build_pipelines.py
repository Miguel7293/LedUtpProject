"""Genera propiedades ADF deterministas; no conecta a Azure."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'adf'
ROOT.mkdir(exist_ok=True)

def expression(value):
    return {'value': value, 'type': 'Expression'}

def dataset(name, **parameters):
    return {'referenceName': name, 'type': 'DatasetReference', 'parameters': parameters}

def depends(name):
    return [{'activity': name, 'dependencyConditions': ['Succeeded']}]

policy = {'timeout': '0.00:15:00', 'retry': 2, 'retryIntervalInSeconds': 30}
sql_params = lambda: {
    'SchemaName': {'type': 'String', 'value': expression('@pipeline().parameters.schemaName')},
    'TableName': {'type': 'String', 'value': expression('@pipeline().parameters.tableName')},
}

copy_query = """@if(equals(activity('Bounds').output.firstRow.LoadType,'Full'),concat('SELECT * FROM [',pipeline().parameters.schemaName,'].[',pipeline().parameters.tableName,']'),concat('SELECT * FROM [',pipeline().parameters.schemaName,'].[',pipeline().parameters.tableName,'] WHERE [',activity('Bounds').output.firstRow.WatermarkColumn,'] > CONVERT(datetime2(7),''',activity('Bounds').output.firstRow.LowerWatermark,''',126) AND [',activity('Bounds').output.firstRow.WatermarkColumn,'] <= CONVERT(datetime2(7),''',activity('Bounds').output.firstRow.UpperWatermark,''',126)'))"""
commit_params = sql_params()
commit_params.update({
    'RunId': {'type': 'String', 'value': expression('@pipeline().parameters.runId')},
    'LowerWatermark': {'type': 'String', 'value': expression("@activity('Bounds').output.firstRow.LowerWatermark")},
    'UpperWatermark': {'type': 'String', 'value': expression("@activity('Bounds').output.firstRow.UpperWatermark")},
    'RowsCopied': {'type': 'Int64', 'value': expression("@activity('Copy').output.rowsCopied")},
})
child = {
    'concurrency': 1,
    'parameters': {name: {'type': 'String'} for name in ['schemaName', 'tableName', 'runId']},
    'activities': [
        {'name': 'Bounds', 'type': 'Lookup', 'policy': policy, 'typeProperties': {
            'firstRowOnly': True,
            'dataset': dataset('DS_Sql'),
            'source': {'type': 'AzureSqlSource', 'sqlReaderStoredProcedureName': '[etl].[GetBounds]', 'storedProcedureParameters': sql_params()},
        }},
        {'name': 'Copy', 'type': 'Copy', 'dependsOn': depends('Bounds'), 'policy': policy,
         'inputs': [dataset('DS_Sql', schemaName=expression('@pipeline().parameters.schemaName'), tableName=expression('@pipeline().parameters.tableName'))],
         'outputs': [dataset('DS_Bronze', folderPath=expression("@concat(pipeline().parameters.schemaName,'/',pipeline().parameters.tableName,'/run_id=',pipeline().parameters.runId)"))],
         'typeProperties': {
             'source': {'type': 'AzureSqlSource', 'sqlReaderQuery': expression(copy_query), 'queryTimeout': '00:10:00'},
             'sink': {'type': 'ParquetSink', 'storeSettings': {'type': 'AzureBlobFSWriteSettings'}, 'formatSettings': {'type': 'ParquetWriteSettings'}},
             'enableStaging': False,
             'dataIntegrationUnits': 4,
         }},
        {'name': 'Commit', 'type': 'SqlServerStoredProcedure', 'dependsOn': depends('Copy'), 'policy': policy,
         'linkedServiceName': {'referenceName': 'LS_Sql', 'type': 'LinkedServiceReference'},
         'typeProperties': {'storedProcedureName': '[etl].[CommitLoad]', 'storedProcedureParameters': commit_params}},
    ],
}
master = {
    'concurrency': 1,
    'parameters': {'onlyTable': {'type': 'String', 'defaultValue': ''}},
    'activities': [
        {'name': 'Metadata', 'type': 'Lookup', 'policy': policy, 'typeProperties': {
            'dataset': dataset('DS_Sql'), 'firstRowOnly': False,
            'source': {'type': 'AzureSqlSource', 'sqlReaderStoredProcedureName': '[etl].[ListLoads]', 'storedProcedureParameters': {'OnlyTable': {'type': 'String', 'value': expression('@pipeline().parameters.onlyTable')}}},
        }},
        {'name': 'Tables', 'type': 'ForEach', 'dependsOn': depends('Metadata'), 'typeProperties': {
            'items': expression("@activity('Metadata').output.value"), 'isSequential': True,
            'activities': [{'name': 'Load', 'type': 'ExecutePipeline', 'typeProperties': {
                'pipeline': {'referenceName': 'LoadTable', 'type': 'PipelineReference'}, 'waitOnCompletion': True,
                'parameters': {'schemaName': expression('@item().SchemaName'), 'tableName': expression('@item().TableName'), 'runId': expression('@pipeline().RunId')},
            }}],
        }},
    ],
}
for name, properties in [('master', master), ('load-table', child)]:
    (ROOT / f'{name}.json').write_text(json.dumps(properties, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print('Generadas propiedades ADF: RetailAndes y LoadTable')
