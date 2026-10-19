# Evidencias del proyecto 06

## Infraestructura

- Grupo independiente: `rg-leadutp-06-dev`, Brazil South.
- API: https://ca-lead06-api.kindwave-4a2cdf0a.brazilsouth.azurecontainerapps.io
- Recursos: `log-lead06`, `appi-lead06`, `kv-lead06-rs67koo3gr6tg`, `id-lead06`, `cae-lead06`, `ca-lead06-api`.
- Módulos propios con fuentes en ACR: `bicep/leadutp/observability:1.0.2` y `bicep/leadutp/security:1.0.0`. Versiones previas conservadas sin sobrescribir.
- AVM Log Analytics `0.11.1`, retención 30 días y cuota de ingesta 1 GB/día.
- Despliegue local `leadutp-06`: Succeeded. Test-Azure.ps1: BICEP_06_TEST_PASS (HTTP 200, managed identity, minReplicas=0, límites de logs y destino correcto).
- Catálogo real de la API verificado: tres productos ficticios, moneda PEN, entorno azure-bicep-06.
- Presupuesto `budget-leadutp-06`: mensual 10 unidades de la moneda de facturación, avisos 80/100%; no detiene recursos.

## GitHub

- Repositorio: [Miguel7293/LedUtpProject](https://github.com/Miguel7293/LedUtpProject).
- Rama `codex/infraestructura-06` publicada; [PR #1](https://github.com/Miguel7293/LedUtpProject/pull/1) en borrador, sin fusionar main.
- GitHub CLI autenticado; identidad Azure `id-lead06-github` con federación OIDC para el environment azure-lab.
- Client ID: `28840f10-1b88-49cc-beb2-a16d25b37017` (identificador público, no credencial).
- El subject usa los IDs inmutables reales del repositorio/propietario. Se corrigió la primera ejecución que esperaba el formato antiguo.
- Environment restringido a main y codex/infraestructura-06; sin revisores automáticos. Variables de identidad y suscripción; destinatario de alertas como secreto AZURE_ALERT_EMAIL.
- [Validación Actions 39192558401](https://github.com/Miguel7293/LedUtpProject/actions/runs/39192558401): success. Login OIDC, restauración de módulos privados, compilación y what-if aprobados.
- [Despliegue manual Actions 39192677684](https://github.com/Miguel7293/LedUtpProject/actions/runs/39192677684): success con deploy=true: login OIDC, módulos privados, compilación, what-if, despliegue y Test-Azure.ps1 aprobados. Código validado en commit 1fe3692; los cambios posteriores son documentación.

## Límites y pendientes

- La última consulta a Log Analytics no encontró tablas: la recepción efectiva de logs sigue sin confirmarse. Test-Azure verifica configuración, no recepción de eventos.
- Express rechazó azure-monitor como destino. La integración Log Analytics usa clave del workspace y requiere disableLocalAuth=false en este laboratorio; ARM resuelve la clave sin exportarla.
- Application Insights y Key Vault están aprovisionados; la imagen de API no tiene instrumentación de trazas ni consume secretos. No se afirma haber probado esas integraciones de aplicación.
- La imagen reutiliza la etiqueta v1 del proyecto 02; fijar digest para producción.
- What-if muestra diferencias de valores predeterminados/referencias dinámicas de Azure y una asignación AcrPull no analizable antes de resolver principalId. No se declara un diff vacío.
- Saldo y fecha de expiración de Azure for Students todavía sin verificar.
- Retirar al finalizar el laboratorio: grupo 06, asignaciones de sus identidades en ACR/suscripción, federación y rol propio si ya no se usa. No eliminar el ACR compartido del proyecto 02.
