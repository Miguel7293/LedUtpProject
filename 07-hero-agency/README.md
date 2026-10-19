# Hero Agency

## Retiro de recursos de Azure — 19 de octubre de 2026

El propietario autorizó eliminar los recursos de Azure de este laboratorio para detener futuros cargos. Se verificó la eliminación de su grupo de recursos y de todos los recursos del laboratorio; las pruebas y direcciones descritas abajo documentan el funcionamiento anterior y no garantizan que los servicios sigan disponibles. Se conservan código, infraestructura y evidencias. Los despliegues de GitHub Actions y Azure Pipelines se deshabilitaron para impedir la recreación automática.

Los respaldos de archivos y datos de demostración se guardan únicamente en `.local/retirada-2026-10-19/` en la raíz del workspace, excluida de Git. No es un respaldo completo de máquinas, imágenes o base SQL: se conservan scripts de inicialización, datos Bronze/Silver, documentos, reportes y votos de demostración. Las contraseñas, secretos e identidades administradas no se restauran desde esos respaldos. Para volver a publicar, revisar los scripts y los costos antes de desplegar.

## Descripción de lo realizado

**Objetivo:** llevar una demo de votación desde código hasta staging y producción con controles de ramas.

La aplicación usa Node.js 24 y Express 5. Localmente guarda votos en memoria; en Azure los conserva en Table Storage. Staging y producción usan tablas e identidades diferentes. Las cookies tienen identificadores opacos y solo su hash se guarda como clave. Repetir un voto es idempotente y cambiarlo devuelve 409. No es un sistema electoral: borrar cookies permite volver a votar.

Azure Pipelines ejecuta cinco etapas: Build, Test, Policies, Staging y Production. La promoción usa el mismo digest de imagen y verifica disponibilidad. Se comprobó que los votos persistieran tras el despliegue. La validación automática del PR también aprobó, sin desplegar desde la rama del PR.

**Uso:** `07-hero-agency/scripts/Test-Local.ps1`, `Test-Azure.ps1` e `Inspect-Pipeline.ps1`. Local: puerto 18070. La opción `-Vote` de la prueba remota agrega votos ficticios.

**Pendiente humano:** aprobar y fusionar el PR de Azure Repos exige otro revisor. La política excluye al autor; no se realizó bypass ni se simuló una aprobación.

Demo de votación Node.js 24 / Express 5, con interfaz web, Docker y Azure Pipelines en cinco etapas. Cada entorno usa su propia tabla privada de Azure Storage y una identidad administrada con permisos solo en esa tabla. No hay claves de Storage en el código.

## Ejecutar y probar

Desde la raíz LeadUTP:

```powershell
./07-hero-agency/scripts/Test-Local.ps1
# Abrir http://localhost:18070
./07-hero-agency/scripts/Test-Azure.ps1
# Prueba de escritura real: agrega un voto ficticio por entorno
./07-hero-agency/scripts/Test-Azure.ps1 -Vote
```

El modo local guarda votos en memoria. En Azure se usa Table Storage, con persistencia independiente del contenedor. Cada cookie de navegador tiene un identificador aleatorio; solo su hash se guarda como clave de voto. Repetir el mismo voto es idempotente; intentar cambiarlo devuelve 409. Borrar cookies permite volver a votar: es una demo educativa, sin autenticación de personas ni garantías electorales. Los resultados consultan los votos existentes: para grandes volúmenes se necesitan agregados y protección contra abuso adicional.

## Azure

Grupo: rg-leadutp-07-dev, Brazil South. Staging y producción tienen identidades, cookies por dominio y tablas separadas. Container Apps usa HTTPS y escala 0–1; ACR se reutiliza del proyecto 02. La imagen se despliega por digest. La imagen base Node 24 y las dependencias npm están fijadas con digest/lockfile.

```powershell
./07-hero-agency/scripts/Deploy-Azure.ps1 -Deploy -Build
# Para revisar después, sin aplicar
./07-hero-agency/scripts/Deploy-Azure.ps1
```

En otro equipo indicar -ContactEmail o AZURE_ALERT_EMAIL para el presupuesto. En este equipo el correo autorizado está en .local/settings.json, ignorado por Git. Presupuesto mensual 10 unidades y alertas 80/100%; no apaga recursos. Container Apps, almacenamiento, transacciones y ACR pueden generar consumo. Saldo Students sin verificar.

## Azure Pipelines

Organización: https://dev.azure.com/miguel7293-leadutp ; proyecto LeadUTP; repositorio HeroAgency. La carpeta 07-hero-agency se mantiene dentro de la raíz del repositorio. YAML: 07-hero-agency/azure-pipelines.yml.

1. Build: genera imágenes runtime y test, guarda ambas como artefacto.
2. Test: descarga las mismas imágenes y ejecuta pruebas automatizadas.
3. Policies: consulta las políticas reales de main en Azure Repos; exige revisor obligatorio y validación de este pipeline. No simula una aprobación de PR.
4. Staging: publica la imagen probada en ACR, despliega por digest y comprueba disponibilidad con acceso real a Table Storage.
5. Production: promueve el mismo digest y vuelve a comprobar disponibilidad.

Los despliegues solo corren sobre main con el parámetro deploy=true. Los PR ejecutan validación mediante la política de Build Validation, no mediante el trigger pr del YAML. La conexión sc-hero07-deploy utiliza federación de identidad, sin contraseña. El bootstrap de infraestructura se realiza con Deploy-Azure.ps1; el pipeline actualiza únicamente imágenes de apps existentes.

Consultar RESULTADO.md para los recursos, políticas y ejecuciones efectivamente verificadas. Un YAML preparado no significa que las cinco etapas ya se hayan ejecutado.

## Limpieza

Eliminar solo rg-leadutp-07-dev cuando no se necesite; retirar sus asignaciones de identidad en el ACR, conexión federada y recursos de Pipelines del laboratorio. No eliminar el ACR compartido del grupo 02. Para detener local: docker compose -f 07-hero-agency/compose.yml down.

### Recursos de DevOps

[Pipeline](https://dev.azure.com/miguel7293-leadutp/LeadUTP/_build?definitionId=1) · [Ejecución inicial](https://dev.azure.com/miguel7293-leadutp/LeadUTP/_build/results?buildId=1) · [PR de revisión](https://dev.azure.com/miguel7293-leadutp/LeadUTP/_git/HeroAgency/pullrequest/1).

Las políticas de main son bloqueantes: un revisor distinto del autor y Build Validation del pipeline 1. El PR de revisión está publicado, con Build Validation aprobada; no fue aprobado por una persona ni fusionado. Los environments no tienen aprobación humana adicional de despliegue. La conexión federada está autorizada únicamente para el pipeline HeroAgency.

Para consultar etapas: `./07-hero-agency/scripts/Inspect-Pipeline.ps1`. Las colas de agentes hospedados pueden demorar entre etapas; no se contrató capacidad adicional.
