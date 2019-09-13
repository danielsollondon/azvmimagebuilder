# Using PowerShell to Create a Windows 10 Custom Image using Azure VM Image Builder (Preview Example)

Most of the examples for Azure VM Image Builder (AIB) using the Azure CLI, this example shows how you can use PowerShell to do the same.

This walk through is based off the [Create a Windows Custom Image from an Azure Platform Vanilla OS Image Quick Start](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image), that is deployed using Azure CLI.

The main key difference is that we use an ARM template with the AIB template nested inside, this simplifies deploying the AIB Configuration Template, and gives you other benefits for free, such as variables and parameter inputs etc. You can also pass parameters from the commandline too, which you will see here.

This walk through is intended to be a copy and paste exercise, and will provide you with a custom Win 10 image, showing you how you can easily create a custom image.

>>>Note! This example is currently being tested, so there maybe bugs in it, if you find a bug, please raise an issue.

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

# If they do not saw registered, run the commented out code below.

## Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
## Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
```

## Step 1: Set up environment and variables

```powerShell
# Step 1: Import module
Import-Module Az.Accounts

# Step 2: get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup="aibmdips"

# location (see possible locations in main docs)
$location="westus"

# your subscription, this will get your current subscription
$subscriptionID=$currentAzContext.Subscription.Id

# name of the image to be created
$imageName="aibCustomImgWin10"

# image distribution metadata reference name
$runOutputName="aibCustWinManImg02ro"

# image template name
$imageTemplateName="helloImageTemplateWin02ps"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName="winclientR01"


# create resource group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

# assign permissions for that resource group, so that AIB can distribute the image to it
New-AzRoleAssignment -ObjectId ef511139-6170-438e-a6e1-763dc31bdf74 -Scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup -RoleDefinitionName Contributor
```
# Create the Shared Image Gallery
```powerShell
$sigGalleryName= "myCorpImggal"
$imageDefName ="win10imgs"

# additional replication region
$replRegion2="eastus"

# create gallery
New-AzGallery -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup  -Location $location

# create gallery definition
New-AzGalleryImageDefinition -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup -Location $location -Name $imageDefName -OsState generalized -OsType Windows -Publisher 'myCo' -Offer 'Windows' -Sku 'Win10'

```

# Configure the Image Template
This command will download and update the template with the parameters specified earlier.
```powerShell

$templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/6_PowerShell_deploymentsSIG/armTemplateWinSIG.json"
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

```


# Submit the template
Your template must be submitted to the service, this will download any dependent artifacts (scripts etc), and store them in the staging Resource Group, prefixed, *IT_*.
```powerShell
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2019-05-01-preview" -imageTemplateName $imageTemplateName -svclocation $location
```
 
# Build the image
To build the image you need to invoke 'Run'.

```powerShell
Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview" -Action Run
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

### Query the Distritbution properties
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

## Clean Up

>>> Note!!!
Delete the resource group template first, do not just delete the entire resource group, otherwise the staging resource group (*IT_*) used by AIB will not be cleaned up.

### Get ResourceID of the Image Template
```powerShell
$resTemplateId = Get-AzResource -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview"
```
### Delete Image Template Artifact
```powerShell
Remove-AzResource -ResourceId $resTemplateId.ResourceId -Force
```
### Delete Resource Group
```powerShell
Remove-AzResourceGroup $imageResourceGroup -Force
```



