# Using PowerShell to Create a Windows Server Custom Image using Azure VM Image Builder

> **MAY 2020 SERVICE ALERT** - Existing users, please ensure you are compliant this [Service Alert by 26th May!!!](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review)

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, and distibute to the Azure [Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries), where you can replicate regions, control the scale, and share inside and outside your organizations.

This covers using mutliple customizations to illustrate some high level functionality:
* PowerShell (ScriptUri) - Downloading a bash script and executing it
* PowerShell (inline) - Execute an array of commands
* File - Copy a html file from github to a specified, pre-created directory
* buildTimeoutInMinutes - Increase a build time to allow for longer running builds 
* vmProfile - specifying a vmSize and Network properties
* osDiskSizeGB - you can increase the size of image
* WindowsRestart - this will allow for restarts between software installs
* WindowsUpdate - update the image with the latest Windows Updates, note this will handle its own required reboots.

To simplify deploying an AIB configuration template with PowerShell CLI, this example uses an Azure Resource Manager (ARM) template with the AIB template nested inside, and gives you other benefits for free, such as variables and parameter inputs etc. You can also pass parameters from the commandline too, which you will see here.

This walk through is intended to be a copy and paste exercise, and will provide you with a custom Win Server image (AIB also supports client images), showing you how you can easily create a custom image.

>>> Note! Azure Image Builder automatically runs sysprep to generalize the image, this is a generic sysprep command, which you can [overide](https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md#vms-created-from-aib-images-do-not-create-successfully) if you are aware of more favorable settings. However, for *Windows there are limits on how many times (8), an image can be sysprep'd*, see [here](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation#limits-on-how-many-times-you-can-run-sysprep) for more details. Therefore exercise caution on how many times you layer customizations.


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
$imageResourceGroup="aibwinsig01"

# location (see possible locations in main docs)
$location="westus"

# your subscription, this will get your current subscription
$subscriptionID=$currentAzContext.Subscription.Id

# name of the image to be created
$imageName="aibCustomImgWin10"

# image template name
$imageTemplateName="helloImageTemplateWin02ps"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName="winclientR01"

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

## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

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
$imageDefName ="winSvrimages"

# additional replication region
$replRegion2="eastus"

# create gallery
New-AzGallery -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup  -Location $location

# create gallery definition
New-AzGalleryImageDefinition -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup -Location $location -Name $imageDefName -OsState generalized -OsType Windows -Publisher 'myCo' -Offer 'Windows' -Sku 'Win2019'

```

# Configure the Image Template
This command will download and update the template with the parameters specified earlier.
```powerShell

$templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/1_Creating_a_Custom_Win_Shared_Image_Gallery_Image/armTemplateWinSIG.json"
$templateFilePath = "armTemplateWinSIG.json"

Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath

((Get-Content -path $templateFilePath -Raw) -replace '<imageDefName>',$imageDefName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<sharedImageGalName>',$sigGalleryName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region1>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region2>',$replRegion2) | Set-Content -Path $templateFilePath

((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$idenityNameResourceId) | Set-Content -Path $templateFilePath

```


# Submit the template
Your template must be submitted to the service, this will download any dependent artifacts (scripts etc), validate, check permissions, and store them in the staging Resource Group, prefixed, *IT_*.
```powerShell
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2019-05-01-preview" -imageTemplateName $imageTemplateName -svclocation $location
```
 
# Build the image
To build the image you need to invoke 'Run'.

```powerShell
Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview" -Action Run -Force
```
>> Note, the command will not wait for the image builder service to complete the image build, you can query the status below.


# Get Status of the Image Build and Query 
As there are currently no specific Azure PowerShell cmdlets for image builder, we need to construct API calls, with the authentication, this is just an example, note, you can use existing alternatives you may have.

## Authentication Setup
We need to start, by getting the Bearer Token from your existing session.

>>> References
A big thanks to brettmillerb, for [this](https://gist.github.com/brettmillerb/69c557f269515ea903364948238a41ab) simple method.


```powerShell
### Step 1: Update context
$currentAzureContext = Get-AzContext

### Step 2: Get instance profile
$azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
    
Write-Verbose ("Tenant: {0}" -f  $currentAzureContext.Subscription.Name)
 
### Step 4: Get token  
$token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
$accessToken=$token.AccessToken
```

## Get Image Build Status and Properties

### Query the Image Template for Current or Last Run Status and Image Template Settings
```powerShell
$managementEp = $currentAzureContext.Environment.ResourceManagerUrl


$urlBuildStatus = [System.String]::Format("{0}subscriptions/{1}/resourceGroups/$imageResourceGroup/providers/Microsoft.VirtualMachineImages/imageTemplates/{2}?api-version=2019-05-01-preview", $managementEp, $currentAzureContext.Subscription.Id,$imageTemplateName)

$buildStatusResult = Invoke-WebRequest -Method GET  -Uri $urlBuildStatus -UseBasicParsing -Headers  @{"Authorization"= ("Bearer " + $accessToken)} -ContentType application/json 
$buildJsonStatus =$buildStatusResult.Content
$buildJsonStatus

```

The image build for this example will take approximately 30mins, when you query the status, you need to look for *lastRunStatus*, below shows the build is still running, if it had completed successfully, it would show 'suceeded'.

```text
  "lastRunStatus": {
   "startTime": "2019-08-21T00:39:40.61322415Z",
   "endTime": "0001-01-01T00:00:00Z",
   "runState": "Running",
   "runSubState": "Building",
   "message": ""
  },
```

### Query the Distribution properties
If you are distributing to a VHD location, need Managed Image Location properties, or Shared Image Gallery replications status, you need to query the 'runOutput', everytime you have a distribution target, you will have a unique runOutput, to describe properties of the distribution type.

```powerShell
$managementEp = $currentAzureContext.Environment.ResourceManagerUrl
$urlRunOutputStatus = [System.String]::Format("{0}subscriptions/{1}/resourceGroups/$imageResourceGroup/providers/Microsoft.VirtualMachineImages/imageTemplates/$imageTemplateName/runOutputs/{2}?api-version=2019-05-01-preview", $managementEp, $currentAzureContext.Subscription.Id, $runOutputName)

$runOutStatusResult = Invoke-WebRequest -Method GET  -Uri $urlRunOutputStatus -UseBasicParsing -Headers  @{"Authorization"= ("Bearer " + $accessToken)} -ContentType application/json 
$runOutJsonStatus =$runOutStatusResult.Content
$runOutJsonStatus
```
## Create a VM
Now the build is finished you can build a VM from the image, use the examples from [here](https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-2.5.0#examples).

# Clean Up

>>> Note!!!
>>Note! If you want to now try and take this SIG image, and re-customize it, try quick quickstart *2_Creating_a_Custom_Win_Shared_Image_Gallery_Image_from_SIG*, and do not run the following code!!!!!

Delete the resource group template first, do not just delete the entire resource group, otherwise the staging resource group (*IT_*) used by AIB will not be cleaned up.

### Get ResourceID of the Image Template
```powerShell
$resTemplateId = Get-AzResource -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview"

# Delete Image Template Artifact
Remove-AzResource -ResourceId $resTemplateId.ResourceId -Force
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
