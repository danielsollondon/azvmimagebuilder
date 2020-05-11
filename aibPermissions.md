# Azure VM Image Builder Permissions Explained and Requirements

This document is to explain permissions granted and required for Azure VM Image Builder Service (AIB), covering these topics:

* Permissions granted registering for the Service
* Requirements
    * Allowing AIB to Distribute Images
    * Allowing AIB to Customize existing Custom Images
    * Allowing AIB to Customize Images on your existing VNETs
* Creating AIB Azure Role Definition and assignment to build image
    * AZ CLI Examples
    * Azure PowerShell Examples
* Using Managed Identity to allowing Image Builder to Access Azure Storage

## Permissions granted registering for the Service
When you register for the (AIB), this grants the AIB Service permission to create, manage and delete a staging resource group (IT_*), and have rights to add resources to it, that are required for the image build. This is done by an AIB Service Principal Name (SPN) being made available in your subscription during a successful registration.

The AIB SPN does *NOT* have permission to access other resources in other resource groups in the subscription, you need to grant explicit actions to allow that to happen. Without these actions the builds will fail.

To allow AIB to create,manage and delete a staging resource group you must register for the service:
* AZ CLI
```bash
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview
```
* PowerShell
```PowerShell
Register-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages
```

## Requirements 
You must create an [Azure user-assigned managed identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli) for use with AIB, this will be used during the image build to read images, write images, and access Azure storage. You then need to grant it permission to do specific actions below in your subscription.

> Note! Previously with AIB, you would use the AIB SPN, and grant the SPN permissions to the image resource groups. We are moving away from this model, to allow for future capabilities. From 1st June 2020, Image Builder will not accept templates that do not have a user-assigned identity. For customers using the Azure DevOps task, the task will be updated shortly to support this.

You can review the [Azure user-assigned managed identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli) documentation on how to create an identity, but here are some examples below.

## Creating an Azure user-assigned Managed Identity
### AZ CLI
```bash
idenityName=aibBuiUserId
imageResourceGroup="<rgname>"
az identity create -g $imageResourceGroup -n $idenityName
```
### PowerShell
```PowerShell
$idenityName="aibIdentity"
$imageResourceGroup="<rgname>"
## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName
```

### Allowing AIB to Distribute Images
For AIB to distribute images (Managed Images / Shared Image Gallery), the AIB service must be allowed to inject the images into these resource groups, to do this, you need to create and grant a user-assigned identity rights on the resource group where the image will be placed. 

You can avoid granting the user-assigned identity contributor permission on the resource group to distribute images, but it will need permissions tp perform these Azure Actions in the distribution resource group:

```bash
# these are minimum required for image builder, irrespective Managed Images \ Shared Image Gallery, as AIB creates an intermediate staging image.
Microsoft.Compute/images/write
Microsoft.Compute/images/read
Microsoft.Compute/images/delete

# in addition, if distributing to a shared image gallery you will need these:
Microsoft.Compute/galleries/read
Microsoft.Compute/galleries/images/read
Microsoft.Compute/galleries/images/versions/read
Microsoft.Compute/galleries/images/versions/write
```

### Allowing AIB to Customize existing Custom Images
For AIB to build images from source custom images (Managed Images / Shared Image Gallery), the AIB service must be allowed to read the images into these resource groups, to do this, you need to grant the AIB Service Principal Name (SPN) reader rights on the resource group where the image is located. 

```bash
# to build from an existing custom image
Microsoft.Compute/galleries/read

# to build from an existing SIG version
Microsoft.Compute/galleries/read
Microsoft.Compute/galleries/images/read
Microsoft.Compute/galleries/images/versions/read
```

### Allowing AIB to Customize Images on your existing VNETs
AIB has the capability to deploy and use an existing VNET in your subcription, thus allowing customizations access to connected resources. 

You can avoid granting the AIB SPN contributor for it to deploy a VM to an existing VNET, but it's SPN will need these Azure Actions on the VNET resource group:

```bash
Microsoft.Network/virtualNetworks/read
Microsoft.Network/virtualNetworks/subnets/join/action
```

## Creating Azure Role Definition and Assignment from Actions
The examples below show creating a Role Definition from the actions above, but these are being applied at the resource group level, but you should evaluate and test if these are granular enough for your requirements. For example the scope is set to the resource group, you maybe able to refine it to a specific Shared Image Gallery. The image actions allow read and write, you should decide what is appropriate for your environment, for example, you may create a role to allow AIB to read images from resource group 1 and allow it to write images to resource group 2.

### AZ CLI Examples
#### Setting AIB user-dentity Permissions to use source custom image and distribute a custom image
```bash
# download user definition template
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

# update template
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" aibRoleImageCreation.json

# get identity id
imgBuilderCliId=$(az identity show -g $imageResourceGroup -n $idenityName | grep "clientId" | cut -c16- | tr -d '",')

# make role name unique, to avoid clashes in the same AAD Domain
imageRoleDefName="Azure Image Builder Image Def"$(date +'%s')

# update the definitions
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json

# create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json

# grant role definition to the user assigned identity
az role assignment create \
    --assignee $imgBuilderCliId \
    --role $imageRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup
```
#### Setting AIB SPN Permissions to allow it to use an existing VNET
```bash
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleNetworking.json -o aibRoleNetworking.json

# update template
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleNetworking.json
sed -i -e "s/<vnetRgName>/$vnetRgName/g" aibRoleNetworking.json

# get identity id
imgBuilderCliId=$(az identity show -g $imageResourceGroup -n $idenityName | grep "clientId" | cut -c16- | tr -d '",')

# make role name unique, to avoid clashes in the same AAD Domain
netRoleDefName="Azure Image Builder Network Def"$(date +'%s')

# update the definitions
sed -i -e "s/Azure Image Builder Service Networking Role/$netRoleDefName/g" aibRoleNetworking.json

# create role definitions
az role definition create --role-definition ./aibRoleNetworking.json

# grant role definition to the user assigned identity
az role assignment create \
    --assignee $imgBuilderCliId \
    --role $netRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$vnetRgName

```

### Azure PowerShell Examples
#### Setting AIB SPN Permissions to use source custom image and distribute a custom image
```powerShell
# make role name unique, to avoid clashes in the same AAD Domain
$timeInt=$(get-date -UFormat "%s")
$imageRoleDefName="Azure Image Builder Image Def"+$timeInt

# get the user-identity properties
$idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId


# assign permissions for identity to distribute images
This command will download and update the template with the parameters specified earlier.
```powerShell
$aibRoleImageCreationUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# download config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

# update role definition template
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath

## randomize the role definition name to make it unique for this example
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
```

#### Setting AIB SPN Permissions to allow it to use an existing VNET

```powerShell
# set unique role name
$networkRoleDefName="Azure Image Builder Network Def"+$timeInt

$aibRoleNetworkingUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleNetworking.json"
$aibRoleNetworkingPath = "aibRoleNetworking.json"

# download configs
Invoke-WebRequest -Uri $aibRoleNetworkingUrl -OutFile $aibRoleNetworkingPath -UseBasicParsing

# update role definition template
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleNetworkingPath
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace '<vnetRgName>',$vnetRgName) | Set-Content -Path $aibRoleNetworkingPath

## randomize the role definition name to make it unique for this example
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace 'Azure Image Builder Service Networking Role',$networkRoleDefName) | Set-Content -Path $aibRoleNetworkingPath

# create role definitions
New-AzRoleDefinition -InputFile  ./aibRoleNetworking.json

# grant role definition to image builder user identity
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $networkRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$vnetRgName"
```

## Using Managed Identity to allowing Image Builder to Access Azure Storage
If you want to seemlessly authenticate with Azure Storage, and use Private Containers, then you need to give AIB an Azure User-Assigned Managed Identity, which it can use to authenticate with Azure Storage.

>>> Note! AIB only uses the identity at image template submission time, the build VM does not have access to the identity during image build!!!

We have a [quick start](XXXXXXXhttps://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/7_Creating_Custom_Image_using_MSI_to_Access_Storage#create-a-custom-image-that-will-use-an-azure-user-assigned-managed-identity-to-seemlessly-access-files-azure-storage) that walks through how to connect to set this up, but in summary, once you have created User-Assigned Managed Identity, you then give rights for it to read from the storage account:

```bash
az role assignment create \
    --assignee $imgBuilderCliId \
    --role "Storage Blob Data Reader" \
    --scope /subscriptions/$subscriptionID/resourceGroups/$strResourceGroup/providers/Microsoft.Storage/storageAccounts/$scriptStorageAcc/blobServices/default/containers/$scriptStorageAccContainer 
```

Then in the Image Builder Template you need to provide the User-Assigned Managed Identity:

```json
    "type": "Microsoft.VirtualMachineImages/imageTemplates",
    "apiVersion": "2019-05-01-preview",
    "location": "<region>",
    ..
    "identity": {
    "type": "UserAssigned",
          "userAssignedIdentities": {
            "<imgBuilderId>": {}     
        }
```

We are making service improvements to reduce the complexity of the existing security model.