import argparse
from decimal import Decimal
import pyarrow.parquet as pq

parser = argparse.ArgumentParser()
parser.add_argument('--file', required=True)
args = parser.parse_args()
table = pq.ParquetFile(args.file).read()
rows = table.select(['SaleId', 'GrossAmount']).to_pylist()
assert len(rows) == 4, rows
assert len({row['SaleId'] for row in rows}) == 4
gross = sum((row['GrossAmount'] for row in rows), Decimal('0'))
assert gross == Decimal('472.20'), gross
print(f'Silver remoto verificado: {len(rows)} ventas, PEN {gross}')
