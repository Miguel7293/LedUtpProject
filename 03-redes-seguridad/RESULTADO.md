# Resultado del laboratorio de redes

## Retiro de recursos de Azure — 19 de octubre de 2026

El propietario autorizó eliminar los recursos de Azure de este laboratorio para detener futuros cargos. Se verificó la eliminación de su grupo de recursos y de todos los recursos del laboratorio; las pruebas y direcciones descritas abajo documentan el funcionamiento anterior y no garantizan que los servicios sigan disponibles. Se conservan código, infraestructura y evidencias. Los despliegues de GitHub Actions y Azure Pipelines se deshabilitaron para impedir la recreación automática.

Los respaldos de archivos y datos de demostración se guardan únicamente en `.local/retirada-2026-10-19/` en la raíz del workspace, excluida de Git. No es un respaldo completo de máquinas, imágenes o base SQL: se conservan scripts de inicialización, datos Bronze/Silver, documentos, reportes y votos de demostración. Las contraseñas, secretos e identidades administradas no se restauran desde esos respaldos. Para volver a publicar, revisar los scripts y los costos antes de desplegar.

Fecha de trabajo: 18 de octubre de 2026, America/Lima.

## Recursos

- Grupo: `rg-leadutp-03-dev`.
- Recursos de red y VM en Central US. Metadatos del grupo en Brazil South.
- VNet01: 10.30.0.0/16.
- Subred frontend: 10.30.1.0/24; VM01: 10.30.1.4.
- Subred backend: 10.30.2.0/24; VM02: 10.30.2.4.
- VM: Standard_B2pts_v2, Ubuntu 24.04 ARM64.
- IP pública de VM01: 132.196.69.6.
- IP pública de VM02: 52.242.130.76, sin entrada pública permitida.
- Un NSG por subred, con excepción web y denegación explícita del resto de entrada desde VirtualNetwork.
- Network Watcher existente en Central US reutilizado; no se modificó su configuración.
- Presupuesto `budget-leadutp-03`: USD 10/mes, avisos al 80% y 100% al correo del usuario.

## Verificación

- Bicep compila y los scripts PowerShell pasan análisis sintáctico.
- Validación ARM y WhatIf correctos.
- Despliegue de VM, VNet, NSG, interfaces e IP públicas: Succeeded.
- HTTP desde el PC hacia VM01: respuesta JSON, host vm01, estado ok.
- SSH desde el PC hacia VM01 con clave local: correcto; `uname -m` devuelve aarch64.
- HTTP real VM01 → VM02 por IP privada: correcto, respuesta del host vm02.
- Conexiones TCP 22/3389 entre VM: timeout esperado, sin respuesta del destino.
- Network Watcher: Allow en puertos 80/443 por AllowFrontendWeb; Deny en 22/3389 por DenyOtherVnetInbound.
- Network Watcher: salida TCP 3389 hacia Internet denegada por DenyRdpInternetOutbound.
- Estado final consultado en Azure: VM01 y VM02 en `VM deallocated`. No generan cargo de cómputo mientras permanezcan así.

## Costos y límites

Se utilizan recursos de pago. La tarifa pública de referencia observada de la familia Bpsv2 pequeña es del orden de USD 0.01 por VM/hora, antes de beneficios, más discos, IP públicas y otros conceptos aplicables. El precio exacto de facturación depende de tu oferta. El crédito restante Students no se ha verificado. Un presupuesto no detiene el consumo.

Desasignar las VM elimina el cargo de cómputo mientras estén desasignadas, pero los discos e IP públicas siguen facturando. Para eliminar todos los recursos de este laboratorio se debe eliminar exclusivamente su grupo después de revisar su contenido.

443 está permitido por política NSG, pero no hay servicio TLS instalado. No se debe presentar esa comprobación como una prueba HTTPS funcional.
