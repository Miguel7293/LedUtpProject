$ErrorActionPreference = 'Stop'
$guestOS02 = Get-CimInstance Win32_OperatingSystem
if ($guestOS02.Caption -notlike '*Windows Server 2022*') { throw 'Sistema operativo inesperado.' }
Write-Output $guestOS02.Caption
Write-Output 'WINDOWS_VM_TEST_PASS'
