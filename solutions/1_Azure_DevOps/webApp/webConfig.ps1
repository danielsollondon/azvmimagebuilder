# Install IIS Website
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Setup directory
New-Item C:\ImageBuilderWebApp -type Directory

# Copy over build artifacts
Copy-Item "C:\buildArtifacts\webApp\*" -Destination "C:\ImageBuilderWebApp" -Recurse
 
# Create site
New-IISSite -Name "ImageBuilderWebApp" -BindingInformation "*:8080:" -PhysicalPath "C:\ImageBuilderWebApp" 

# Open firewall port for 8080
New-NetFirewallRule -DisplayName "Allow Outbound Port 8080" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow

# Clean up buildArtifacts directory
Remove-Item -Path "C:\buildArtifacts\*" -Force -Recurse

# Delete the buildArtifacts directory
Remove-Item -Path "C:\buildArtifacts" -Force 