# Create a Windows Custom Image that will use an Azure User-Assigned Managed Identity to seemlessly access files Azure Storage (DRAFT)

>>> NOTE!!!! THIS ARTICLE IS IN DRAFT, it has not been tested end to end, there will be bugs, expect this to be fully tested mid Decemeber 2019! The Linux version of the article is fully tested, and available [here](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/7_Creating_Custom_Image_using_MSI_to_Access_Storage).

AIB supports using scripts, or copying files from multiple locations, such as GitHub and Azure storage etc. 

This article shows how to create a basic customized image using the Azure VM Image Builder, where the service will use a [User-assigned Managed Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) to access files in Azure storage for the image customization, without you having to make the files publically accessible, or setting up SAS tokens.


In the example below, you will create two resource groups, one will be used for the custom image created, and the other one will just host an Azure Storage Account, that includes a scipt file. You will create a user-assigned identity, then grant that read permissions on the script file, and pass that identity to Image Builder. 

Here is a short video on how the example below works.

[<img src="./aibMsi.png" alt="drawing" width="450"/>
](https://youtu.be/aalpp2a8wv0)


To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID** variable below.

## Step 1: Enable Prereqs

Happy Image Building!!!

### Register for Image Builder / VM / Storage Features
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


If they do not show registered, run the commented out code below.
```PowerShell
## az provider register -n Microsoft.VirtualMachineImages

## az provider register -n Microsoft.Storage
```

### Set Permissions & Create Resource Group for Image Builder Images

```PowerShell
# set your environment variables here!!!!

# image resource group
imageResourceGroup=aibmdimsiwin

# Step 1: Import module
Import-Module Az.Accounts

# Step 2: get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup="aibmdimsiwin"

# 2nd resource group for storage account
strResourceGroup=aibmdimsistor

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

## Step 3: Create another Resource Group for a Storage Account to host scripts
```PowerShell
# create resource group for the script storage
New-AzResourceGroup -Name $strResourceGroup -Location $location

$dateNumeric = $(Get-Date -Format yyMMddTHHmmss)

# script storage account
$scriptStorageAcc=("aibstor"+$dateNumeric) 

# script container
$scriptStorageAccContainer=("scriptscont"+$dateNumeric)

# create storage account and blob in resource group

$storageAccount = New-AzStorageAccount -ResourceGroupName $strResourceGroup `
  -Name $scriptStorageAcc `
  -Location $location `
  -SkuName "Standard_LRS"


$storageAccount | New-AzStorageContainer -Name $scriptStorageAccContainer  -Permission Off

az storage container create -n $scriptStorageAccContainer --fail-on-exist --account-name $scriptStorageAcc

# copy in an example script from the github repo 
Upload a file into the container

```


## Step 4: Create User-Assigned Managed Identity and Grant Permissions 
For more information on User-Assigned Managed Identity, see [here](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#user-assigned-managed-identity).

```PowerShell
Install-Module -Name Az.ManagedServiceIdentity

New-AzUserAssignedIdentity -ResourceGroupName ignite2019 -Name aibIdentityPS

# get identityID
$identityId=""

New-AzRoleAssignment 
    -ObjectId $identityId -RoleDefinitionName "Storage Blob Data Reader" 
    -Scope "/subscriptions/$subscriptionID/resourceGroups/$strResourceGroup/providers/Microsoft.Storage/storageAccounts/$scriptStorageAcc/blobServices/default/containers/$scriptStorageAccContainer"

# create the user identity URI
$msiResID="/subscriptions/$subscriptionID+/resourcegroups/$imageResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$idenityName"
```
## Step 5: Configure the Image Builder Template

```PowerShell
# download the example and configure it with the variables below:

$templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/6_PowerShell_deploymentsSIG/armTemplateWinSIG.json"
$templateFilePath = "armTemplateWinSIG.json"

Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing
```
* subscriptionID
* rgName
* region
* imageName
* scriptUrl
* imgBuilderId
* runOutputName


## Step 5a: Submit the Image Configuration to the VM Image Builder Service

Your template must be submitted to the service, this will download any dependent artifacts (scripts etc), and store them in the staging Resource Group, prefixed, *IT_*.
```powerShell
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2019-05-01-preview" -imageTemplateName $imageTemplateName -svclocation $location -msi-token $msiResID
```
 
## Build the image
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

## Next Steps
* Want to learn more???
    * Explore the documentation in the [MS Teams channel](https://teams.microsoft.com/l/channel/19%3a03e8b2922c5b44eaaaf3d0c7cd1ff448%40thread.skype/General?groupId=a82ee7e2-b2cc-49e6-967d-54da8319979d&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47) (Files).
    * Look at the composition of the Image Builder Template, look in the 'Properties' you will see the source image, customization script it runs, and where it distributes it.

    ```PowerShell
    cat helloImageTemplateMsi.json
    ```

* Want to try more???
* Image Builder does support deployment through Azure Resource Manager, see here in the repo for [examples](https://github.com/danielsollondon/azvmimagebuilder/tree/master/armTemplates), you will also see how you can use a RHEL ISO source too, and manu other capabilities.
