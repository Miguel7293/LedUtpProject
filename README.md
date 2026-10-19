# Laboratorios y proyectos LEAD UTP

Cada proyecto vive en una carpeta independiente. Algunos laboratorios desplegados usan recursos de pago; consultar RESULTADO.md y las instrucciones de costos y limpieza de cada carpeta.

La descripción completa de objetivos, implementación, ejecución, verificaciones, dependencias y costos está en [GUIA-PROYECTOS.md](GUIA-PROYECTOS.md). Cada carpeta incluye además su README técnico y su informe de evidencias.

## Avance

- 01: SQL con oferta gratuita, presupuesto y consultas verificados.
- 02: web .NET y API Python probadas localmente y en Azure; publicación GitHub OIDC aprobada y Windows Server 2022 comprobado. VM Linux cubiertas por 03. Sin dominio propio disponible.
- 03: red con dos subredes y dos VM Linux desplegadas; segmentación probada con tráfico real y Network Watcher. Revisar RESULTADO.md para el estado de energía final.
- 04: ADF/ADLS con cargas completas/incrementales probadas. Databricks remoto escribió y releyó Delta: cuatro ventas, PEN 472.20. Key Vault probado tanto para configuración como para una credencial real. Clúster detenido.
- 05: Entra/RBAC, lectura privada por identidad y auditoría diaria probadas. Alertas activadas en la prueba inicial; el usuario no recibió correos. Entrega en diagnóstico, prueba nativa limitada por Students y verificación de destinatario pendiente. Authenticator confirmado.
- 06: Bicep/AVM, módulos privados y Actions probados. API instrumentada, lectura Key Vault por identidad y recepción real de logs, solicitudes y trazas verificadas.
- 07: cinco etapas Azure Pipelines y validación de PR aprobadas; revisión humana pendiente.
- 08: FastAPI/LangGraph con RAG PDF, perfiles sintéticos y modelo Azure real; ejecución local y once pruebas aprobadas.

| Carpeta | Alcance |
| --- | --- |
| [01-configuracion-costos-sql](01-configuracion-costos-sql/README.md) | Resource Groups, presupuestos y Azure SQL |
| [02-computo-web-contenedores](02-computo-web-contenedores/README.md) | VM, web .NET 10, API Python, Docker, ACR y Container Apps |
| [03-redes-seguridad](03-redes-seguridad/README.md) | VNet, subredes, VM01/VM02 y NSG |
| [04-retail-andes](04-retail-andes/README.md) | SQL, ADF, ADLS Gen2, Parquet y Databricks |
| [05-identidades-keyvault-monitoreo](05-identidades-keyvault-monitoreo/README.md) | Entra ID, RBAC, Managed Identity, Key Vault y Logic Apps |
| [06-infraestructura-bicep](06-infraestructura-bicep/README.md) | Módulos Bicep, AVM y GitHub Actions |
| [07-hero-agency](07-hero-agency/README.md) | Node.js, Docker y Azure Pipelines |
| [08-campanas-ia-banco](08-campanas-ia-banco/README.md) | FastAPI, LangGraph, RAG PDF y modelo real Azure Foundry; ejecución local |

## Forma de trabajo

- Cada carpeta tendrá su código, infraestructura, pruebas y documentación.
- Las dependencias Python se aislarán en un entorno virtual por proyecto.
- Los secretos y archivos de configuración local no se guardan en Git.
- Los despliegues de laboratorio se validan contra las cuotas y el crédito disponible.
- La eliminación de recursos debe apuntar únicamente al grupo del laboratorio correspondiente.

## Preparación

Ejecutar `./scripts/Test-Environment.ps1` en PowerShell para revisar herramientas.
El estado inicial de cada proyecto está en su README.

Antes del primer despliegue: iniciar sesión en Azure, seleccionar explícitamente la suscripción Students y verificar saldo, permisos, región y cuotas. Los presupuestos generan alertas; no detienen los recursos.
