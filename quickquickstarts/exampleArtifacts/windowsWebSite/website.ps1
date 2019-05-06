# Install IIS Website
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Setup directory
New-Item C:\ImageBuilderWebApp -type Directory

Set-Content C:\ImageBuilderWebApp\Default.htm "ImageBuilderWebApp Default Page"

New-Item IIS:\Sites\ImageBuilderWebApp -PhysicalPath C:\ImageBuilderWebApp -bindings @{protocol="http";bindingInformation=":8080:"}
