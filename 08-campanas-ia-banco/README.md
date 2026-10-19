# Banco ABC: campañas con IA

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

## Crear el proyecto de Microsoft Foundry

1. Abrir https://ai.azure.com con la cuenta de Azure y seleccionar la suscripción **Azure for Students**. La interfaz puede mostrar Microsoft Foundry o Azure AI Foundry.
2. Seleccionar **Create a new project** y usar `banco-abc`.
3. En **Advanced options**, usar un grupo independiente `rg-leadutp-08-dev`. Probar `East US 2` si está disponible para este recurso y la política de la suscripción lo permite.
4. Crear el proyecto. En **Build > Models > Deploy > Deploy a base model**, revisar los modelos disponibles, su precio y la cuota asignable antes de desplegar.
5. Elegir un modelo de texto pequeño disponible, con la capacidad mínima permitida para el laboratorio. Usar el nombre de despliegue `banco-abc-texto`. La disponibilidad y la cuota dependen de la suscripción, región y modelo; no están garantizadas por Azure for Students.
6. Copiar el **project endpoint** de la pantalla de bienvenida y el nombre del despliegue. Son datos de configuración, no claves. No compartir tokens ni API keys.

Si aparece `Insufficient quota`, registrar modelo, región, tipo de despliegue y mensaje completo. No convertir la suscripción a pago para resolverlo sin revisar primero las alternativas.

## Comprobación del entorno (19 de octubre de 2026)

- Recurso, proyecto y despliegue Succeeded.
- Dos generaciones reales completadas; última validada con tres campañas.
- Once pruebas automatizadas aprobadas, incluida afinidad demográfica sintética y exclusión de identificadores. Ver RESULTADO.md.

Referencia oficial: https://learn.microsoft.com/en-us/azure/foundry/tutorials/quickstart-create-foundry-resources
