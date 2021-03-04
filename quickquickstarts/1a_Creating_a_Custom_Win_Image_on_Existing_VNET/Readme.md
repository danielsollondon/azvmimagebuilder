# Create a Windows Image allowing access to an existing Azure VNET

> **MAY 2020 SERVICE ALERT** - Existing users, please ensure you are compliant this [Service Alert by 26th May!!!](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review)

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, which has access to existing resources on a VNET. For the end to end example, the build VM will be deployed on to a VNET you specify in your subscription, either an existing one, or a new one. Using this model means the image builder service does not require any public network connectivity.

This covers using mutliple customizations to illustrate some high level functionality:
* PowerShell (ScriptUri) - Downloading a bash script and executing it
* PowerShell (inline) - Execute an array of commands
* File - Copy a html file from github to a specified, pre-created directory
* buildTimeoutInMinutes - Increase a build time to allow for longer running builds 
* Windows Restart - Restart Windows between customizations
* Windows Update - Install Windows Updates during the build (this will also handle restarts, if required)
* vmProfile - specifying a vmSize and Network properties
* osDiskSizeGB - you can increase the size of image

This walk through is intended to be a copy and paste exercise, and will provide you with a custom Win Server image (AIB also supports client images), showing you how you can easily create a custom image.

> Note! Azure Image Builder automatically runs sysprep to generalize the image, this is a generic sysprep command, which you can [overide](https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md#vms-created-from-aib-images-do-not-create-successfully) if you are aware of more favorable settings. However, for *Windows there are limits on how many times (8), an image can be sysprep'd*, see [here](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation#limits-on-how-many-times-you-can-run-sysprep) for more details. Therefore exercise caution on how many times you layer customizations.


## Step 1 : Enable Prereqs
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

### Set Permissions & Create Resource Group for Image Builder Images

```powerShell
# Step 1: Import module
Import-Module Az.Accounts

# Step 2: get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup="aibImageRG"

# location (see possible locations in main docs)
$location="westus2"

## if you need to change your subscription: Get-AzSubscription / Select-AzSubscription -SubscriptionName 

# get subscription, this will get your current subscription
$subscriptionID=$currentAzContext.Subscription.Id

# name of the image to be created
$imageName="win2019image01"

# image distribution metadata reference name
$runOutputName="win2019ManImg02ro"

# image template name
$imageTemplateName="window2019VnetTemplate03"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName="winSvrSigR01"

# VNET properties (update to match your existing VNET, or leave as-is for demo)
# VNET name
$vnetName="myexistingvnet01"
# subnet name
$subnetName="subnet01"
# VNET resource group name
$vnetRgName="existingVnetRG"
# Existing Subnet NSG Name or the demo will create it
$nsgName="aibdemoNsg"
# NOTE! The VNET must always be in the same region as the AIB service region.


# create resource group for image and image template resource
New-AzResourceGroup -Name $imageResourceGroup -Location $location
```
## Step 2: Configure Networking
>>>Note!! If you do not have an existing VNET\Subnet\NSG 
Please follow these [steps](./createTestVnetWindows.md) to create a VNET\Subnet\NSG, these are required for the demo.

###  Add NSG rule to allow the AIB deployed Azure Load Balancer to communicate with the proxy VM

```powerShell
Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $vnetRgName  | Add-AzNetworkSecurityRuleConfig -Name AzureImageBuilderAccess -Description "Allow Image Builder Private Link Access to Proxy VM" -Access Allow -Protocol Tcp -Direction Inbound -Priority 400 -SourceAddressPrefix AzureLoadBalancer -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 60000-60001 | Set-AzNetworkSecurityGroup
```

### Disable Private Service Policy on subnet
```powerShell
$virtualNetwork= Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRgName 
   
($virtualNetwork | Select -ExpandProperty subnets | Where-Object  {$_.Name -eq $subnetName} ).privateLinkServiceNetworkPolicies = "Disabled"  
 
$virtualNetwork | Set-AzVirtualNetwork 
```
For more information on image builder networking, please review this [document](https://github.com/danielsollondon/azvmimagebuilder/blob/master/aibNetworking.md#networking-with-azure-vm-image-builder).

## Step 2 : Modify the Example template and create role for AIB
This command will download and update the template with the parameters specified earlier.
```powerShell
$templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/1a_Creating_a_Custom_Win_Image_on_Existing_VNET/existingVNETWindows.json"
$templateFilePath = "existingVNETWindows.json"

$aibRoleNetworkingUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleNetworking.json"
$aibRoleNetworkingPath = "aibRoleNetworking.json"

$aibRoleImageCreationUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# download configs
Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

Invoke-WebRequest -Uri $aibRoleNetworkingUrl -OutFile $aibRoleNetworkingPath -UseBasicParsing

Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

# update AIB image config template
((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imageName>',$imageName) | Set-Content -Path $templateFilePath

((Get-Content -path $templateFilePath -Raw) -replace '<vnetName>',$vnetName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<subnetName>',$subnetName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<vnetRgName>',$vnetRgName) | Set-Content -Path $templateFilePath
```

# Assign permissions, create user idenity and role for AIB for distributing images and connecting to network.

```powerShell
# setup role def names, these need to be unique
$timeInt=$(get-date -UFormat "%s")
$imageRoleDefName="Azure Image Builder Image Def"+$timeInt
$networkRoleDefName="Azure Image Builder Network Def"+$timeInt
$idenityName="aibIdentity"+$timeInt

# create user identity
## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName

$idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId

# update template with identity
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$idenityNameResourceId) | Set-Content -Path $templateFilePath

# update the role defintion names
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role',$imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace 'Azure Image Builder Service Networking Role',$networkRoleDefName) | Set-Content -Path $aibRoleNetworkingPath

# update role definitions
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleNetworkingPath
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace '<vnetRgName>',$vnetRgName) | Set-Content -Path $aibRoleNetworkingPath

((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath

# create role definitions from role configurations examples, this avoids granting contributor to the SPN
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json
New-AzRoleDefinition -InputFile  ./aibRoleNetworking.json

# grant role definition to image builder user identity
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $networkRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$vnetRgName"

```
For more information on image builder permissions, please review this [document](https://github.com/danielsollondon/azvmimagebuilder/blob/master/aibPermissions.md#azure-vm-image-builder-permissions-explained-and-requirements).


# Submit the template
Your template must be submitted to the service, this will download any dependent artifacts (scripts etc), and store them in the staging Resource Group, prefixed, *IT_*.
```powerShell
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2020-02-14" -imageTemplateName $imageTemplateName -svclocation $location

# note this will take minute, as validation is run (security / dependencies etc.)
```
 
# Build the image
To build the image you need to invoke 'Run'.

```powerShell
Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run -Force

>>>> WAITING ON IMAGE BUILD

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

The image build for this example will take approximately 50mins (multiple reboots, windows update installs/reboot), when you query the status, you need to look for *lastRunStatus*, below shows the build is still running, if it had completed successfully, it would show 'suceeded'.

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

## Clean Up

### Delete Image Template Artifact
```powerShell
# Get ResourceID of the Image Template
$resTemplateId = Get-AzResource -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview"

### Delete Image Template Artifact
Remove-AzResource -ResourceId $resTemplateId.ResourceId -Force

```
### Delete role assignment
```powerShell
## remove role assignments
Remove-AzRoleAssignment -ObjectId $idenityNamePrincipalId  -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
Remove-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $networkRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$vnetRgName"

## remove definitions
Remove-AzRoleDefinition -Id $imageRoleDefObjId -Force
Remove-AzRoleDefinition -Id $networkRoleObjId -Force

## delete identity
Remove-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName -Force
```

### Delete Resource Groups
```powerShell
Remove-AzResourceGroup $imageResourceGroup -Force


# delete VNET created
# BEWARE!!!!! In this example, you have either used an existing VNET or created one for this example. Do not delete your existing VNET. If you want to delete the VNET Resource group used in this example '$vnetRgName', modify the above code.
```
## Next Steps
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../quickquickstarts/nextSteps.md)]


