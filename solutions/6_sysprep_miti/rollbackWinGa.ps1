 ## download older version of agent
 Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?LinkID=394789 -OutFile guestagent.msi -UseBasicParsing

 ## installs C:\WindowsAzure\Packages_20201026_144227
 Start-Process msiexec.exe -Wait -ArgumentList '/i guestagent.msi /qn /norestart'
 
 ## stop service - to stop auto uopdate until image create
 Get-Service -DisplayName "RdAgent" | Stop-Service 