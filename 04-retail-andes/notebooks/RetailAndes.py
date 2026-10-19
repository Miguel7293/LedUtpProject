# Databricks notebook source
# Importar como notebook Python en un workspace con acceso autorizado a ADLS.
# No contiene claves; el acceso debe configurarse con Unity Catalog / external location.
dbutils.widgets.text('storage_account', '')
dbutils.widgets.text('committed_run_ids', '')
dbutils.widgets.text('expected_sales', '4')

# COMMAND ----------
import re
import uuid
from pyspark.sql import Window, functions as F

account = dbutils.widgets.get('storage_account')
if not re.fullmatch(r'[a-z0-9]{3,24}', account):
    raise ValueError('Indicar una cuenta de Storage válida.')
run_ids = [str(uuid.UUID(value.strip())) for value in dbutils.widgets.get('committed_run_ids').split(',') if value.strip()]
if not run_ids:
    raise ValueError('Indicar solo run IDs confirmados en etl.LoadHistory.')
paths = [f'abfss://bronze@{account}.dfs.core.windows.net/retail/Sales/run_id={run_id}' for run_id in run_ids]
raw = spark.read.parquet(*paths)
latest = raw.withColumn('_rank', F.row_number().over(Window.partitionBy('SaleId').orderBy(F.col('UpdatedAt').desc()))).filter('_rank = 1').drop('_rank')
if latest.filter('SaleId IS NULL OR Quantity <= 0 OR UnitPrice < 0 OR UpdatedAt IS NULL').count():
    raise ValueError('Se encontraron ventas no válidas.')
silver = latest.withColumn('GrossAmount', (F.col('Quantity') * F.col('UnitPrice')).cast('decimal(18,2)'))

# COMMAND ----------
destination = f'abfss://silver@{account}.dfs.core.windows.net/SalesDelta/run_id={run_ids[-1]}'
silver.write.format('delta').mode('overwrite').save(destination)
display(silver.orderBy('SaleId'))
display(silver.agg(F.count('*').alias('Sales'), F.sum('GrossAmount').alias('GrossAmountPEN')))

# COMMAND ----------
import json
check = spark.read.format('delta').load(destination).agg(F.count('*').alias('rows'), F.sum('GrossAmount').alias('amount')).first()
if check['rows'] != int(dbutils.widgets.get('expected_sales')) or str(check['amount']) != '472.20':
    raise ValueError('La lectura Delta no coincide con la demostración confirmada.')
dbutils.notebook.exit(json.dumps({'status':'RETAIL_DATABRICKS_PASS','rows':check['rows'],'gross_amount_pen':str(check['amount']),'path':destination}))
