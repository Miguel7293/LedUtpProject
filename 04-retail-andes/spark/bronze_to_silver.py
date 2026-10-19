"""Transformación PySpark sobre ejecuciones Bronze confirmadas."""
import argparse
import json
import uuid
from pathlib import Path
from pyspark.sql import SparkSession, Window, functions as F

parser = argparse.ArgumentParser()
parser.add_argument('--run-id', action='append', required=True)
parser.add_argument('--root', default='.local')
args = parser.parse_args()
run_ids = [str(uuid.UUID(value)) for value in args.run_id]
root = Path(args.root).resolve()
paths = [str(root / 'bronze' / 'retail' / 'Sales' / f'run_id={run_id}') for run_id in run_ids]
spark = SparkSession.builder.appName('RetailAndesSilver').getOrCreate()
spark.sparkContext.setLogLevel('WARN')
try:
    raw = spark.read.parquet(*paths)
    latest = raw.withColumn('_rank', F.row_number().over(Window.partitionBy('SaleId').orderBy(F.col('UpdatedAt').desc()))).filter('_rank = 1').drop('_rank')
    if latest.filter('SaleId IS NULL OR Quantity <= 0 OR UnitPrice < 0 OR UpdatedAt IS NULL').count():
        raise ValueError('Registros de venta no válidos.')
    silver = latest.withColumn('GrossAmount', (F.col('Quantity') * F.col('UnitPrice')).cast('decimal(18,2)'))
    target = root / 'silver' / 'Sales' / f'run_id={run_ids[-1]}'
    silver.write.mode('overwrite').parquet(str(target))
    metrics = silver.agg(F.count('*').alias('rows'), F.sum('GrossAmount').alias('gross')).first()
    result = {'rows': metrics.rows, 'gross_amount_pen': str(metrics.gross), 'output': str(target), 'input_run_ids': run_ids}
    root.mkdir(parents=True, exist_ok=True)
    (root / 'silver-result.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print('RETAIL_SILVER_RESULT=' + json.dumps(result))
finally:
    spark.stop()
