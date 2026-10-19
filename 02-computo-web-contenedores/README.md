# Cómputo, web y contenedores

## Descripción de lo realizado

**Objetivo:** construir y desplegar una aplicación distribuida sencilla.

Una web .NET 10 sirve el catálogo y consulta una API FastAPI con tres productos ficticios en PEN. Docker Compose permite ejecutar ambos componentes localmente. En Azure, la web usa App Service F1 y la API usa Container Apps, que descarga su imagen desde un ACR privado mediante identidad administrada. Se configuró escalado mínimo cero para la API.

Se añadió una VM Windows Server 2022 en Central US, sin IP pública ni puertos entrantes abiertos. Su sistema operativo se comprobó con Run Command y la VM se desasignó después de la prueba. Las VM Linux se cubren en el proyecto 03.

La publicación desde GitHub Actions compila .NET, autentica mediante OIDC, despliega App Service y comprueba salud y catálogo. Su identidad tiene permiso Website Contributor solo sobre esa web. No utiliza un secreto de publicación permanente.

**Uso:** `02-computo-web-contenedores/scripts/Test-Local.ps1` y `Test-Azure.ps1`. Local: web 18080, API 18000. Azure: `https://web-leadutp02-jmas5j6rizpu4.azurewebsites.net`.

**Pendiente externo:** no hay dominio propio. Se mantiene el dominio de Azure; un dominio personalizado exige disponer del dominio, controlar DNS y comprobar compatibilidad del plan.

Web desplegada y probada: https://web-leadutp02-jmas5j6rizpu4.azurewebsites.net

API desplegada y probada: https://ca-leadutp02-api.whitesea-c86c9ca6.brazilsouth.azurecontainerapps.io/docs

## Aplicación

El cierre añadió Windows Server 2022 sin IP pública, comprobado con Run Command y desasignado al terminar, y publicación real de la web desde GitHub Actions con OIDC. `scripts/Test-WindowsVM.ps1` inicia, comprueba y vuelve a desasignar la VM; genera consumo temporal y el disco sigue facturando. `devops/web02-completo.yml` es el workflow ejecutado; `scripts/Connect-GitHub.ps1` configura su identidad limitada a App Service. No hay dominio propio disponible: se mantiene azurewebsites.net. Ver RESULTADO.md para la evidencia final.

Catálogo ficticio Andes: interfaz web .NET 10 que consulta una API FastAPI. Tres productos en soles, sin pagos ni datos personales. Los datos son de demostración en memoria; no usa la base SQL del proyecto 01.

## Ejecutar en tu PC

Desde la raíz LeadUTP:

```powershell
docker compose -f ./02-computo-web-contenedores/compose.yaml up -d --build --wait
./02-computo-web-contenedores/scripts/Test-Local.ps1
```

- Web: http://localhost:18080
- API interactiva: http://localhost:18000/docs
- Salud: `/health` en ambos servicios.

Los puertos se publican solo en loopback. Se eligieron 18080/18000 porque Windows rechazó el uso del puerto 8080. No se modificaron contenedores de otros proyectos.

## Pruebas Python

```powershell
. ./scripts/Enter-DevEnvironment.ps1
python -m venv ./02-computo-web-contenedores/api/.venv
& ./02-computo-web-contenedores/api/.venv/Scripts/python.exe -m pip install -r ./02-computo-web-contenedores/api/requirements-dev.txt
& ./02-computo-web-contenedores/api/.venv/Scripts/python.exe -m pytest -c ./02-computo-web-contenedores/api/pytest.ini ./02-computo-web-contenedores/api/tests
```

Las dependencias de ejecución están fijadas en `api/requirements.lock.txt`, compartido entre Python local y Docker. Los procesos de ambos contenedores se ejecutan sin root.

## Azure

Grupo dedicado `rg-leadutp-02-dev`, región Brazil South. Preparación inicial: registrar los proveedores Microsoft.Web, Microsoft.App, Microsoft.ContainerRegistry y Microsoft.ManagedIdentity.

```powershell
az group create -n rg-leadutp-02-dev -l brazilsouth --tags project=leadutp-02 environment=dev purpose=learning
./02-computo-web-contenedores/scripts/Deploy-Azure.ps1 -Stage Registry -Deploy
./02-computo-web-contenedores/scripts/Deploy-Azure.ps1 -Stage Api -Deploy
./02-computo-web-contenedores/scripts/Deploy-Azure.ps1 -Stage Web -Deploy
```

Sin `-Deploy`, cada etapa muestra WhatIf. Api y Web requieren que la etapa anterior exista. No ejecutar etapas simultáneamente.

Verificación remota: `./02-computo-web-contenedores/scripts/Test-Azure.ps1`.

- ACR Basic privado, administrador con contraseña deshabilitado. Referencia de tarifa observada: aproximadamente USD 0.17 por día, más almacenamiento excedente o transferencias aplicables. Sigue generando costo aunque no haya tráfico.
- Identidad administrada con rol AcrPull limitado al registro.
- Container Apps: API con HTTPS, 0–2 réplicas, 0.25 vCPU/0.5 GiB y regla HTTP de escalado. La primera petición puede tardar al arrancar desde cero. El consumo fuera de franquicias puede generar cargos.
- App Service Linux F1 gratuito con .NET 10, HTTPS y URL de API como variable de entorno. No se cambia automáticamente a pago si Azure rechaza F1.
- El plan gratuito no cubre el ejercicio de dominio propio. Para ello se necesita un dominio bajo tu control y un plan compatible; queda pendiente.

Se configuró un presupuesto adicional para este grupo: USD 10 por mes, alertas al 80% y 100%, con el correo indicado por el usuario. No suma ni reemplaza el presupuesto del proyecto 01. Como se reutilizó su módulo, el nombre del recurso de presupuesto es `budget-leadutp-01`, dentro de `rg-leadutp-02-dev`.

## GitHub

La plantilla `devops/web-deploy.yml` se copia a `.github/workflows/` al conectar un repositorio. Configurar identidad federada OIDC y las variables indicadas en el archivo. Todavía no se ha creado ni conectado un repositorio remoto ni ejecutado GitHub Actions. La publicación inicial se realiza con Azure CLI.

## VM opcional

`infra/vm.bicep` prepara una VM Ubuntu 24.04 con clave SSH, IP privada y sin IP pública. No abre SSH a Internet. Requiere consultar primero disponibilidad y cuotas de Standard_B1s. Se administra mediante Run Command o una conexión privada autorizada. La VM no se despliega junto a las aplicaciones; genera costos de cómputo y disco. Una VM detenida desde el sistema operativo puede seguir facturando cómputo: desasignar desde Azure al terminar; el disco conserva costo hasta su eliminación. Windows VM queda pendiente de una variante específica.

## Limpieza

Para detener los contenedores locales del laboratorio: `docker compose -f ./02-computo-web-contenedores/compose.yaml down`.

Para Azure, revisar el contenido de `rg-leadutp-02-dev` y eliminar ese grupo al finalizar el laboratorio. No borrar grupos de otros proyectos. Escalar la API a cero no elimina el cargo del registro ACR.
