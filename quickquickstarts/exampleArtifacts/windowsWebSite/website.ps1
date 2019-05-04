# Install IIS Website
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Setup directory
New-Item C:\ImageBuilderWebApp -type Directory

Set-Content C:\ImageBuilderWebApp\Default.htm "ImageBuilderWebApp Default Page"

New-Item C:\AppPools\DemoAppPool -type Directory

Import-Module "WebAdministration"

New-Item IIS:\Sites\ImageBuilderWebApp -physicalPath C:\ImageBuilderWebApp -bindings @{protocol="http";bindingInformation=":8080:"} -force
Set-ItemProperty IIS:\Sites\ImageBuilderWebApp -name applicationPool -value DemoAppPool
