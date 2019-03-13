# Create a Windows Custom Image from an Azure Platform Vanilla OS Image

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, and distribute to a region.

To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID** variable below.

## Step 0 : Sign up for the Image Builder Private Preview

You must register [here](https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR4Mz2uUjMSlGsl9SsCqVlc5UNUFCRDRRTjFJSDJJQTcwWks1UFBGTU8yRi4u), you will be added to the MS Teams channel, where you can ask questions to the dev team and gain access to docs.

For full detailed information, please refer to the documentation on the Azure VM Image Builder [MS Teams channel](https://teams.microsoft.com/l/channel/19%3a03e8b2922c5b44eaaaf3d0c7cd1ff448%40thread.skype/General?groupId=a82ee7e2-b2cc-49e6-967d-54da8319979d&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47).

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
```

If they do not saw registered, run the commented out code below.
```bash
## az provider register -n Microsoft.VirtualMachineImages

## az provider register -n Microsoft.Storage
```

## Set Permissions & Create Resource Group for Image Builder Images

```bash
# set your environment variables here!!!!

# destination image resource group
imageResourceGroup=dansolaibmdiwin2

# location (see possible locations in main docs)
location=WestUS2

# password for test VM
vmpassword=<INSERT YOUR PASSWORD HERE>
# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=<INSERT YOUR SUBSCRIPTION ID HERE>

# name of the image to be created
imageName=aibCustomImgWini01

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

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json -o helloImageTemplateWin.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateWin.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" helloImageTemplateWin.json
sed -i -e "s/<region>/$location/g" helloImageTemplateWin.json
sed -i -e "s/<imageName>/$imageName/g" helloImageTemplateWin.json

```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateWin.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateWin01


# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateWin01 \
     --action Run 

# wait approx 15mins
```

## Step 4 : Create the VM
```bash
az vm create \
  --resource-group $imageResourceGroup \
  --name aibImgVm00 \
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

az group delete -n $imageResourceGroup

```

## Next Steps
* Want to learn more???
    * Explore the documentation in the [MS Teams channel](https://teams.microsoft.com/l/channel/19%3a03e8b2922c5b44eaaaf3d0c7cd1ff448%40thread.skype/General?groupId=a82ee7e2-b2cc-49e6-967d-54da8319979d&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47) (Files).
    * Look at the composition of the Image Builder Template, look in the 'Properties' you will see the source image, customization script it runs, and where it distributes it.

    ```bash
    cat helloImageTemplate.json
    ```

* Want to try more???
* Image Builder does support deployment through Azure Resource Manager, see here in the repo for [examples](https://github.com/danielsollondon/azvmimagebuilder/tree/master/armTemplates), you will also see how you can use a RHEL ISO source too, and manu other capabilities.
