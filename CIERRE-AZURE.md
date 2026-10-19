# Cierre de recursos de Azure — 19 de octubre de 2026

Por autorización del propietario se eliminaron los ocho grupos `rg-leadutp-01-dev` a `rg-leadutp-08-dev` y `rg-retail-databricks-managed`. La consulta final de grupos y recursos confirmó que ninguno permanece. Se retiraron las VM y discos, IP públicas, NAT Gateway, ACR, SQL, Databricks, Storage, Container Apps, App Service, Foundry, Key Vault, Logic App y monitorización de los laboratorios. Se retiró el presupuesto de suscripción `budget-retail-andes-total`.

Los dos workflows GitHub quedaron `disabled_manually` y Azure Pipelines HeroAgency quedó con `queueStatus=disabled`. No se modificaron los recursos ajenos a los laboratorios en Minecraft y NetworkWatcherRG ni el grupo vacío VisualStudioOnline.

Se conservan código, README y resultados históricos. El respaldo local `.local/respaldo-laboratorios-2026-10-19.zip` contiene archivos Bronze/Silver, documentos, reportes, votos sintéticos y evidencia de inventario. No contiene una imagen completa de las VM o SQL; los scripts y datos fuente permiten reconstruir el ejercicio. El respaldo privado no se publica en GitHub.

Las direcciones de Azure documentadas son históricas y dejaron de estar disponibles. Los cargos generados antes de la eliminación pueden reflejarse más tarde; la eliminación no cancela consumo ya realizado. Se conservaron objetos Entra y configuración de repositorios que no representan recursos de cómputo o almacenamiento facturables de los laboratorios.
