"""Verifica los Parquet reales descargados; no simula la ingesta."""
import argparse
import json
from pathlib import Path
import pyarrow.parquet as pq

parser = argparse.ArgumentParser()
parser.add_argument('--run-id', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1] / '.local' / 'bronze'
results = {}
for path in root.rglob('*.parquet'):
    if f'run_id={args.run_id}' not in path.parts:
        continue
    relative = path.relative_to(root)
    key = '/'.join(relative.parts[:2])
    table = pq.ParquetFile(path).read()
    results[key] = results.get(key, 0) + table.num_rows
    if key == 'retail/Sales':
        assert {'SaleId', 'Quantity', 'UnitPrice', 'UpdatedAt'} <= set(table.column_names)
        # SQL datetime2 puede conservar fracciones submicrosegundo en Parquet.
        # No convertir UpdatedAt a datetime de Python para validar importes.
        for row in table.select(['Quantity', 'UnitPrice']).to_pylist():
            assert row['Quantity'] > 0
            assert row['UnitPrice'] >= 0
if not results:
    raise SystemExit('No se encontraron archivos para ese run ID.')
print(json.dumps({'run_id': args.run_id, 'rows_by_table': results}, indent=2))
