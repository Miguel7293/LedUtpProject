# Preparación local

## Herramientas

- Git 2.51.0 y Node.js 20.17.0 detectados. La versión de Node se revisará al implementar las aplicaciones.
- Azure CLI 2.91.0 instalado y ejecutado correctamente.
- Bicep 0.48.1 instalado mediante Azure CLI.
- Python 3.12.10 instalado con pip 25.0.1. Se prefiere frente al Python de MSYS2 que no tiene pip.
- .NET SDK 10.0.402 instalado; validado con `dotnet --version` y `dotnet --list-sdks`.
- Docker CLI y motor Linux 28.5.1 disponibles; conexión validada con `docker info`.

## Activar herramientas en la terminal actual

```powershell
. ./scripts/Enter-DevEnvironment.ps1
./scripts/Test-Environment.ps1
```

## Conectar Azure

Inicio de sesión completado. Suscripción Azure for Students seleccionada y estado Enabled verificado desde el entorno de desarrollo. Para futuras sesiones, si caduca el acceso:

```powershell
. ./scripts/Enter-DevEnvironment.ps1
az login
az account list --output table
```

Completar el inicio de sesión y MFA personalmente en el navegador. Seleccionar explícitamente la suscripción Students antes de crear recursos. No compartir contraseñas ni códigos MFA en el chat.

Permiso Owner validado. Pendiente: revisar crédito restante y vencimiento; cuotas y regiones se validan por servicio. Primer laboratorio desplegado en `rg-leadutp-01-dev`: SQL gratuito en Brazil South y presupuesto mensual. Consultar `01-configuracion-costos-sql/RESULTADO.md`.

## Incidencia de Docker

Incidencia anterior: fallo al inicializar Inference manager al abrir el socket local `dockerInference`. Después del reinicio, el motor responde correctamente. No se borraron datos, contenedores ni distribuciones WSL durante el diagnóstico.

Estado actual: resuelta; motor Linux 28.5.1 validado.

## Aplicaciones del bloque 02

Web .NET y API Python ejecutadas en Docker local y desplegadas en Azure (App Service F1, ACR Basic y Container Apps). Comprobaciones HTTP locales y remotas aprobadas. Ver `02-computo-web-contenedores/RESULTADO.md` para recursos, costos y ejercicios pendientes.

## Redes del bloque 03

Dos VM Ubuntu ARM64 y una VNet segmentada desplegadas en Central US, con NSG probados mediante tráfico HTTP real y Network Watcher. Ambas VM quedaron en `VM deallocated`; discos e IP públicas conservan costos. Ver `03-redes-seguridad/RESULTADO.md`.

## Retail Andes del bloque 04

ADF y ADLS Gen2 desplegados con identidad administrada. Carga completa y dos incrementales verificadas (ventas 3/2/0), checkpoint e idempotencia de Commit comprobados. Silver procesado con PySpark local, publicado en Azure y descargado para validar cuatro ventas por PEN 472.20. Databricks remoto y Key Vault quedan pendientes. Ver `04-retail-andes/RESULTADO.md`.

## Seguridad del bloque 05

Grupos Entra y roles Reader/Contributor/Owner en el grupo del laboratorio, Key Vault con secretos sintéticos/llaves/certificado, Storage privado y prueba VM01 con managed identity completados. Lectura del PDF y denegación de escritura verificadas. Logic Apps diario a las 08:00 Lima con reporte de vencimientos y dos alertas Azure Monitor Fired (15/30 días). La entrega al buzón no se confirmó. Ambas VM quedan desasignadas. Ver `05-identidades-keyvault-monitoreo/RESULTADO.md`.

## Infraestructura del bloque 06

Módulos Bicep propios publicados en el ACR compartido y AVM Log Analytics restaurado. Container Apps, identidad, Key Vault, Application Insights, workspace y presupuesto desplegados en el grupo 06. API HTTP 200 y configuración de escala/retención verificadas. Repositorio elegido: Miguel7293/LedUtpProject; rama publicada, PR #1 en borrador y Actions OIDC/compilación/what-if aprobados. Consultar `06-infraestructura-bicep/RESULTADO.md` para evidencia final de logs.


## Hero Agency del bloque 07

Aplicación Node.js 24 / Express 5, interfaz de votación y Docker implementados. Pruebas locales y HTTP en Azure aprobadas, incluyendo votos reales ficticios en dos tablas separadas mediante managed identity. Organización Azure DevOps miguel7293-leadutp, proyecto LeadUTP, repositorio HeroAgency y pipeline 1 configurados. Políticas de main: revisión obligatoria y Build Validation. Las cinco etapas de la ejecución 1 aprobaron; ambas apps usan el mismo digest y conservaron sus votos tras la promoción. Consultar 07-hero-agency/RESULTADO.md para evidencias y revisión pendiente del PR.


## Cierre técnico del 19 de octubre de 2026

- Web 02 publicada desde GitHub Actions con OIDC y catálogo verificado. VM Windows Server 2022 probada y desasignada; sin dominio propio disponible.
- API 06 instrumentada con OpenTelemetry, lectura real de Key Vault por identidad y recepción de solicitudes, trazas y consola comprobadas. Despliegue Actions 39213075970 aprobado.
- Banco ABC 08: FastAPI/LangGraph, PDF y modelo Foundry real; once pruebas aprobadas, perfiles totalmente ficticios, tres llamadas reales al modelo y API local en 18090.
- Retail Andes: workspace Databricks y acceso UC configurados, ADF leyó Key Vault correctamente. El estado final de la ejecución remota está en 04-retail-andes/RESULTADO.md.
- La guía del portafolio está en GUIA-PROYECTOS.md. Los apartados anteriores describen el avance histórico; los informes RESULTADO.md incluyen el cierre más reciente.
