# Resultado del laboratorio 05

Verificado el 18 de octubre de 2026, America/Lima.

## Entra y RBAC

- Creado `GRP_bootcamp_LEAD_UTP`: Reader en `rg-leadutp-05-dev`.
- Creado `GRP_bootcamp_LEAD_UTP_Contributor`: Contributor en ese grupo de recursos, sin miembros.
- Creado `GRP_bootcamp_LEAD_UTP_Owner`: Owner en ese grupo de recursos, sin miembros.
- Usuario lector de laboratorio creado, deshabilitado y agregado al grupo base. Contraseña aleatoria no guardada ni mostrada.
- Asignaciones RBAC consultadas en Azure y verificadas en el alcance del laboratorio.
- Microsoft Authenticator: el usuario confirmó que está vinculado a la cuenta de Azure. No se verificaron automáticamente todas las políticas de MFA del tenant.

## Recursos y datos

- Grupo: `rg-leadutp-05-dev`, Brazil South.
- Key Vault: `kv-lead05-fnihwkcijj322`, RBAC y borrado suave.
- Storage: `stlead05fnihwkcijj322`, contenedores documents/reports privados, claves compartidas deshabilitadas.
- Secretos sintéticos a 10/25/90 días; llaves RSA-2048 a 20 días y EC P-256 a 90 días.
- Certificado autofirmado de demostración a 12 días; no apto para producción.
- PDF generado con ReportLab, texto comprobado con pypdf y página renderizada e inspeccionada visualmente.
- Presupuesto `budget-leadutp-05`: USD 10/mes, alertas al 80% y 100% al correo del usuario. No detiene recursos.

## VM e identidad administrada

VM01 del proyecto 03 recibió una identidad SystemAssigned y permiso Storage Blob Data Reader solamente sobre documents.

Prueba real desde la VM:

- Token obtenido desde IMDS, sin contraseñas ni claves de Storage.
- PDF privado leído por HTTPS: 2,766 bytes.
- SHA-256: `e7f40e6180f6ae080d52de0f839cf62d35c62001151f9c498b38dea2afbf1976`, idéntico al original.
- Intento de escritura: 403 esperado.
- Marcador: `MI_STORAGE_TEST_PASS`.
- Estado final consultado: VM01 y VM02 en `VM deallocated`.

## Logic Apps, métricas y correo

- Workflow: `logic-keyvault-expiry`, Enabled.
- Recurrencia consultada: diaria a las 08:00, zona SA Pacific Standard Time (America/Lima).
- Primer horario programado: 19 de octubre de 2026 a las 08:00 Lima.
- Ejecución manual: `08584092301816762758988266131CU08`, Succeeded; todas las acciones verificadas Succeeded.
- Reporte privado generado en `reports/keyvault-expiry/latest.json`.
- Dos objetos en intervalo hasta 15 días: secreto de 10 días y certificado de 12 días.
- Dos objetos entre más de 15 y 30 días: secreto de 25 días y llave RSA de 20 días.
- Llave EC y secreto de 90 días excluidos por no estar próximos a vencer. Objetos administrados por certificados excluidos para evitar doble conteo.
- Las métricas reales Due15Days y Due30Days registraron valor 2 en Azure Monitor.
- Reglas `keyvault-expiry-15-days` y `keyvault-expiry-30-days` verificadas en estado Fired.
- Action Group configurado para `[destinatario configurado localmente]`.
- Marcador: `MONITOR_TEST_PASS`.

La activación de las alertas está comprobada; la entrega y lectura en el buzón no se confirmó. Las alertas son agregadas y con estado, no notificaciones individuales por cada objeto ni recordatorios diarios si la condición no cambia. El reporte sí se actualiza diariamente.

## Costos y dependencias

Logic Apps, Key Vault, reglas de alerta y Storage pueden generar cargos. El crédito restante Students no se verificó. No hay cómputo VM activo al terminar; discos e IP públicas del proyecto 03 conservan cargos.

## Revisión de entrega del 19 de octubre

El usuario informó que no recibió los correos. Se comprobó `ag-keyvault-expiry` habilitado, destinatario Enabled y ambas reglas enlazadas al grupo correcto. El estado Enabled no confirma recepción ni verificación OTP del buzón.

La API de prueba de notificaciones devolvió `Conflict: Free subscription not supported`. Es una limitación observada de esa operación en esta suscripción; no demuestra por sí sola que las alertas normales estén bloqueadas. Microsoft documenta verificación OTP para direcciones nuevas de grupos de acciones. Se solicitó al usuario revisar Verify/Resend y Spam; la verificación personal no debe automatizarse con códigos compartidos.

Se preparó `Test-EmailDelivery.ps1` para una alerta temporal sobre la auditoría real, con eliminación de la regla al finalizar, y se ejecutó una auditoría nueva: `08584092114607428119212552707CU05`, Succeeded. Ambas métricas volvieron a mostrar 2. La entrega al buzón sigue pendiente de confirmación; no se declara resuelta.

Referencia: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups

Eliminar el grupo 05 no elimina los objetos Entra ni la VM reutilizada. Revisar la sección de retiro en README antes de eliminar dependencias. El PFX sintético permanece en `.local`, excluido de Git.

La prueba normal terminó con EMAIL_DELIVERY_ALERT_FIRED (alerta d1c4971d-616f-4634-acb1-d8ee3a9af000). La regla temporal se retiró al finalizar. Esto confirma la evaluación de Azure Monitor; la recepción de correo sigue pendiente.
