# Proyecto 06: infraestructura como código

## Retiro de recursos de Azure — 19 de octubre de 2026

El propietario autorizó eliminar los recursos de Azure de este laboratorio para detener futuros cargos. Se verificó la eliminación de su grupo de recursos y de todos los recursos del laboratorio; las pruebas y direcciones descritas abajo documentan el funcionamiento anterior y no garantizan que los servicios sigan disponibles. Se conservan código, infraestructura y evidencias. Los despliegues de GitHub Actions y Azure Pipelines se deshabilitaron para impedir la recreación automática.

Los respaldos de archivos y datos de demostración se guardan únicamente en `.local/retirada-2026-10-19/` en la raíz del workspace, excluida de Git. No es un respaldo completo de máquinas, imágenes o base SQL: se conservan scripts de inicialización, datos Bronze/Silver, documentos, reportes y votos de demostración. Las contraseñas, secretos e identidades administradas no se restauran desde esos respaldos. Para volver a publicar, revisar los scripts y los costos antes de desplegar.

## Descripción de lo realizado

**Objetivo:** desplegar una plataforma repetible y verificarla con CI/CD.

Bicep organiza recursos, módulos propios versionados en el ACR y un módulo AVM para Log Analytics. Despliega Container Apps, identidad, Key Vault, Application Insights, workspace y presupuesto. GitHub Actions usa OIDC para compilar, revisar what-if, desplegar y verificar la API.

La ampliación incorpora una imagen propia instrumentada con OpenTelemetry. Al iniciar, la API lee `catalog-label` de Key Vault mediante su identidad administrada; no devuelve el valor del secreto. Las peticiones y trazas llegan a Application Insights y los registros de consola a Log Analytics. Se fijó la imagen por digest para evitar cambios accidentales de etiqueta.

**Uso:** `06-infraestructura-bicep/scripts/Test-Azure.ps1`, `Inspect-Logs.ps1` e `Inspect-Telemetry.ps1`. La API es `https://ca-lead06-api.kindwave-4a2cdf0a.brazilsouth.azurecontainerapps.io`.

La integración de logs del entorno Express usa internamente una clave de workspace resuelta por ARM; las aplicaciones se autentican con identidad administrada para Key Vault. No se debe describir toda la plataforma como completamente libre de claves.

Este laboratorio despliega su propio grupo `rg-leadutp-06-dev` en Brazil South. Reutiliza el ACR del proyecto 02 y publica su propia imagen instrumentada; el registro compartido debe conservarse.

## Componentes

- Módulos propios `observability` y `security`, publicados con fuentes en el ACR privado bajo `bicep/leadutp/observability:1.0.2` y `bicep/leadutp/security:1.0.0`.
- Log Analytics mediante Azure Verified Modules, versión fija `0.11.1`; retención de 30 días y cuota de ingesta de 1 GB/día.
- Application Insights vinculado al workspace.
- Key Vault con RBAC, eliminación recuperable y una identidad administrada con Key Vault Secrets User.
- Container Apps con HTTPS, extracción de imagen mediante identidad/AcrPull, 0–1 réplicas y logs al workspace.
- Presupuesto mensual de 10 unidades de la moneda de facturación, avisos al 80% y 100% al correo autorizado.

La imagen de `api/` incorpora OpenTelemetry para Application Insights y lee una etiqueta sintética de Key Vault mediante identidad administrada al iniciar. Se verificó recepción real de solicitudes, trazas y registros de consola. La imagen está fijada por digest en Bicep. Las evidencias históricas y finales están en RESULTADO.md.

## Uso desde la raíz LeadUTP

```powershell
# Revisar cambios
./06-infraestructura-bicep/scripts/Deploy.ps1
# Aplicar
./06-infraestructura-bicep/scripts/Deploy.ps1 -Deploy
# Verificar HTTP, identidad, escala y límites del workspace
./06-infraestructura-bicep/scripts/Test-Azure.ps1
# Consultar logs reales (pueden tardar varios minutos en aparecer)
./06-infraestructura-bicep/scripts/Inspect-Logs.ps1
# Comprobar solicitudes y trazas de la API instrumentada
./06-infraestructura-bicep/scripts/Inspect-Telemetry.ps1
```

`-PublishModules` es solo para la publicación inicial. No se sobrescriben versiones existentes: al cambiar un módulo, incrementar la versión en el script y en `infra/platform.bicep`. El ACR conserva las fuentes para revisión. La compilación restaura módulos usando la sesión Azure actual.

## GitHub Actions

Repositorio: [Miguel7293/LedUtpProject](https://github.com/Miguel7293/LedUtpProject). Rama publicada: `codex/infraestructura-06`. [PR #1](https://github.com/Miguel7293/LedUtpProject/pull/1), en borrador y sin fusionar.

La plantilla `.github/workflows/infra.yml` se copia a `.github/workflows/infra06.yml` en la raíz del repositorio. El código permanece en la carpeta `06-infraestructura-bicep`, que el workflow usa como directorio de trabajo.

El push en main o codex/infraestructura-06 compila y ejecuta what-if. La ejecución manual permite marcar `deploy` para aplicar infraestructura y verificar HTTP/configuración. La validación real de OIDC, descarga de módulos privados, compilación y what-if terminó correctamente en [Actions](https://github.com/Miguel7293/LedUtpProject/actions/runs/39192558401). Consultar RESULTADO.md para la evidencia del despliegue manual.

La identidad `id-lead06-github` usa federación OIDC sin contraseña. El subject exacto contiene IDs inmutables: `repo:Miguel7293@114840612/LedUtpProject@1425027654:environment:azure-lab`. Issuer: `https://token.actions.githubusercontent.com`; audience: `api://AzureADTokenExchange`.

El environment azure-lab permite main y codex/infraestructura-06. Tiene variables AZURE_CLIENT_ID, AZURE_TENANT_ID y AZURE_SUBSCRIPTION_ID, y el secreto AZURE_ALERT_EMAIL para ocultar el destinatario en los logs. No se configuraron revisores automáticos del environment.

Permisos de la identidad:

- Contributor y Role Based Access Control Administrator en el grupo 06.
- AcrPull y Role Based Access Control Administrator solo en el ACR compartido.
- Rol propio LeadUTP06 Subscription Deployment: operaciones de despliegues ARM en la suscripción; no concede escritura de recursos de otros grupos.

`scripts/Connect-GitHub.ps1` reproduce esta configuración para el repositorio autorizado con una sesión administrativa de Azure y una sesión GitHub. No se otorga Owner de suscripción a Actions. Al terminar el curso, retirar también la federación, las asignaciones de esta identidad en el ACR y la suscripción y el rol propio si ya no se usa.

## Costos y limpieza

La cuota de logs limita ingesta de forma aproximada; puede haber demora y sobrepaso. El presupuesto **no detiene recursos**. Container Apps escala a cero, pero peticiones y logs pueden generar consumo. No se verificó el saldo restante de Students.

Para retirar únicamente este laboratorio, revisar y ejecutar manualmente:

```powershell
az group delete --name rg-leadutp-06-dev
```

No eliminar el grupo 02: lo usan otros laboratorios. Al eliminar 06, retirar también la asignación AcrPull de su identidad en el ACR; Key Vault permanece recuperable durante siete días. Los artefactos Bicep publicados en el ACR siguen almacenados hasta retirarlos expresamente.

Fuentes: [AVM Log Analytics](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/operational-insights/workspace), [registro privado Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/private-module-registry).

La integración de logs del entorno Express requiere autenticación por clave en el workspace (disableLocalAuth=false). La clave se consulta dentro de ARM y no se exporta. Este tipo de entorno rechazó el destino alternativo azure-monitor en su validación de Azure.

En otro equipo, indicar -ContactEmail al ejecutar Deploy.ps1, o definir AZURE_ALERT_EMAIL. En este equipo el destinatario autorizado se guarda en .local/settings.json, excluido de Git.
