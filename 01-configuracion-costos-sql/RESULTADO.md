# Resultado del primer laboratorio

Verificado el 18 de octubre de 2026 (America/Lima).

## Recursos creados

- Grupo: `rg-leadutp-01-dev`.
- Servidor: `sql-leadutp-epf457eti6toe`.
- Región del servidor y base: Brazil South.
- Base: `sqldb-leadutp`, muestra AdventureWorksLT.
- Presupuesto: `budget-leadutp-01`, mensual, USD 10 (moneda USD confirmada por Azure), alertas al 80% y 100%, correo elegido por el usuario.

## Verificaciones

- Bicep compila y los scripts PowerShell pasan análisis sintáctico.
- Validación ARM y despliegue final: Succeeded.
- Estado SQL: Online.
- `useFreeLimit`: true.
- `freeLimitExhaustionBehavior`: AutoPause.
- `autoPauseDelay`: 60 minutos.
- Conexión cifrada con sqlcmd y autenticación Entra mediante Azure CLI: correcta.
- Consulta a `SalesLT.Customer`: 847 clientes.
- Consulta a `SalesLT.Product`: 10 productos devueltos.
- Regla individual temporal retirada; consulta posterior de reglas de firewall: lista vacía.

## Límites

El presupuesto solo cubre este grupo y no detiene servicios. El saldo y vencimiento del crédito Students no se han verificado. La base se pausa al agotar su límite gratuito y por inactividad; mantener conexiones abiertas puede impedir la pausa por inactividad.

East US 2 rechazó el primer intento de servidor por restricción regional. La consulta de capacidades mostró Brazil South disponible y allí se completó el despliegue. No se cambió a una modalidad de pago. El servidor del primer intento no aparece como recurso existente.
