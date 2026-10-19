# Configuración, costos y Azure SQL

## Objetivo

Crear un grupo de recursos, un servidor lógico SQL y una base AdventureWorksLT mediante Bicep, con presupuesto configurable.

## Diseño

- Grupo dedicado: `rg-leadutp-01-dev`. No modifica los grupos existentes Minecraft y NetworkWatcherRG.
- Región SQL: Brazil South, disponible en la consulta de capacidades de esta suscripción. East US y East US 2 restringen el aprovisionamiento. El grupo conserva sus metadatos en East US 2; esto no impide alojar SQL en Brazil South. La oferta gratuita de SQL fija una región para las bases gratuitas de la suscripción.
- SQL General Purpose serverless: máximo 2 vCores, mínimo 0.5, 32 GB y pausa por inactividad de 60 minutos.
- `useFreeLimit=true` y `freeLimitExhaustionBehavior=AutoPause`. No hay conversión automática a pago si se rechaza la oferta.
- Identidad del usuario conectado como administrador Entra. Autenticación SQL con contraseña deshabilitada.
- Sin reglas de firewall ni acceso genérico para todos los servicios de Azure. Para consultar desde el PC habrá que autorizar únicamente su IP pública.

## Validar y desplegar

Desde la raíz LeadUTP, en PowerShell:

```powershell
./01-configuracion-costos-sql/scripts/Deploy.ps1 -Mode Validate
./01-configuracion-costos-sql/scripts/Deploy.ps1 -Mode WhatIf
./01-configuracion-costos-sql/scripts/Deploy.ps1 -Mode Deploy
```

El script verifica la suscripción antes de operar. WhatIf es el modo predeterminado.

## Presupuesto

`infra/budget.bicep` define un presupuesto mensual de 10 unidades de la moneda de facturación, con alertas al 80% y 100%. Requiere `contactEmail` y `startDate` (primer día del mes, formato ISO 8601). Se despliega por separado para elegir explícitamente el correo destinatario. Un presupuesto no detiene el consumo.

```powershell
./01-configuracion-costos-sql/scripts/Set-Budget.ps1 -ContactEmail 'tu-correo@example.com'
./01-configuracion-costos-sql/scripts/Set-Budget.ps1 -ContactEmail 'tu-correo@example.com' -Deploy
```

Estado: presupuesto `budget-leadutp-01` creado correctamente, con destinatario indicado por el usuario. El alcance es únicamente este grupo; no cubre Minecraft ni los demás proyectos.

## Verificación funcional

Tras el despliegue, verificar `useFreeLimit`, `freeLimitExhaustionBehavior` y estado de la base. Luego autorizar la IP del PC y ejecutar `sql/Verify.sql` con autenticación Entra. La consulta debe devolver clientes y productos AdventureWorksLT. Compilar Bicep o validar ARM no demuestra que las consultas SQL funcionen.

Se instaló `Microsoft.Sqlcmd` (Go) para ejecutar la prueba con el inicio de sesión de Azure CLI:

```powershell
./01-configuracion-costos-sql/scripts/Verify-Sql.ps1 -ClientIPv4 'TU_IP_PUBLICA'
```

El script agrega una regla para esa IP individual y la retira al terminar, incluso si falla la consulta. No requiere contraseñas ni guarda tokens en archivos. Si el proveedor de identidad exige otra autenticación para Azure SQL, se debe completar MFA para ese recurso.

## Limpieza

Antes de eliminar, revisar que el grupo `rg-leadutp-01-dev` contiene exclusivamente los recursos de este laboratorio. La eliminación del grupo borra su base de datos. No eliminar otros grupos de la suscripción.

## Referencias

- [Oferta gratuita SQL](https://learn.microsoft.com/en-us/azure/azure-sql/database/free-offer?view=azuresql)
- [Referencia Bicep para presupuestos](https://learn.microsoft.com/en-us/azure/templates/microsoft.consumption/2024-08-01/budgets)
