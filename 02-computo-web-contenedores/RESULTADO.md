# Resultado del bloque 02

## Retiro de recursos de Azure — 19 de octubre de 2026

El propietario autorizó eliminar los recursos de Azure de este laboratorio para detener futuros cargos. Se verificó la eliminación de su grupo de recursos y de todos los recursos del laboratorio; las pruebas y direcciones descritas abajo documentan el funcionamiento anterior y no garantizan que los servicios sigan disponibles. Se conservan código, infraestructura y evidencias. Los despliegues de GitHub Actions y Azure Pipelines se deshabilitaron para impedir la recreación automática.

Los respaldos de archivos y datos de demostración se guardan únicamente en `.local/retirada-2026-10-19/` en la raíz del workspace, excluida de Git. No es un respaldo completo de máquinas, imágenes o base SQL: se conservan scripts de inicialización, datos Bronze/Silver, documentos, reportes y votos de demostración. Las contraseñas, secretos e identidades administradas no se restauran desde esos respaldos. Para volver a publicar, revisar los scripts y los costos antes de desplegar.

Trabajo realizado el 18 de octubre de 2026, America/Lima.

## Aplicaciones

- API Python/FastAPI con listado, consulta individual, 404 y validación de identificador.
- Web .NET 10 que sirve HTML y consulta la API desde el servidor.
- Catálogo ficticio de tres productos en PEN; no conectado a SQL ni a pagos.
- Docker Compose con puertos locales 18080 y 18000.
- Versiones de dependencias Python fijadas para alinear ejecución local y Docker.

## Validación realizada

- Compilación .NET Release: correcta, sin advertencias ni errores.
- Pruebas Python: 2 aprobadas; cubren contrato, consulta de producto, 404 y entrada no válida.
- Docker: ambas imágenes construidas y ambos contenedores iniciados correctamente.
- Prueba HTTP local: ambos endpoints de salud, HTML, catálogo a través de .NET y producto inexistente correctos.
- Bicep: las cuatro plantillas compilan.
- Scripts PowerShell: análisis sintáctico correcto.
- Prueba con API detenida: no ejecutada; revisión automática bloqueó la operación de detención temporal.

## Azure

- Grupo independiente: `rg-leadutp-02-dev` en Brazil South.
- Registro privado Basic: `acrleadutpjmas5j6rizpu4`, imagen `leadutp02-api:v1` publicada.
- Identidad: `id-leadutp02-pull`, rol AcrPull limitado al registro.
- Container Apps: entorno `cae-leadutp02`, aplicación `ca-leadutp02-api`, escala 0–2 réplicas.
- API: https://ca-leadutp02-api.whitesea-c86c9ca6.brazilsouth.azurecontainerapps.io
- API remota verificada: salud correcta, 3 productos, moneda PEN, entorno azure.
- App Service: `web-leadutp02-jmas5j6rizpu4`, plan F1 gratuito creado.
- Web: https://web-leadutp02-jmas5j6rizpu4.azurewebsites.net
- Publicación ZIP finalizada correctamente. Prueba remota de web y API aprobada: ambos endpoints de salud, catálogo remoto con tres productos y entorno azure, y HTML del catálogo servido por .NET.
- Presupuesto de este grupo: mensual de USD 10, avisos al 80% y 100%, correo del usuario. No detiene recursos.

## Costos y pendientes

ACR Basic tiene un precio de referencia observado en la API pública de tarifas de Azure de unos USD 0.17/día para Brazil South, más conceptos adicionales aplicables. No se verificó el crédito restante Students. Container Apps puede cobrar uso fuera de franquicias. El plan web es F1.

No se desplegaron VM. Hay una plantilla Linux con IP privada y autenticación por clave; la variante Windows queda pendiente. El dominio personalizado y la ejecución del workflow GitHub requieren dominio/plan compatible y conexión de repositorio, respectivamente. El archivo de GitHub Actions está preparado, sin ejecución remota.

El laboratorio posterior `03-redes-seguridad` sí despliega y prueba dos VM Linux, cubriendo el ejercicio de aprovisionamiento Linux y redes sin duplicar esos recursos en el grupo 02. La variante Windows permanece pendiente.

## Cierre del 19 de octubre de 2026

- Windows Server 2022 Datacenter desplegado en `vm-leadutp02-win`, Central US, Standard_D2s_v3. Sin IP pública; NSG deniega entrada. Dos intentos de comprobación: el primero falló por comillas del script transmitido; se corrigió usando archivo. Segundo: `WINDOWS_VM_TEST_PASS` y sistema operativo comprobado dentro del huésped.
- VM desasignada y estado consultado: `VM deallocated`. Sigue existiendo disco de sistema con costo. La contraseña aleatoria de creación no se publicó y el archivo temporal fue retirado; si se necesita sesión administrativa, restablecerla de forma controlada.
- GitHub Actions [39212010688](https://github.com/Miguel7293/LedUtpProject/actions/runs/39212010688): success. Compilación .NET 10, acceso OIDC, publicación App Service y comprobación remota del catálogo aprobados. Identidad `id-web02-github`, Website Contributor solo sobre la web; environment azure-web02.
- Workflow efectivo: `devops/web02-completo.yml`, publicado como `.github/workflows/web02.yml` en la rama del PR GitHub existente. El archivo anterior `web-deploy.yml` es una plantilla histórica, no el workflow ejecutado.
- El usuario confirmó que no tiene dominio propio. Se mantiene el dominio azurewebsites.net; el ejercicio de DNS propio queda como dependencia externa.
