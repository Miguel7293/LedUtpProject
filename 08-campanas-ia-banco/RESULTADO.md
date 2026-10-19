# Resultado del proyecto 08

Verificado el 19 de octubre de 2026:

- Foundry creado por el usuario en grupo independiente 08; proyecto y recurso Succeeded.
- Despliegue `banco-abc-texto` creado y verificado Succeeded: gpt-4.1-mini 2025-04-14, GlobalStandard, capacidad 1.
- Permiso Cognitive Services OpenAI User asignado al usuario Azure CLI únicamente en el recurso. Sin API keys en código.
- FastAPI y LangGraph implementados; 10 pruebas aprobadas: consentimiento, ranking, vigencia, PDF, modo Azure deshabilitado por defecto, ausencia de fallback simulado, entrada inválida, campañas inventadas, promesas y documentos visuales.
- Guía de marca ficticia PDF generada y revisada visualmente, una página.
- Dos generaciones reales: primera 1398 tokens; revisión detectó un pasaporte en prompt visual. Se endurecieron instrucciones y validación. Segunda 1462 tokens, tres borradores completos y validación aprobada. Total reportado: 2860 tokens; importe monetario no verificado.
- Última evidencia: `.local/azure-generation.json`, estado `needs_human_review`.

Aplicación local y modelo remoto real. Sin despliegue público de API, envío de mensajes, base SQL, imágenes generadas ni datos reales. Matching por reglas; redactor Azure con LLM. Referencias PDF muestran contexto recuperado, no validación semántica de cada frase. Borradores requieren revisión humana.

## Ampliación del cierre

Perfiles ampliados con DNI explícitamente ficticio, rango de edad, estado civil y número de hijos sintéticos. Afinidad educativa adicional para etapa de estudio o perfil familiar; sin decisiones crediticias. DNI y estado civil no afectan el ranking ni se envían al modelo. Once pruebas aprobadas tras la ampliación. La redacción sigue basada en las campañas afines sin mencionar ni inferir datos familiares del destinatario.

Tercera llamada real tras la ampliación: 1512 tokens y tres borradores validados. Total de las tres llamadas: 4372 tokens. API local reiniciada para cargar la versión nueva; el modo de pago permanece deshabilitado por defecto.
