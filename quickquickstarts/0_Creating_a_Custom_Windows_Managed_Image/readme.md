# Create a Windows Custom Managed Image from an Azure Platform Vanilla OS Image

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, and distribute to a region.

This covers using mutliple customizations to illustrate some high level functionality:
* PowerShell (ScriptUri) - Downloading a bash script and executing it
* PowerShell (inline) - Execute an array of commands
* File - Copy a html file from github to a specified, pre-created directory
* buildTimeoutInMinutes - Increase a build time to allow for longer running builds 
* vmProfile - specifying a vmSize and Network properties
* osDiskSizeGB - you can increase the size of image
* WindowsRestart - this will allow for restarts between software installs
* WindowsUpdate - update the image with the latest Windows Updates, note this will handle its own required reboots.

To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID** variable below.

## Step 1 : Enable Prereqs

Happy Image Building!!!

>> Note!! You will notice the code below is all in Bash, with AZ CLI. We now have PowerShell equivalent example in preview [here](https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/5_PowerShell_deployments#using-powershell-to-create-a-windows-10-custom-image-using-azure-vm-image-builder-preview-example). 

### Register for Image Builder / VM / Storage Features
```bash
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview

az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview | grep state

# wait until it says registered

# check you are registered for the providers

az provider show -n Microsoft.VirtualMachineImages | grep registrationState
az provider show -n Microsoft.Storage | grep registrationState
az provider show -n Microsoft.Compute | grep registrationState
az provider show -n Microsoft.KeyVault | grep registrationState
```

If they do not show registered, run the commented out code below.
```bash
## az provider register -n Microsoft.VirtualMachineImages
## az provider register -n Microsoft.Storage
## az provider register -n Microsoft.Compute
## az provider register -n Microsoft.KeyVault

```

## Set Permissions & Create Resource Group for Image Builder Images

```bash
# set your environment variables here!!!!

# destination image resource group
imageResourceGroup=aibmdiwin06

# location (see possible locations in main docs)
location=WestUS2

# password for test VM
vmpassword=<INSERT YOUR PASSWORD HERE>
# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=$(az account show | grep id | tr -d '",' | cut -c7-)


# name of the image to be created
imageName=aibCustomImgWini01

# image distribution metadata reference name
runOutputName=aibCustWinManImg01ro

# create resource group
az group create -n $imageResourceGroup -l $location
```

### Assign AIB SPN Permissions to distribute a Managed Image or Shared Image 
```bash
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

## Step 2 : Modify HelloImage Example

```bash
# download the example and configure it with your vars

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/10_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json -o helloImageTemplateWin.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateWin.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" helloImageTemplateWin.json
sed -i -e "s/<region>/$location/g" helloImageTemplateWin.json
sed -i -e "s/<imageName>/$imageName/g" helloImageTemplateWin.json
sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateWin.json

```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateWin02.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateWin02
# wait approx 1-3mins, depending on external links

# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateWin \
     --action Run 

# wait approx 15mins
```

## Step 4 : Create the VM
```bash
az vm create \
  --resource-group $imageResourceGroup \
  --name aibImgWinVm00 \
  --admin-username aibuser \
  --admin-password $vmpassword \
  --image $imageName \
  --location $location

```
Remote Desktop to the VM, using the Portal, or typing MSTSC at the Command Prompt (CMD).

Then, Go to the Command Prompt, then run:
```bash
dir c:\
```
You should see these two directories created during image customization:
* buildActions
* buildArtifacts

## Clean Up
```bash
az resource delete \
    --resource-group $imageResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateWin01

az role assignment delete \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role "Azure Image Builder Service Image Creation Role" \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

az role definition delete --name "Azure Image Builder Service Image Creation Role"

az group delete -n $imageResourceGroup

```

## Next Steps
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../quickquickstarts/nextSteps.md)]
