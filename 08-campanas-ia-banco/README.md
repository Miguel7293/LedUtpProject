# Banco ABC: campañas con IA

## Retiro de recursos de Azure — 19 de octubre de 2026

El propietario autorizó eliminar los recursos de Azure de este laboratorio para detener futuros cargos. Se verificó la eliminación de su grupo de recursos y de todos los recursos del laboratorio; las pruebas y direcciones descritas abajo documentan el funcionamiento anterior y no garantizan que los servicios sigan disponibles. Se conservan código, infraestructura y evidencias. Los despliegues de GitHub Actions y Azure Pipelines se deshabilitaron para impedir la recreación automática.

Los respaldos de archivos y datos de demostración se guardan únicamente en `.local/retirada-2026-10-19/` en la raíz del workspace, excluida de Git. No es un respaldo completo de máquinas, imágenes o base SQL: se conservan scripts de inicialización, datos Bronze/Silver, documentos, reportes y votos de demostración. Las contraseñas, secretos e identidades administradas no se restauran desde esos respaldos. Para volver a publicar, revisar los scripts y los costos antes de desplegar.

## Descripción de lo realizado

**Objetivo:** seleccionar campañas afines y generar comunicaciones con una guía de marca recuperada de PDF.

FastAPI expone perfiles ficticios y un endpoint de generación. LangGraph encadena selección, recuperación de conocimiento, redacción y validación. El matching usa reglas explicables de intereses y categorías de consumo. El RAG extrae texto del PDF y recupera fragmentos por coincidencia léxica, con página y fuente; no necesita un servicio vectorial.

El modo local usa plantillas. El modo Azure llama realmente al despliegue `banco-abc-texto` de gpt-4.1-mini en Foundry y exige salida JSON estructurada. Produce asunto, preheader, cuerpo, SMS, pop-up y prompt de imagen en inglés para cada campaña. Las condiciones se toman del catálogo. Los prompts no se envían a generadores de imágenes.

Once pruebas verificaron el flujo y sus restricciones; también se realizaron llamadas reales al modelo. Los perfiles incluyen DNI ficticio, rango de edad, estado civil e hijos sintéticos. El matching incorpora una afinidad educativa limitada a etapa de estudio o familiar; DNI y estado civil quedan excluidos del ranking y del modelo. Los resultados son `needs_human_review`. No se envían mensajes ni se toman decisiones de crédito.

**Uso:** `08-campanas-ia-banco/scripts/Start-Local.ps1`, abrir `http://localhost:18090/docs`. Para consumo del modelo remoto, reiniciar con `-Azure` y usar `mode: "azure"`. La API permanece local, sin autenticación para publicación pública.

Implementado con FastAPI, LangGraph y modelo real Azure. Datos y marca ficticios; solo genera borradores para revisión humana.

## Ejecutar y probar

Desde la raíz del workspace, ejecutar `./08-campanas-ia-banco/scripts/Start-Local.ps1` y abrir http://localhost:18090/docs.

En `POST /campaigns/generate` usar `{"customer_id":"demo-001","mode":"local"}`. Local usa plantillas, no IA generativa. Para llamadas pagadas, reiniciar con `Start-Local.ps1 -Azure` y enviar `mode: "azure"`. Requiere Azure CLI autenticado. El script configura endpoint y despliegue, sin claves. `.env.example` no se carga automáticamente.

Si falta el entorno virtual: activar `scripts/Enter-DevEnvironment.ps1` del workspace, crear con `python -m venv 08-campanas-ia-banco/.venv` e instalar `requirements.txt` con el Python de ese entorno.

Desde esta carpeta ejecutar `.venv/Scripts/python.exe -m pytest tests -q`. La prueba pagada es `scripts/Test-Azure.py`, requiere las variables del script de inicio y `$env:PYTHONPATH='.'`. Guarda evidencia en `.local/azure-generation.json`.

## Arquitectura y límites

LangGraph ejecuta `matching -> retrieve_pdf -> creative -> validate`. Matching es determinista: interés declarado (2 puntos) + proporción del consumo ficticio en categoría + afinidad educativa (0.2 puntos) para perfiles sintéticos en etapa de estudio o con hijos. Filtra campañas vencidas y exige consentimiento. Selecciona hasta tres con afinidad positiva. No evalúa solvencia ni decisiones de crédito. DNI ficticio y estado civil existen solo para explicar el esquema del ejercicio, se excluyen del ranking y del modelo. Edad por rangos y número de hijos se usan únicamente en esta demostración con datos inventados.

RAG real con extracción pypdf y recuperación léxica de fragmentos solapados con página de origen. No usa embeddings ni Azure AI Search. `sources` muestra el contexto entregado, no prueba que todas las frases cumplan la guía. La guía ficticia está en `output/pdf/` y se regenera con `scripts/create_brand_pdf.py`.

Redactor local con plantillas o Azure con JSON Schema estricto. Solo se envían campañas seleccionadas y guía; no IDs de cliente ni perfil completo. Validación de esquema, longitudes, IDs, orden, cifras/promesas y restricciones visuales básicas; condiciones y beneficio se añaden desde catálogo. No garantiza exactitud semántica: requiere revisión editorial. Prompts de imagen en inglés; no genera imágenes ni llama a Flux/Gemini/Nano Banana.

Servidor local en loopback, sin login ni persistencia. No publicarlo directamente: antes requiere autenticación, autorización, límites por usuario, monitoreo y evaluación. La exclusión mutua limita concurrencia solo dentro de un proceso, no gasto acumulado. No envía mensajes.

## Azure verificado

- Grupo `rg-leadutp-08-dev`, región Brazil South, recurso `banco-abc-resource`, proyecto `banco-abc`.
- Endpoint de proyecto: `https://banco-abc-resource.services.ai.azure.com/api/projects/banco-abc`.
- Inferencia: `https://banco-abc-resource.openai.azure.com`.
- Despliegue `banco-abc-texto`: gpt-4.1-mini, versión 2025-04-14, GlobalStandard, capacidad 1.
- AzureCliCredential local y permiso Cognitive Services OpenAI User en el recurso. Opción ManagedIdentityCredential con `AZURE_USE_MANAGED_IDENTITY=true`, todavía sin API alojada ni identidad de aplicación configurada.
- Inferencias pagadas por tokens. Presupuesto 10 unidades de moneda de facturación, 80%/100%; no detiene recursos. Saldo restante no verificado.

Para retirar solo el modelo: `az cognitiveservices account deployment delete -g rg-leadutp-08-dev -n banco-abc-resource --deployment-name banco-abc-texto`. Detener el servidor local no elimina Foundry. Revisar Cost Management para costo acumulado.

Referencia de integración: [OpenAI Docs: salidas estructuradas](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=chat).


## Comprobación del entorno

- Recurso, proyecto y despliegue Succeeded.
- Dos generaciones reales completadas; última validada con tres campañas.
- Once pruebas automatizadas aprobadas, incluida afinidad demográfica sintética y exclusión de identificadores. Ver RESULTADO.md.
