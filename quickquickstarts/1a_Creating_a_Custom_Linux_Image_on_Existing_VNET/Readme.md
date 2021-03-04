# Create a Custom Linux Image allowing access to an existing Azure VNET

> **MAY 2020 SERVICE ALERT** - Existing users, please ensure you are compliant this [Service Alert by 26th May!!!](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review)

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, which has access to existing resources on a VNET. For the end to end example, the build VM will be deployed on to a VNET you specify in your subscription, either an existing one, or a new one. Using this model means the image builder service does not require any public network connectivity.

This covers using mutliple customizations to illustrate some high level functionality:
* Shell (ScriptUri) - Downloading a bash script and executing it
* Shell (inline) - Execute an array of commands
* File - Copy a html file from github to a specified, pre-created directory
* buildTimeoutInMinutes - Increase a build time to allow for longer running builds 
* vmProfile - specifying a vmSize and Network properties
* osDiskSizeGB - you can increase the size of image

To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/).

## Step 1 : Enable Prereqs

Happy Image Building!!!

### Register for Image Builder / VM / Storage Features
```bash
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview

az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview | grep state

az feature show --namespace Microsoft.KeyVault --name VirtualMachineTemplatePreview | grep state

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

### Set Permissions & Create Resource Group for Image Builder Images

```bash
# set your environment variables here!!!!

# destination image resource group
imageResourceGroup=aibImageRG01

# location (see possible locations in main docs)
location=WestUS2

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=$(az account show | grep id | tr -d '",' | cut -c7-)

# name of the image to be created
imageName=aibCustomLinuxImg01

# image distribution metadata reference name
runOutputName=aibCustLinManImg01ro


# VNET properties (update to match your existing VNET, or leave as-is for demo)
# VNET name
vnetName=myexistingvnet01
# subnet name
subnetName=subnet01
# VNET resource group name
# NOTE! The VNET must always be in the same region as the AIB service region.
vnetRgName=existingVnetRG
# Existing Subnet NSG Name or the demo will create it
nsgName=aibdemoNsg

# create resource group for image and image template resource
az group create -n $imageResourceGroup -l $location

```

## Step 2: Configure Networking
>>>Note!! If you do not have an existing VNET\Subnet\NSG 
Please follow these [steps](./createTestVnetLinux.md) to create a VNET\Subnet\NSG, these are required for the demo.

###  Add NSG rule to allow the AIB deployed Azure Load Balancer to communicate with the proxy VM
```
az network nsg rule create \
    --resource-group $vnetRgName \
    --nsg-name $nsgName \
    -n AzureImageBuilderNsgRule \
    --priority 400 \
    --source-address-prefixes AzureLoadBalancer \
    --destination-address-prefixes VirtualNetwork \
    --destination-port-ranges 60000-60001 --direction inbound \
    --access Allow --protocol Tcp \
    --description "Allow Image Builder Private Link Access to Proxy VM"
```
This allows connectivity from the load balancer to the proxy VM, specifically, 60001 is for Linux OS's, and 60000 for Windows OS's. The proxy VM will connect to the build VM using port 22 for Linux OS's, or 5986 for Windows OS's.


### Disable Private Service Policy on subnet

```bash
az network vnet subnet update \
  --name $subnetName \
  --resource-group $vnetRgName \
  --vnet-name $vnetName \
  --disable-private-link-service-network-policies true 
```

For more information on image builder networking, please review this [document](https://github.com/danielsollondon/azvmimagebuilder/blob/master/aibNetworking.md#networking-with-azure-vm-image-builder).

## Step 2 : Modify the Example template and create role for AIB

```bash
# download the example and configure it with your vars

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/1a_Creating_a_Custom_Linux_Image_on_Existing_VNET/existingVNETLinux.json -o existingVNETLinux.json
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleNetworking.json -o aibRoleNetworking.json
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" existingVNETLinux.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" existingVNETLinux.json
sed -i -e "s/<region>/$location/g" existingVNETLinux.json
sed -i -e "s/<imageName>/$imageName/g" existingVNETLinux.json
sed -i -e "s/<runOutputName>/$runOutputName/g" existingVNETLinux.json

sed -i -e "s/<vnetName>/$vnetName/g" existingVNETLinux.json
sed -i -e "s/<subnetName>/$subnetName/g" existingVNETLinux.json
sed -i -e "s/<vnetRgName>/$vnetRgName/g" existingVNETLinux.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" aibRoleImageCreation.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleNetworking.json
sed -i -e "s/<vnetRgName>/$vnetRgName/g" aibRoleNetworking.json

```


## Step 3: Create a user identify and assign permissions for the resource group where the image will be created, and permissions to join the existing VNET

### Create User-Assigned Managed Identity and Grant Permissions 
For more information on User-Assigned Managed Identity, see [here](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#user-assigned-managed-identity).

```bash
# create user assigned identity for image builder
idenityName=aibBuiUserId$(date +'%s')
az identity create -g $imageResourceGroup -n $idenityName

# get identity id
imgBuilderCliId=$(az identity show -g $imageResourceGroup -n $idenityName | grep "clientId" | cut -c16- | tr -d '",')

# get the user identity URI, needed for the template
imgBuilderId=/subscriptions/$subscriptionID/resourcegroups/$imageResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$idenityName

# update the template
sed -i -e "s%<imgBuilderId>%$imgBuilderId%g" existingVNETLinux.json

# make role name unique, to avoid clashes in the same AAD Domain
imageRoleDefName="Azure Image Builder Image Def"$(date +'%s')
netRoleDefName="Azure Image Builder Network Def"$(date +'%s')

# update the definitions
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json
sed -i -e "s/Azure Image Builder Service Networking Role/$netRoleDefName/g" aibRoleNetworking.json
```
Instead of granting image builder lower granularity, increased privilge, you can create two roles, one gives the builder permissions to create an image, the other allows it to connect the build VM and loadbalancer to your VNET.

```bash
# create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json
az role definition create --role-definition ./aibRoleNetworking.json

# grant role definition to the user assigned identity
az role assignment create \
    --assignee $imgBuilderCliId \
    --role $imageRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

az role assignment create \
    --assignee $imgBuilderCliId \
    --role $netRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$vnetRgName

```
For more information on image builder permissions, please review this [document](https://github.com/danielsollondon/azvmimagebuilder/blob/master/aibPermissions.md#azure-vm-image-builder-permissions-explained-and-requirements).

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imageResourceGroup \
    --properties @existingVNETLinux.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n existingVNETLinuxTemplate01

# wait approx 1-3mins (validation, permissions etc.)

# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n existingVNETLinuxTemplate01 \
     --action Run 

# wait approx 15mins

```


## Step 4 : Create the VM

```bash
az vm create \
  --resource-group $imageResourceGroup \
  --name aibImgVm0001 \
  --admin-username aibuser \
  --image $imageName \
  --location $location \
  --generate-ssh-keys

# and login...

ssh aibuser@<pubIp>

You should see the image was customized with a Message of the Day as soon as your SSH connection is established!

*******************************************************
**            This VM was built from the:            **
...

```

## Clean Up
```bash
az resource delete \
    --resource-group $imageResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n existingVNETLinuxTemplate01


# delete permissions asssignments, roles and identity
az role assignment delete \
    --assignee $imgBuilderCliId \
    --role $imageRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

az role assignment delete \
    --assignee $imgBuilderCliId \
    --role $netRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$vnetRgName


az role definition delete --name "$imageRoleDefName"
az role definition delete --name "$netRoleDefName"

az identity delete --ids $imgBuilderId

az group delete -n $imageResourceGroup
az group delete -n $vnetRgName

# delete VNET created
# BEWARE!!!!! In this example, you have either used an existing VNET or created one for this example. Do not delete your existing VNET. If you want to delete the VNET Resource group used in this example '$vnetRgName', modify the above code.
```

## Next Steps
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../quickquickstarts/nextSteps.md)]
