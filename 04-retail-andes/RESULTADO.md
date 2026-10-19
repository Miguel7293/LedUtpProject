# Resultado de Retail Andes

Verificado el 18 de octubre de 2026, America/Lima.

## Recursos

- Grupo: `rg-leadutp-04-dev`, Brazil South.
- Data Factory: `adf-retail-57cyqpixoehss`.
- Lake: `stretail57cyqpixoehss`, HNS habilitado, contenedores Bronze/Silver privados.
- Claves compartidas y acceso anónimo a blobs: deshabilitados.
- ADF utiliza identidad administrada; sin contraseñas SQL ni claves de Storage.
- Presupuesto `budget-retail-andes`: USD 10 mensuales, avisos al 80% y 100% al correo del usuario. No detiene recursos.
- SQL compartido: `sqldb-leadutp` del grupo 01; su modalidad gratuita permanece.

## Resultados reales

| Ejecución | Run ID | Filas |
| --- | --- | --- |
| Primera carga | c2b5f5d1-7fd1-419e-b3d1-f3b358888a15 | 847 clientes, 295 productos y 3 ventas |
| Incremental tras cambios | 0488aba4-3f28-41b1-a33d-414aa4c1cef1 | 2 ventas: una actualizada y una nueva |
| Incremental sin cambios | 51793669-a71a-4801-b121-53a86d9715a2 | 0 ventas |

Los tres pipelines terminaron en Succeeded. Los Parquet de la primera y segunda carga se descargaron y leyeron con PyArrow; sus conteos coinciden con ADF.

`Invoke-Sql.ps1 -Action Verify` confirmó:

- Secuencia de ventas copiadas: 3 → 2 → 0.
- Checkpoint idéntico entre segunda y tercera ejecución.
- Cuatro ventas finales en SQL.
- Repetir Commit del primer run no duplica su historial ni retrocede el checkpoint.
- Resultado: `RETAIL_HISTORY_TEST_PASS`.

## PySpark y Silver

Spark 4.0.1 se ejecutó localmente en un contenedor Docker sobre los Parquet reales descargados. Conservó la versión más reciente de cada venta y calculó importes con decimal.

- Primera carga: 3 ventas, PEN 317.30.
- Consolidación de primera e incremental: 4 ventas, PEN 472.20.
- Archivo consolidado publicado en `abfss://silver@stretail57cyqpixoehss.dfs.core.windows.net/Sales/run_id=0488aba4-3f28-41b1-a33d-414aa4c1cef1/`.
- Silver se volvió a descargar de Azure y verificar con PyArrow: 4 SaleId únicos, importe bruto PEN 472.20.

## Estado final y límites

Las reglas temporales SQL se retiraron; la consulta final de reglas devolvió una lista vacía. No hay triggers recurrentes ni clúster Databricks activo. ADF y Storage tienen costos por actividad, operaciones y almacenamiento. No se verificó el crédito restante Students.

El watermark de tiempo es una demostración sin escritores concurrentes: no captura eliminaciones ni garantiza transacciones tardías. Los consumidores deben usar solo cargas confirmadas. Para producción se requiere revisar CDC/Change Tracking, consistencia, reintentos y conectividad privada.

## Pendientes avanzados del estado inicial (resueltos en el cierre)

- `notebooks/RetailAndes.py` está preparado para Databricks, pero no se creó workspace ni se ejecutó el notebook allí. La validación descrita es PySpark local; el notebook remoto escribe Delta y requiere Unity Catalog/external location con acceso al lake.
- Integración ADF → Databricks y credenciales mediante Key Vault pendientes. La ingesta validada usa identidad administrada y no necesita esos secretos.

## Ampliación remota del 19 de octubre de 2026

- Workspace `dbw-retail-andes`, Premium, Brazil South: Succeeded. URL `https://adb-7405618636834329.9.azuredatabricks.net`. Grupo administrado `rg-retail-databricks-managed`, con almacenamiento, NAT Gateway e IP pública: pueden cobrar aun sin clúster activo.
- Access Connector `ac-retail-andes`, identidad de usuario `id-retail-databricks-lake` y Key Vault `kv-retail-andes-7293` desplegados. Permisos de datos limitados a contenedores Bronze/Silver y lector de secretos para ADF.
- Pipeline ADF `Retail_ValidateKeyVault`, run `3adc7532-59d9-417a-b8fa-c389fabf6e94`: Succeeded. Leyó la configuración sintética `silver-expected-sales` desde Key Vault con MSI y verificó su valor. No se guardaron contraseñas SQL/Storage: la autenticación sigue usando identidades administradas.
- La lectura de Key Vault por ADF está probada; no equivale a haber ejecutado aún el notebook remoto. Los detalles finales de Databricks se registrarán después de la comprobación de cómputo y acceso UC.
- Credencial real desde Key Vault: `Retail_ValidateKeyVaultCredential`, run `e0001cd0-9ebc-40b4-8aaf-b9e09827afe9`. `ReadPrivateBlob` Succeeded, `exists=true`, tamaño 68 bytes. Usó SAS de delegación de usuario guardada en `demo-read-sas`, referenciada como AzureKeyVaultSecret; lectura/listado solo del contenedor ficticio `credentials-demo`, vencimiento de una hora. No se habilitaron claves compartidas ni SQL passwords.

## Cierre remoto aprobado

- Pipeline `Retail_DatabricksSilver`, run `a2278020-fdfa-4d86-9782-bebd05482559`: Succeeded. Actividades `ReadSilverPolicy` y `BronzeToSilver` aprobadas. La política esperada se leyó desde Key Vault y el notebook se ejecutó con la identidad de ADF.
- [Ejecución Databricks 770877848812661](https://adb-7405618636834329.9.azuredatabricks.net/?o=7405618636834329#job/967923417775110/run/770877848812661): escritura y relectura Delta aprobadas, cuatro ventas e importe PEN 472.20. Marcador `RETAIL_DATABRICKS_PASS`.
- Destino: `abfss://silver@stretail57cyqpixoehss.dfs.core.windows.net/SalesDelta/run_id=0488aba4-3f28-41b1-a33d-414aa4c1cef1`. El Parquet Silver local anterior permanece en su ruta separada.
- Clúster `1019-071138-56vwmfmh`: Runtime 16.4 LTS, un nodo Standard_D4ds_v4, asignado a la identidad ADF. Terminación manual solicitada después de la prueba y estado `TERMINATED` comprobado. Terminación por inactividad adicional: diez minutos.
- Se resolvieron problemas de sincronización de identidad, propiedad UC y permisos de delegación. La primera familia de VM no tenía capacidad; se cambió a D4ds_v4. Un primer notebook falló por falta de Storage Blob Delegator; se añadió el permiso de emitir credenciales temporales en la cuenta, manteniendo acceso a datos limitado a Bronze/Silver. No se modificaron los datos fuente para obtener el resultado esperado.
- Aplicaciones Entra temporales retiradas, principales temporales de Databricks deshabilitados y credencial UC redundante eliminada. Objetos UC definitivos a cargo del usuario.
- Presupuesto adicional `budget-retail-andes-total`, mensual 10 con avisos 80%/100%, filtrado a grupo 04 y su grupo administrado. Despliegue Succeeded. No detiene consumo; el presupuesto previo del grupo 04 se conserva.
- Evidencia JSON local: `.local/databricks-result.json`. No hay triggers recurrentes nuevos. El costo acumulado y el crédito restante todavía no se han confirmado.
