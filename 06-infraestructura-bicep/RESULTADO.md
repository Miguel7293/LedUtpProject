# Evidencias del proyecto 06

## Preparación verificada

- Compilación Bicep aprobada; módulo AVM `operational-insights/workspace:0.11.1` restaurado.
- Módulos propios `observability:1.0.2` y `security:1.0.0` publicados con fuentes en `acrleadutpjmas5j6rizpu4.azurecr.io/bicep/leadutp/`.
- What-if revisado: creación del grupo 06 y sus recursos; asignación AcrPull en el ACR del grupo 02. Esa asignación aparece como no analizable en what-if porque depende del principalId de la identidad nueva.
- Sintaxis de scripts PowerShell validada.

## Pendientes explícitos

- Vincular repositorio GitHub, identidad OIDC, permisos y variables; ejecutar el workflow real. La carpeta contiene el workflow manual, pero aún no existe evidencia de un run en GitHub.
- Instrumentar la API para Application Insights y consumir secretos desde Key Vault si se quiere demostrar integración de aplicación. Los componentes de infraestructura por sí solos no prueban esas funcionalidades.
- La API reutiliza la etiqueta `v1` del proyecto 02; para producción fijar digest y establecer política de actualización.
- Revisar saldo y fecha de expiración de Azure for Students.


## Despliegue verificado

- Despliegue de suscripción `leadutp-06`: Succeeded.
- Grupo `rg-leadutp-06-dev`, Brazil South.
- API: https://ca-lead06-api.kindwave-4a2cdf0a.brazilsouth.azurecontainerapps.io
- `Test-Azure.ps1`: BICEP_06_TEST_PASS, HTTP 200, identidad administrada, minReplicas=0, retención 30 días y cuota 1 GB/día.
- Recursos: `log-lead06`, `appi-lead06`, `kv-lead06-rs67koo3gr6tg`, `id-lead06`, `cae-lead06`, `ca-lead06-api`.
- Presupuesto `budget-leadutp-06`, mensual 10 unidades, avisos 80/100%.
- La versión observability 1.0.1 usa el output de AVM para resolver la dependencia de creación del workspace; la versión 1.0.0 quedó publicada como antecedente y no se consume.
- Repositorio elegido: Miguel7293/LedUtpProject. GitHub CLI instalado; la autenticación del usuario sigue pendiente. No se ha publicado código ni configurado OIDC aún.


## Publicación preparada

La rama local `codex/infraestructura-06` se preparó en `.local/repository` a partir del único README remoto, sin modificar main. El workflow se ubicará en la raíz `.github/workflows/infra06.yml`, con la carpeta del laboratorio como directorio de trabajo.

Para GitHub CLI, ejecutar en una terminal del usuario:

```powershell
& 'C:/Program Files/GitHub CLI/gh.exe' auth login --hostname github.com --git-protocol https --web
```

Después se podrá configurar OIDC con `scripts/Connect-GitHub.ps1` y publicar la rama. El push ejecutará solo compilación y what-if; el despliegue requiere ejecución manual.

## Configuración final de logs y costos

El entorno Express rechazó el destino azure-monitor durante la validación. La versión final `observability:1.0.2` habilita autenticación local exclusivamente en el workspace de este laboratorio para la integración nativa Log Analytics. La clave se resuelve en ARM; no se imprime ni se exporta al repositorio. Las versiones anteriores de los módulos permanecen en el ACR y no se sobrescribieron.

El último despliegue y Test-Azure.ps1 terminaron correctamente. La prueba confirma además que el customerId del destino de logs coincide con el workspace. El what-if posterior muestra diferencias de propiedades predeterminadas/referencias dinámicas de Azure; no se interpreta como un diff vacío ni se declara idempotencia totalmente demostrada.

La configuración final de logs está aplicada, pero la última consulta todavía no encontró tablas en el workspace. La ingesta efectiva permanece pendiente de confirmación; no confundir la configuración de destino aprobada con evidencia de logs recibidos.
