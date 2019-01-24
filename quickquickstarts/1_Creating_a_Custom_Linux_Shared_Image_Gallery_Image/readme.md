# Create a Custom Image, then Distribute and Version over Multiple Regions

This article is to show you how you can create a basic customized image using the Azure VM Image Builder, and then use the Azure [Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries).

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

# register and enable for shared image gallery
az feature register --namespace Microsoft.Compute --name GalleryPreview

# wait until it says registered

# check you are registered for the providers

az provider show -n Microsoft.VirtualMachineImages | grep registrationState

az provider show -n Microsoft.Storage | grep registrationState

az provider show -n Microsoft.Compute | grep registrationState
```

If they do not saw registered, run the commented out code below.
```bash
## az provider register -n Microsoft.VirtualMachineImages

## az provider register -n Microsoft.Storage

## az provider register -n Microsoft.Compute

```

## Step 1 : Set Permissions & Create Shared Image Gallery (SIG)

```bash
# set your environment variables here!!!!

# Create SIG  resource group
sigResourceGroup=aibsig

# location of SIG (see possible locations in main docs)
location=WestUS

# additional region to replication image to
additionalregion=eastus

# your subscription
subscriptionID=<INSERT YOUR SUBSCRIPTION ID HERE>
#<ADD YOUR Az SUBSCRIPTION HERE>

# name of the shared image gallery, e.g. myCorpGallery
sigName=my1stSIG

# name of the image definition to be created, e.g. ProdImages
imageDefName=ubuntu1804images

# create resource group
az group create -n $sigResourceGroup -l $location

# assign permissions for that resource group
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role Contributor \
    --scope /subscriptions/$subscriptionID/resourceGroups/$sigResourceGroup

# create SIG
az sig create \
    -g $sigResourceGroup \
    --gallery-name $sigName

# create SIG image definition

az sig image-definition create \
   -g $sigResourceGroup \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefName \
   --publisher corpIT \
   --offer myOffer \
   --sku 18.04-LTS \
   --os-type Linux
```


## Step 2 : Modify HelloImage Example

```bash
# download the example and configure it with your vars

curl https://github.com/danielsollondon/azvmimagebuilder/blob/master/quickquickstarts/1_Creating_a_Custom_Linux_Shared_Image_Gallery_Image/helloImageTemplateforSIG.json -o helloImageTemplateforSIG.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateforSIG.json
sed -i -e "s/<rgName>/$sigResourceGroup/g" helloImageTemplateforSIG.json
sed -i -e "s/<imageDefName>/$imageDefName/g" helloImageTemplateforSIG.json
sed -i -e "s/<sharedImageGalName>/$sigName/g" helloImageTemplateforSIG.json

sed -i -e "s/<region1>/$location/g" helloImageTemplateforSIG.json
sed -i -e "s/<region2>/$additionalregion/g" helloImageTemplateforSIG.json

```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $sigResourceGroup \
    --properties @helloImageTemplateforSIG.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateforSIG01


# start the image build

az resource invoke-action \
     --resource-group $sigResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateforSIG01 \
     --action Run 

# wait approx 35mins (this includes replication time to both regions)
```


## Step 4 : Create the VM

```bash
az vm create \
  --resource-group $sigResourceGroup \
  --name azaibvm1 \
  --admin-username aibuser \
  --image "/subscriptions/$subscriptionID/resourceGroups/$sigResourceGroup/providers/Microsoft.Compute/galleries/$sigName/images/$imageDefName/versions/latest" \
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
    --resource-group $sigResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
     --action Run 
    -n helloImageTemplateforSIG01

az sig delete -r $sigName -g $sigResourceGroup

az group delete -n $sigResourceGroup
```

## Next Steps
* Want to learn more???
    * Explore the documentation in the [MS Teams channel](https://teams.microsoft.com/l/channel/19%3a03e8b2922c5b44eaaaf3d0c7cd1ff448%40thread.skype/General?groupId=a82ee7e2-b2cc-49e6-967d-54da8319979d&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47) (Files).
    * Look at the composition of the Image Builder Template, look in the 'Properties' you will see the source image, customization script it runs, and where it distributes it.

    ```bash
    cat helloImageTemplateforSIG.json
    ```

* Want to try more???
* Image Builder does support deployment through Azure Resource Manager, see here in the repo for [examples](https://github.com/danielsollondon/azvmimagebuilder/tree/master/armTemplates), you will also see how you can use a RHEL ISO source too, and manu other capabilities.
