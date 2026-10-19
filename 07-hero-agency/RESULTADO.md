# Evidencias de Hero Agency

- Cinco pruebas automatizadas aprobadas en Docker con Node.js 24.22.0.
- Prueba HTTP local aprobada: creación, repetición idempotente y cambio denegado; interfaz revisada visualmente.
- Grupo rg-leadutp-07-dev y despliegue hero07 Succeeded.
- Storage privado sthero07cfk5fa3gxboi6, Shared Key desactivado; tablas votesstaging y votesproduction.
- Staging: https://ca-hero07-staging.livelywater-a238d1e3.brazilsouth.azurecontainerapps.io
- Producción: https://ca-hero07-production.livelywater-a238d1e3.brazilsouth.azurecontainerapps.io
- Ambos entornos aprobaron HERO_HEALTH_PASS y VOTO_REAL_PASS con acceso real a Table Storage mediante managed identity; se agregó un voto sintético por entorno durante la prueba.
- Imagen inicial: acrleadutpjmas5j6rizpu4.azurecr.io/hero-agency@sha256:c311b66c3c0740fc1a3154edd325818d7ce16e332e0f5cbee76bb9eecd1521ec.
- Presupuesto budget-leadutp-07 y escala mínima cero configurados.
- Azure DevOps: proyecto LeadUTP y repositorio HeroAgency configurados; ejecución manual 1 aprobada en las cinco etapas.

## Configuración de Azure DevOps verificada

- Organización miguel7293-leadutp / proyecto LeadUTP (4343c1f0-016e-415a-8297-2010e3623b58).
- Repositorio HeroAgency (2e2a7def-8cc1-46df-baeb-fc71ab7a886d), código inicial en main: 825f19c4a8222b40f1065661dd45a817df17cce2.
- [Pipeline HeroAgency, ejecución 1](https://dev.azure.com/miguel7293-leadutp/LeadUTP/_build/results?buildId=1), iniciado con deploy=true.
- [PR 1 de revisión](https://dev.azure.com/miguel7293-leadutp/LeadUTP/_git/HeroAgency/pullrequest/1), rama codex/hero07-review, publicado y sin fusionar. La ejecución 2 se disparó automáticamente con reason=pullRequest.
- Política 1: mínimo un revisor, autor no cuenta; bloqueante. Política 2: Build Validation del pipeline 1, bloqueante y automática al actualizar un PR publicado.
- Environments hero-staging (1) y hero-production (2), creados. No se añadieron aprobaciones humanas de despliegue.
- Conexión sc-hero07-deploy (15b9f38f-5f60-43f8-a1f6-0f9abfc54840), WIF usando issuer/subject exactos devueltos por Azure DevOps, sin contraseña. Autorizada explícitamente para el pipeline 1.
- Identidad id-hero07-pipelines: Contributor solo en las dos Container Apps, Reader en grupo 07 para consultar configuración, AcrPush solo en ACR compartido. Las identidades de aplicación mantienen acceso solo a su tabla.
- Ejecución 1: Build, Test, Policies, Staging y Production aprobadas. Ejecución 2 del PR: Build, Test y Policies aprobadas; Staging y Production omitidas por la condición de rama. La validación automática del PR terminó correctamente.

Consulta del estado:

```powershell
./07-hero-agency/scripts/Inspect-Pipeline.ps1
```

El PR incluye la migración de NodeTool@0 a UseNode@1 y el script Inspect-Pipeline.ps1. La política de revisión exige otra persona: el autor no puede aprobar su propio PR. No se realizó bypass ni fusión.


## Promoción y persistencia verificadas

Las dos apps ejecutan el mismo digest `sha256:fcdb78c20f6785c973dd832c3af700515312926817ba6f8cf5d868a549951900`. Ambas conservan el voto previo al despliegue (total=1 en cada tabla) y minReplicas=0. Marcador de verificación: PROMOTION_AND_PERSISTENCE_PASS.

La ejecución 1 validó el código inicial 825f19c4a8222b40f1065661dd45a817df17cce2. El PR incluye la actualización de UseNode@1 y documentación; no está fusionado. La configuración final no depende de contraseñas de servicio ni de claves de Storage.

[Validación automática del PR, ejecución 2](https://dev.azure.com/miguel7293-leadutp/LeadUTP/_build/results?buildId=2): succeeded, código de la rama 358962f3d30ad33199b79bc5bf7c8e8464f85835. El PR sigue publicado, sin aprobación humana ni fusión. La evidencia final se conserva en este informe local y en los registros de ambas ejecuciones; el código validado del PR no se modificó después de las pruebas.
