$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "COMPACT-WSL2-DISK" -ForegroundColor Yellow
Write-Host ""

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Write-Host "Opening elevated shell... " -ForegroundColor Yellow
	Write-Host ""
	# Start-Process PowerShell "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$PWD'; & '$($MyInvocation.MyCommand.Definition)';`""" -Verb RunAs
	Start-Process PowerShell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

$files = Get-ChildItem -Path $env:LOCALAPPDATA\Packages,$env:LOCALAPPDATA\Docker -Recurse -Filter "ext4.vhdx" -ErrorAction SilentlyContinue
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
	Write-Host "Disk to compact: $disk" -ForegroundColor Yellow
	Write-Host "Length: $($file.Length/1MB) MB" -ForegroundColor Yellow
	Write-Host "Compacting disk (starting diskpart)..." -ForegroundColor Yellow

	@"
select vdisk file="$disk"
attach vdisk readonly
compact vdisk
detach vdisk
exit
"@ | diskpart

	Write-Host "Success. Compacted $disk." -ForegroundColor Yellow
	Write-Host "New length: $((Get-Item $disk).Length/1MB) MB" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Compacting of $($files.count) file(s) complete." -ForegroundColor Yellow

pause
