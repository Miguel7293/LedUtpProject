# Resultado del primer laboratorio

## Retiro de recursos de Azure — 19 de octubre de 2026

El propietario autorizó eliminar los recursos de Azure de este laboratorio para detener futuros cargos. Se verificó la eliminación de su grupo de recursos y de todos los recursos del laboratorio; las pruebas y direcciones descritas abajo documentan el funcionamiento anterior y no garantizan que los servicios sigan disponibles. Se conservan código, infraestructura y evidencias. Los despliegues de GitHub Actions y Azure Pipelines se deshabilitaron para impedir la recreación automática.

Los respaldos de archivos y datos de demostración se guardan únicamente en `.local/retirada-2026-10-19/` en la raíz del workspace, excluida de Git. No es un respaldo completo de máquinas, imágenes o base SQL: se conservan scripts de inicialización, datos Bronze/Silver, documentos, reportes y votos de demostración. Las contraseñas, secretos e identidades administradas no se restauran desde esos respaldos. Para volver a publicar, revisar los scripts y los costos antes de desplegar.

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
