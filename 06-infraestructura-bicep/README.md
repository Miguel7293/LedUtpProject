# Proyecto 06: infraestructura como código

Este laboratorio despliega su propio grupo `rg-leadutp-06-dev` en Brazil South. Reutiliza el ACR y la imagen de API del proyecto 02; ese proyecto debe conservarse.

## Componentes

- Módulos propios `observability` y `security`, publicados con fuentes en el ACR privado bajo `bicep/leadutp/observability:1.0.2` y `bicep/leadutp/security:1.0.0`.
- Log Analytics mediante Azure Verified Modules, versión fija `0.11.1`; retención de 30 días y cuota de ingesta de 1 GB/día.
- Application Insights vinculado al workspace.
- Key Vault con RBAC, eliminación recuperable y una identidad administrada con Key Vault Secrets User.
- Container Apps con HTTPS, extracción de imagen mediante identidad/AcrPull, 0–1 réplicas y logs al workspace.
- Presupuesto mensual de 10 unidades de la moneda de facturación, avisos al 80% y 100% al correo autorizado.

La imagen reutilizada no tiene instrumentación de Application Insights ni consume secretos de Key Vault. La infraestructura deja ambos componentes preparados; no se afirma una prueba de trazas ni de lectura de secretos desde esta API.

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
```

`-PublishModules` es solo para la publicación inicial. No se sobrescriben versiones existentes: al cambiar un módulo, incrementar la versión en el script y en `infra/platform.bicep`. El ACR conserva las fuentes para revisión. La compilación restaura módulos usando la sesión Azure actual.

## GitHub Actions

La plantilla `.github/workflows/infra.yml` se copia a `.github/workflows/infra06.yml` en la raíz de `Miguel7293/LedUtpProject`. El código permanece en la carpeta `06-infraestructura-bicep`; el workflow ya configura ese directorio de trabajo.

El workflow compila y ejecuta what-if al publicar cambios en main o codex/infraestructura-06; también admite ejecución manual. Aplica y verifica solo al marcar `deploy` en una ejecución manual. Usa OIDC de `azure/login`, sin contraseñas de servicio. No se ha vinculado ni ejecutado en GitHub: el repositorio autorizado es `Miguel7293/LedUtpProject` y falta completar el inicio de sesión de GitHub.

Antes de ejecutarlo:

1. Crear una identidad de automatización y una credencial federada con subject exacto `repo:PROPIETARIO/REPOSITORIO:environment:azure-lab` y audience `api://AzureADTokenExchange`.
2. Crear el environment `azure-lab`, configurar revisores de despliegue y restringir la rama autorizada.
3. Configurar variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_ALERT_EMAIL` en ese environment.
4. Asignar permisos necesarios para despliegues de suscripción/creación del grupo, Contributor y gestión de asignaciones RBAC solo en el grupo 06, y lectura de artefactos/gestión de AcrPull solo en el ACR compartido. No otorgar Owner de suscripción por comodidad. Estos permisos y la federación aún no se han creado. `scripts/Connect-GitHub.ps1` prepara la identidad, la federación y las variables una vez autenticado en GitHub. Restringe el environment a main y codex/infraestructura-06; no configura revisores automáticamente.

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
