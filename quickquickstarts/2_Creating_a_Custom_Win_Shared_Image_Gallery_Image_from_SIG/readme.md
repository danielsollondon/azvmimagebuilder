# Create a Custom Windows Image, from an existing Shared Image Gallery Custom Image then Distribute and Version over Multiple Regions

> **MAY 2020 SERVICE ALERT** - Existing users, please ensure you are compliant this [Service Alert by 26th May!!!](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review)

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, and then use the Azure [Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries).

This Quick Start assumes you have completed 1_Creating_a_Custom_Win_Shared_Image_Gallery_Image, and therefore the variables below, will be preset to those variable names, for continuity, but you can always update them yourself.

To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID** variable below.

>>> Note! Azure Image Builder automatically runs sysprep to generalize the image, this is a generic sysprep command, which you can [overide](https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md#vms-created-from-aib-images-do-not-create-successfully) if you are aware of more favorable settings. However, for *Windows there are limits on how many times (8), an image can be sysprep'd*, see [here](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation#limits-on-how-many-times-you-can-run-sysprep) for more details. Therefore exercise caution on how many times you layer customizations.

## Step 1 : Enable Prereqs

Happy Image Building!!!

### Register for Image Builder / VM / Storage Features
```bash
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview

az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview | grep state

# register and enable for shared image gallery
az feature register --namespace Microsoft.Compute --name GalleryPreview

# wait until it says registered

# check you are registered for the providers

az provider show -n Microsoft.VirtualMachineImages | grep registrationState
az provider show -n Microsoft.Storage | grep registrationState
az provider show -n Microsoft.Compute | grep registrationState
az provider show -n Microsoft.KeyVault | grep registrationState
```

If they do not saw registered, run the commented out code below.
```bash
## az provider register -n Microsoft.VirtualMachineImages
## az provider register -n Microsoft.Storage
## az provider register -n Microsoft.Compute
## az provider register -n Microsoft.KeyVault

```

## Step 1 : Set Variables

```powerShell

# Step 2: get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup="aibwinsig01"

# location (see possible locations in main docs)
$location="westus"

# your subscription, this will get your current subscription
$subscriptionID=$currentAzContext.Subscription.Id

# image template name
$imageTemplateName="helloImageTemplateWin03ps"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName="winserverR02"

$sigGalleryName= "myaibsig01"
$imageDefName ="winSvrimages"

# additional replication region
$replRegion2="eastus"
```

## Step 2 : Permissions, create user idenity and role for AIB

### Create user identity or use previous identity
```powerShell
# setup role def names, these need to be unique
$idenityObject=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup | Where-Object {$_.Name -Match "aibIdentity*"})


$idenityNameResourceId=$idenityObject.Id
$idenityNamePrincipalId=$idenityObject.PrincipalId
$idenityName=$idenityObject.Name
```
### (Optional) Assign permissions for identity to read source images and distribute images
In the previous example you have setup a SIG, with a user identity, that has permissions to read and write to the SIG. This is enough permissions for this example as we will be reading the SIG image version created in the prereq example, but just incase you are experimenting, and want to read an image version from another SIG, you will need to give the user identity permissions to access it, with the role definition.

```powerShell
$imageRoleDefName=<Get from previous example>
# grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName contributor -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

```

## Step 3 : Get latest image version for source
```powerShell
# get all versions from SIG def
$getAllImageVersions=$(Get-AzGalleryImageVersion -ResourceGroupName $imageResourceGroup  -GalleryName $sigGalleryName -GalleryImageDefinitionName $imageDefName)

# get name and expand publishing date for a version
$versionPubList=$($getAllImageVersions | Select-Object -Property Name -ExpandProperty PublishingProfile)

# order by published date (leaving in more columns for induvidual validation)
$sortedVersionList=$($versionPubList | Select-Object Name, PublishedDate | Sort-Object PublishedDate -Descending | Select-Object Name -First 1)

# get latest version resource id
$sigDefImgVersionId=$(Get-AzGalleryImageVersion -ResourceGroupName $imageResourceGroup  -GalleryName $sigGalleryName -GalleryImageDefinitionName $imageDefName -Name $sortedVersionList.name).Id
```

## Step 4 : Configure the Image Template

# Configure the Image Template
This command will download and update the template with the parameters specified earlier.
```powerShell

$templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/2_Creating_a_Custom_Win_Shared_Image_Gallery_Image_from_SIG/helloImageTemplateforSIGfromWinSIG.json"
$templateFilePath = "helloImageTemplateforSIGfromWinSIG.json"

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

((Get-Content -path $templateFilePath -Raw) -replace '<sigDefImgVersionId>',$sigDefImgVersionId) | Set-Content -Path $templateFilePath


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
