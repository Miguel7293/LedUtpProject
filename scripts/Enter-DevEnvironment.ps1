# Dot-source desde PowerShell: . ./scripts/Enter-DevEnvironment.ps1
# Modifica únicamente la sesión actual, sin cambiar el PATH del sistema.
$developmentDirectories = @(
    "$env:LOCALAPPDATA\Programs\Python\Python312",
    "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
    "$env:ProgramFiles\dotnet",
    "$env:ProgramFiles\Microsoft SDKs\Azure\CLI2\wbin"
)
$env:PATH = ($developmentDirectories -join ';') + ';' + $env:PATH
Write-Host 'Entorno de desarrollo activado para esta sesión de PowerShell.'
