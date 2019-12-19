# Create a Custom Image from an Azure Platform Vanilla OS Image

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, and distribute to a region. This covers using mutliple customizations to illustrate some high level functionality:
* Shell (ScriptUri) - Downloading a bash script and executing it
* Shell (ScriptUri) with file validation, using sha256Checksum:
    * Checksum your Script file locally, then pass this to Image Builder to compare the checksum during the image build. 
    * To generate the sha256Checksum, using a terminal on Mac/Linux run:
    ```bash
    sha256sum <fileName>
    ```
* Shell (inline) - Execute an array of commands
* File - Copy a html file from github to a specified, pre-created directory
    * This also supports *sha256Checksum* property too.
* buildTimeoutInMinutes - Increase a build time to allow for longer running builds 
* vmProfile:
    * vmSize
        By default Image Builder will use a "Standard_D1_v2" build VM, you can override this, for example, if you want to customize an Image for a GPU VM, you need a GPU VM size. This is optional.
    * osDiskSizeGB
        * By default, Image Builder will not change the size of the image, it will use the size from the source image. You can adjust the size of the OS Disk (Win and Linux), note, do not go too small than the minimum required space required for the OS. This is optional, and a value of 0 means leave the same size as the source image.


To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID** variable below.

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

## Set Permissions & Create Resource Group for Image Builder Images

```bash
# set your environment variables here!!!!

# destination image resource group
imageResourceGroup=aibmdi

# location (see possible locations in main docs)
location=WestUS2

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=<INSERT YOUR SUBSCRIPTION ID HERE>

# name of the image to be created
imageName=aibCustomLinuxImg01

# image distribution metadata reference name
runOutputName=aibCustLinManImg01ro

# create resource group
az group create -n $imageResourceGroup -l $location

# assign permissions for that resource group
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role Contributor \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

```

## Step 2 : Modify HelloImage Example

```bash
# download the example and configure it with your vars

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json -o helloImageTemplateLinux.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateLinux.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" helloImageTemplateLinux.json
sed -i -e "s/<region>/$location/g" helloImageTemplateLinux.json
sed -i -e "s/<imageName>/$imageName/g" helloImageTemplateLinux.json
sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateLinux.json

```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateLinux.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateLinux01

# wait approx 1-3mins, depending on external links

# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateLinux01 \
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
    -n helloImageTemplateLinux01

az group delete -n $imageResourceGroup


```

## Next Steps
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../quickquickstarts/nextSteps.md)]
