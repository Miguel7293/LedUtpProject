import logging
import os
from contextlib import asynccontextmanager

if os.getenv('APPLICATIONINSIGHTS_CONNECTION_STRING'):
    from azure.monitor.opentelemetry import configure_azure_monitor
    configure_azure_monitor(logger_name='leadutp06', enable_live_metrics=False,
                            enable_performance_counters=False, disable_offline_storage=True)

from fastapi import FastAPI, HTTPException
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

logger = logging.getLogger('leadutp06')
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())
config = {'loaded': False}

@asynccontextmanager
async def lifespan(app):
    if os.getenv('KEY_VAULT_URI'):
        credential = ManagedIdentityCredential(client_id=os.environ['AZURE_CLIENT_ID'])
        try:
            with SecretClient(os.environ['KEY_VAULT_URI'], credential) as client:
                value = client.get_secret('catalog-label').value
                if value != 'Catalogo educativo LEAD UTP':
                    raise RuntimeError('Configuración de laboratorio inesperada.')
                config['loaded'] = True
            logger.info('KEYVAULT_CONFIG_LOADED')
        finally:
            credential.close()
    logger.info('LEADUTP06_API_STARTED')
    yield

app = FastAPI(title='Catálogo instrumentado 06', lifespan=lifespan)
PRODUCTS = [
    {'id':1,'name':'Mochila Andes','category':'Accesorios','price':89.90},
    {'id':2,'name':'Termo Lima','category':'Accesorios','price':45.00},
    {'id':3,'name':'Cuaderno UTP','category':'Papelería','price':18.50},
]

@app.get('/health')
def health():
    return {'status':'ok','service':'catalog-api','key_vault_loaded':config['loaded']}

@app.get('/api/products')
def products():
    logger.info('CATALOG_REQUEST_OK')
    return {'items':PRODUCTS,'currency':'PEN','source':'demo','environment':os.getenv('APP_ENV','local')}

@app.get('/api/products/{product_id}')
def product(product_id:int):
    for item in PRODUCTS:
        if item['id'] == product_id:
            return item
    raise HTTPException(404,'Producto no encontrado')
