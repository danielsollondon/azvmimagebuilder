# Create a Custom Image from an Azure Platform Vanilla OS Image and distribute to VHD
This article is to show you how you can create a basic customized image using the Azure VM Image Builder, and distribute to VHD.

To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID** variable below.


## Step 1 : Enable Prereqs

Happy Image Building!!!

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
imageResourceGroup=aibvhd

# location (see possible locations in main docs)
location=WestUS2

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=$(az account show | grep id | tr -d '",' | cut -c7-)

# Image Template Name
imageTemplateName=helloImageTemplateVHD01

# image distribution metadata reference name
runOutputName=aibCustomVhd01ro

# create resource group
az group create -n $imageResourceGroup -l $location
```

## Step 2 : Modify HelloImage Example

```bash
# download the example and configure it with your vars

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/4_Creating_a_Custom_Linux_Image_to_VHD/helloImageTemplateVHD.json -o helloImageTemplateVHD.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateVHD.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" helloImageTemplateVHD.json
sed -i -e "s/<region>/$location/g" helloImageTemplateVHD.json
sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateVHD.json

```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateVHD.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateVHD01


# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateVHD01 \
     --action Run 

# wait approx 15mins
```


## Step 4 : Get the URL to the VHD
```bash
az resource show \
    --ids "/subscriptions/$subscriptionID/resourcegroups/$imageResourceGroup/providers/Microsoft.VirtualMachineImages/imageTemplates/$imageTemplateName/runOutputs/$runOutputName"  \
    --api-version=2019-05-01-preview | grep artifactUri
```


>>Note!! Once the VHD has been created, copy it to an alternative location, as soon as possible. The VHD is stored in a storage account in the temporary Resource Group created when the Image Template is submitted to the AIB service. If you delete the Image Template, then you will loose this VHD. 

## Clean Up
```bash
az resource delete \
    --resource-group $imageResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplate01

az group delete -n $imageResourceGroup

```

## Next Steps
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../quickquickstarts/nextSteps.md)]
