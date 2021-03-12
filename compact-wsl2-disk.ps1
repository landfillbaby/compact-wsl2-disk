$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "COMPACT-WSL2-DISK" -ForegroundColor Yellow
Write-Host ""

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
	Write-Host "Opening elevated shell... " -ForegroundColor Yellow
	Write-Host ""
	Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
	exit
}


# File is normally under something like C:\Users\onoma\AppData\Local\Packages\CanonicalGroupLimited...
$files = @()
Push-Location $env:LOCALAPPDATA\Packages
Get-ChildItem -Recurse -Filter "ext4.vhdx" -ErrorAction SilentlyContinue | foreach-object {
  $files += ${PSItem}
}

# Docker wsl2 vhdx files
Push-Location $env:LOCALAPPDATA\Docker
Get-ChildItem -Recurse -Filter "ext4.vhdx" -ErrorAction SilentlyContinue | foreach-object {
  $files += ${PSItem}
}

if ( $files.count -eq 0 ) {
  throw "We could not find a file called ext4.vhdx in $env:LOCALAPPDATA\Packages or $env:LOCALAPPDATA\Docker"
}

Write-Host "Found $($files.count) VHDX file(s)" -ForegroundColor Yellow
Write-Host "Shutting down WSL2..." -ForegroundColor Yellow

# See https://github.com/microsoft/WSL/issues/4699#issuecomment-722547552
wsl -e sudo fstrim /
wsl --shutdown

foreach ($file in $files) {

	$disk = $file.FullName
	Write-Host ""
	Write-Host "Compacting '$disk'..."  -ForegroundColor Yellow

	@"
select vdisk file="$disk"
attach vdisk readonly
compact vdisk
detach vdisk
exit
"@ | diskpart

}

Pop-Location
Pop-Location

Write-Host ""
Write-Host "Finished." -ForegroundColor Yellow
Write-Host ""

timeout /t 5