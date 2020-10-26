Write-Host 'v2 Start of mitigation sysprep for 26th October sysprep issue, this **must** not be used past mid November'
$myApp=Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name Like '%Windows Azure VM Agent%'"

$MyApp.Uninstall() 
Write-Host "stop service - to stop auto uopdate until image create"
Get-Service -DisplayName "RdAgent" | Stop-Service 

Write-Host "End of mitigation"



