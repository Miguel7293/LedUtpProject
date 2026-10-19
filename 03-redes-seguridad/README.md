# Redes y seguridad

## Diseño del laboratorio

VNet01: `10.30.0.0/16`, con dos subredes:

Configuración elegida: Central US, dos VM `Standard_B2pts_v2` ARM64 con Ubuntu 24.04. El grupo conserva metadatos en Brazil South; los recursos de red y cómputo se alojan en Central US. Se reutiliza el Network Watcher existente en esa región. La elección se validó contra las restricciones de la suscripción Students.

| VM | Subred | IP privada | Entrada permitida |
| --- | --- | --- | --- |
| VM01 | frontend: 10.30.1.0/24 | 10.30.1.4 | SSH 22 y web 80/443, únicamente desde la IP del PC |
| VM02 | backend: 10.30.2.0/24 | 10.30.2.4 | Web 80/443, únicamente desde la IP privada de VM01 |

Ambas tienen IP pública Standard para salida explícita a Internet sin NAT Gateway. VM02 no acepta conexiones públicas entrantes. Las IP públicas no convierten a las subredes en una red sin segmentación: la entrada queda controlada por NSG.

Los NSG incluyen una denegación de entrada desde VirtualNetwork con prioridad 4000 para anular el permiso predeterminado entre VM. La excepción HTTP/HTTPS tiene prioridad 100. También se bloquea salida TCP 3389 hacia Internet; el resto de las reglas predeterminadas de salida permanece.

Las VM Ubuntu 24.04 arrancan un servidor HTTP en el puerto 80 mediante cloud-init, Python y systemd. El puerto 443 está permitido por política, pero no se configura un servicio TLS: la prueba de 443 evalúa reglas NSG, no una conexión HTTPS funcional.

## Despliegue

Desde la raíz LeadUTP:

```powershell
./03-redes-seguridad/scripts/Deploy.ps1 -Mode Validate
./03-redes-seguridad/scripts/Deploy.ps1 -Mode WhatIf
./03-redes-seguridad/scripts/Deploy.ps1 -Mode Deploy
```

Elegir región y tamaño con disponibilidad y cuota confirmadas. El script comprueba la suscripción, genera una clave SSH Ed25519 en `.local` (excluida de Git) y autoriza la IP pública actual del PC. Nunca compartir la clave privada. Si cambia tu IP pública, revisar las reglas NSG.

Si se cambia a un tamaño x64, también se debe indicar `-ImageSku server`; el tamaño predeterminado utiliza `server-arm64`.

## Pruebas

```powershell
./03-redes-seguridad/scripts/Test-Network.ps1
```

Usa Azure Run Command para comprobar que VM01 accede por HTTP a VM02 y que las conexiones TCP 22/3389 agotan el tiempo de espera. Network Watcher verifica por separado Allow en 80/443 y Deny en 22/3389. También se evalúa Deny en la salida RDP hacia Internet. La simulación de reglas no sustituye la prueba HTTP real.

## Control de costos

```powershell
./03-redes-seguridad/scripts/Set-PowerState.ps1 -Action Deallocate
az vm list -g rg-leadutp-03-dev -d -o table
```

Desasignar detiene el costo de cómputo; los discos e IP públicas siguen generando cargos. El presupuesto avisa, no detiene el consumo. Para retirar todo el laboratorio, revisar y eliminar exclusivamente `rg-leadutp-03-dev`. Eso elimina VM, discos y claves instaladas en ellas; conservar la clave local no recupera sus datos.

Para volver a practicar: ejecutar Set-PowerState con `-Action Start`, esperar que ambas estén Running y repetir Test-Network. La clave local se conserva hasta que decidas retirarla.

## Referencias

- [Reglas y prioridades NSG](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Estados y facturación de VM](https://learn.microsoft.com/en-us/azure/virtual-machines/states-billing)
