# Using PowerShell to Create a Windows Virtual Desktop Custom Image using Azure VM Image Builder

NOTE!! This is still under development, and not complete!

This article is to show you how you can create a basic WVD customized image with these customizations:

* Installing [FsLogix](https://github.com/DeanCefola/Azure-WVD/blob/master/PowerShell/FSLogixSetup.ps1)
* Running a [WVD Optimzation script](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool) from the WVD team
* Installing a LOB App, [MS Teams](https://docs.microsoft.com/en-us/azure/virtual-desktop/teams-on-wvd)
* [Windows Restart](https://docs.microsoft.com/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#windows-restart-customizer)
* [Windows Update](https://docs.microsoft.com/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#windows-update-customizer)

We will show you how to automate this using the Azure VM Image Builder, and distibute to the Azure [Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries), where you can replicate regions, control the scale, and share inside and outside your organizations.


To simplify deploying an AIB configuration template with PowerShell CLI, this example uses an Azure Resource Manager (ARM) template with the AIB template nested inside, and gives you other benefits for free, such as variables and parameter inputs etc. You can also pass parameters from the commandline too, which you will see here.

This walk through is intended to be a copy and paste exercise, and will provide you with a custom Win Server image (AIB also supports client images), showing you how you can easily create a custom image.

> Note! 
The scripts to install the apps are located in this repo, note, they are for illustration and testing ONLY, and **NOT** production. 

## Building Windows Images with AIB Notes:
1. VM Size - When AIB runs, it uses a build VM to build the image, the default AIB size (Standard_D1_v2) is not suitable. Use Standard_D2_v2 or greater.
2. The example here uses the AIB [PowerShell customerizer scripts](https://docs.microsoft.com/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#powershell-customizer), you will need to run these with the settings below. If you do not, the build will hang.
```text
  "runElevated": true,
  "runAsSystem": true,
```
For example:
```json
  {
      "type": "PowerShell",
      "name": "installFsLogix",
      "runElevated": true,
      "runAsSystem": true,
      "scriptUri": "https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/14_Building_Images_WVD/0_installConfFsLogix.ps1"
```
3. Comment your code

The AIB build log (customization.log) is extremely verbose, if you comment your scripts using 'write-host' these will be sent to the logs, and make troubleshooting easier.

```PowerShell
 write-host 'AIB Customization: Starting OS Optimizations script'
```

4. Networking: Set-NetAdapterAdvancedProperty 

This is being set in the optimization script, but fails the AIB build, as it disconnects the network, this is commented out. It is under investigation.

## PreReqs
You must have the latest Azure PowerShell CmdLets installed, see [here](https://docs.microsoft.com/en-us/powershell/azure/overview?view=azps-2.6.0) for install details.

```PowerShell
# Register for Azure Image Builder Feature
Register-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages
# wait until RegistrationState is set to 'Registered'

# check you are registered for the providers, ensure RegistrationState is set to 'Registered'.
Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Get-AzResourceProvider -ProviderNamespace Microsoft.Storage 
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute
Get-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

# If they do not saw registered, run the commented out code below.

## Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
## Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
## Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
## Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault
```

## Step 1: Set up environment and variables

```powerShell
# Step 1: Import module
Import-Module Az.Accounts

# Step 2: get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup="wvdImageDemoRg"

# location (see possible locations in main docs)
$location="westus2"

# your subscription, this will get your current subscription
$subscriptionID=$currentAzContext.Subscription.Id

# image template name
$imageTemplateName="wvd10ImageTemplate01"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName="sigOutput"

# create resource group
New-AzResourceGroup -Name $imageResourceGroup -Location $location
```

## Step 2 : Permissions, create user idenity and role for AIB

### Create user identity
```powerShell
# setup role def names, these need to be unique
$timeInt=$(get-date -UFormat "%s")
$imageRoleDefName="Azure Image Builder Image Def"+$timeInt
$idenityName="aibIdentity"+$timeInt

## Add AZ PS modules to support AzUserAssignedIdentity and Az AIB
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName

$idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId

```

### Assign permissions for identity to distribute images
This command will download and update the template with the parameters specified earlier.
```powerShell
$aibRoleImageCreationUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# download config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting


```

## Step 3 : Create the Shared Image Gallery 

```powerShell
$sigGalleryName= "myaibsig01"
$imageDefName ="win10wvd"

# create gallery
New-AzGallery -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup  -Location $location

# create gallery definition
New-AzGalleryImageDefinition -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup -Location $location -Name $imageDefName -OsState generalized -OsType Windows -Publisher 'myCo' -Offer 'Windows' -Sku '10wvd'

```

# Configure the Image Template
This command will download and update the template with the parameters specified earlier.

You can also change the Win10 image:
```powerShell
Get-AzVMImageSku -Location westeurope -PublisherName MicrosoftWindowsDesktop -Offer windows-10
```


```powerShell

$templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/14_Building_Images_WVD/armTemplateWVD.json"
$templateFilePath = "armTemplateWVD.json"

Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath

((Get-Content -path $templateFilePath -Raw) -replace '<imageDefName>',$imageDefName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<sharedImageGalName>',$sigGalleryName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region1>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$idenityNameResourceId) | Set-Content -Path $templateFilePath

```


# Submit the template
Your template must be submitted to the service, this will download any dependent artifacts (scripts etc), validate, check permissions, and store them in the staging Resource Group, prefixed, *IT_*.
```powerShell
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2020-02-14" -imageTemplateName $imageTemplateName -svclocation $location
```
 
# Build the image
```powerShell
Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName -NoWait

```

>> Note, the command will not wait for the image builder service to complete the image build, you can query the status below.

```powerShell
Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName 
```
## Create a VM
Now the build is finished you can build a VM from the image, use the examples from [here](https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-2.5.0#examples).

# Clean Up

Delete the resource group template first, do not just delete the entire resource group, otherwise the staging resource group (*IT_*) used by AIB will not be cleaned up.

### Remove Image Template
```powerShell
Remove-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name wvd10ImageTemplate
```
### Delete role assignment
```powerShell
Remove-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

## remove definitions
Remove-AzRoleDefinition -Name "$idenityNamePrincipalId" -Force -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

## delete identity
Remove-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName -Force
```
### Delete Resource Group
```powerShell
Remove-AzResourceGroup $imageResourceGroup -Force
```
## Next Steps
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../quickquickstarts/nextSteps.md)]
