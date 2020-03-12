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
When you register for the (AIB), this grants the AIB Service permission to create, manage and delete a staging resource group (IT_*), and have rights to add resources to it, that are required for the image build. 

AIB does *NOT* have permission to access other resources in other resource groups in the subscription, you need to take explicit actions to allow that to happen. Without these actions the builds will fail.

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
The privilges below highlight what actions AIB requires, and you can create a Custom Role Definition and assign it to the AIB SPN, see the examples at the end of the document.

### Allowing AIB to Distribute Images
For AIB to distribute images (Managed Images / Shared Image Gallery), the AIB service must be allowed to inject the images into these resource groups, to do this, you need to grant the AIB Service Principal Name (SPN) rights on the resource group where the image will be placed. 

You can avoid granting the AIB SPN contributor on the resource group to distribute images, but it's SPN will need these these Azure Actions in the distribution resource group:

```bash
# these are minimum required for image builder, irrespective Managed Images \ Shared Image Gallery
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
The examples below show creating a Role Definition from the actions above, but these are being applied at the resource group level, but you should evaluate and test if these are granular enough for your requirements. For example the scope is set to the resource group, you maybe able to refine it to a specific resource.

### AZ CLI Examples
#### Setting AIB SPN Permissions to distribute a Managed Image or Shared Image 
```bash
# set your variables
subscriptionID=<subID>
imageResourceGroup=<distributionRG>

# download preconfigured example
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

# update the definition
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" aibRoleImageCreation.json

# create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json

# grant role definition to the AIB SPN
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role "Azure Image Builder Service Image Creation Role" \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup
```

#### Setting AIB SPN Permissions to allow it to use an existing VNET
```bash
# set your variables
subscriptionID=<subID>
imageResourceGroup=<distributionRG>

# download preconfigured example
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleNetworking.json -o aibRoleNetworking.json

# update the definition
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleNetworking.json
sed -i -e "s/<vnetRgName>/$vnetRgName/g" aibRoleNetworking.json

# create role definitions
az role definition update --role-definition ./aibRoleNetworking.json

# grant role definition to the AIB SPN
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role "Azure Image Builder Service Networking Role" \
 --scope /subscriptions/$subscriptionID/resourceGroups/$vnetRgName
```

### Azure PowerShell Examples
#### Setting AIB SPN Permissions to distribute a Managed Image or Shared Image 
```powerShell
# set your variables

# download preconfigured example
$aibRoleImageCreationUrl="https://raw.githubusercontent.com/../aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

# update the definition
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath

# create role definitions
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# grant role definition to the AIB SPN

New-AzRoleAssignment -ObjectId ef511139-6170-438e-a6e1-763dc31bdf74 -RoleDefinitionName "Azure Image Builder Service Image Creation Role" -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
```

#### Setting AIB SPN Permissions to allow it to use an existing VNET

```powerShell
# set your variables

# download preconfigured example
$aibRoleNetworkingUrl="https://raw.githubusercontent.com/../aibRoleNetworking.json"
$aibRoleNetworkingPath = "aibRoleNetworking.json"

Invoke-WebRequest -Uri $aibRoleNetworkingUrl -OutFile $aibRoleNetworkingPath -UseBasicParsing

# update the definition
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleNetworkingPath
((Get-Content -path $aibRoleNetworkingPath -Raw) -replace '<vnetRgName>',$vnetRgName) | Set-Content -Path $aibRoleNetworkingPath

# create role definitions
New-AzRoleDefinition -InputFile  ./aibRoleNetworking.json

# grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId ef511139-6170-438e-a6e1-763dc31bdf74 -RoleDefinitionName "Azure Image Builder Service Networking Role" -Scope "/subscriptions/$subscriptionID/resourceGroups/$vnetRgName"
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