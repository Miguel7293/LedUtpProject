import logging
import os
import threading
from typing import Literal
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict
from .workflow import run, CUSTOMERS, PDF

app = FastAPI(title='Banco ABC | Campañas ficticias', version='1.0.0')
lock = threading.Lock()

class Request(BaseModel):
    model_config = ConfigDict(extra='forbid')
    customer_id: str
    mode: Literal['local', 'azure'] = 'local'

@app.get('/')
def index():
    return {'project': 'Banco ABC ficticio', 'docs': '/docs', 'notice': 'Solo borradores. Local usa reglas; azure consume el modelo desplegado.'}

@app.get('/health')
def health():
    if not PDF.is_file():
        raise HTTPException(503, 'Falta la guía PDF.')
    return {'status': 'ok', 'azure_enabled': os.getenv('ENABLE_AZURE_GENERATION') == 'true'}

@app.get('/customers')
def customers():
    return [{'id': c['id'], 'interests': c['interests'], 'marketing_consent': c['marketing_consent']} for c in CUSTOMERS]

@app.post('/campaigns/generate')
def generate(request: Request):
    if request.mode == 'azure' and os.getenv('ENABLE_AZURE_GENERATION') != 'true':
        raise HTTPException(503, 'Generación Azure deshabilitada; habilitar explícitamente para consumir el modelo.')
    # Serializes generation in this single-process local lab, limiting concurrent paid requests.
    if not lock.acquire(blocking=False):
        raise HTTPException(429, 'Ya hay una generación en curso.')
    try:
        return run(request.customer_id, request.mode)
    except KeyError:
        raise HTTPException(404, 'Perfil ficticio no encontrado.')
    except PermissionError as exc:
        raise HTTPException(403, str(exc))
    except Exception:
        logging.getLogger(__name__).exception('Generación fallida')
        raise HTTPException(502, 'No se pudo generar o validar el borrador. No se usó una respuesta simulada.')
    finally:
        lock.release()
