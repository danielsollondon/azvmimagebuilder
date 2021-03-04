Write-Host 'v3 Start of mitigation sysprep for 26th October sysprep issue, this **must** not be used past mid November'
#disable WinGA services
Set-Service -Name RdAgent -StartupType Disabled
Set-Service -Name WindowsAzureGuestAgent -StartupType Disabled

# remove the registry key for sysprep
$path = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\SysPrepExternal\Generalize"
$generalizeKey = Get-Item -Path $path
$generalizeProperties = $generalizeKey | Select-Object -ExpandProperty property

$values = $generalizeProperties | ForEach-Object {
New-Object psobject -Property @{"Name"=$_;
"Value" = (Get-ItemProperty -Path $path -Name $_).$_}
}

$values | ForEach-Object {
$item = $_;
if( $item.Value.Contains("VMAgentDisabler.dll")) {
Write-HOST "Removing " $item.Name - $item.Value;
Remove-ItemProperty -Path $path -Name $item.Name;
}
}

