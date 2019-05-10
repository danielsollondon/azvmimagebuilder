# Create a Custom Image from a RHEL ISO, then Distribute and Version over Multiple Regions

This article is to show you how you can create a customized image using the Azure VM Image Builder from a RHEL ISO, and distribute to two Azure regions..

To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID, rhelChecksum, rhelLinkAddress** variables below.

## Step 1 : Enable Prereqs

Happy Image Building!!!

### Licences
Ensure you have eligible Red Hat licences in your Red Hat subscription.

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
sigResourceGroup=aibRhelRgSig

# location (see possible locations in main docs)
location=westUS2

# additional region to replication image to
additionalregion=eastus

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=<INSERT YOUR SUBSCRIPTION ID HERE>

# name of the shared image gallery, e.g. myCorpGallery
sigName=my3rdSIG

# image distribution metadata reference name
runOutputName=aibCustRhSigImg01ro

# name of the image definition to be created, e.g. ProdImages
imageDefName=rhel75

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
   --sku 7.5-CI \
   --os-type Linux

```
### Get Red Hat ISO details in Red Hat Customer Portal

Go to the Red Hat Customer Portal > Downloads > Red Hat Enterprise Linux > Product Software

Product Variant : Red Hat Enterprise Linux Server
Version > 7.3 - 7.5 (7.6 is scheduled for testing).

For example, for 7.5:
https://access.redhat.com/downloads/content/69/ver=/rhel---7/7.5/x86_64/product-software

You then need to go to:
Red Hat Enterprise Linux 7.x Binary DVD

1. Copy SHA-256 Checksum and set variable below
2. Right click on 'Download Now' and 'Copy Link Address'

![alt text](./rhcustomerportalpic1.png "ISO Steps")

```bash
# paste checksum here
rhelChecksum="<INSERT CHECKSUM HERE>"

# link address must be in double quotes
rhelLinkAddress="<INSERT LINK ADDRESS HERE>"

```

## Step 2 : Modify HelloImage Example

```bash
# download the example and configure it with your vars

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/3_Creating_a_Custom_Image_using_Red_Hat_Subscription_Licences_SIG/helloImageTemplateRhelByosSig.json -o helloImageTemplateRhelByosSig.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateRhelByosSig.json
sed -i -e "s/<rgName>/$sigResourceGroup/g" helloImageTemplateRhelByosSig.json

sed -i -e "s/<rhelChecksum>/$rhelChecksum/g" helloImageTemplateRhelByosSig.json

sed -i -e "s%<rhelLinkAddress>%$rhelLinkAddress%g" helloImageTemplateRhelByosSig.json
sed -i -e "s/<rhelLinkAddress>/\&/g" helloImageTemplateRhelByosSig.json

sed -i -e "s/<imageDefName>/$imageDefName/g" helloImageTemplateRhelByosSig.json
sed -i -e "s/<sharedImageGalName>/$sigName/g" helloImageTemplateRhelByosSig.json

sed -i -e "s/<region1>/$location/g" helloImageTemplateRhelByosSig.json
sed -i -e "s/<region2>/$additionalregion/g" helloImageTemplateRhelByosSig.json

sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateRhelByosSig.json
```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $sigResourceGroup \
    --properties @helloImageTemplateRhelByosSig.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateRhelByosSig001

# wait approx 15mins (AIB is downloading the ISO)


# start the image build

az resource invoke-action \
     --resource-group $sigResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateRhelByosSig001 \
     --action Run 

# wait approx 15mins
```

## Step 4 : Create the VM

```bash
az vm create \
  --resource-group $sigResourceGroup \
  --name aibImgVm02 \
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
# BEWARE : This is DELETING the Image created for you, be sure this is what you want!!!

az resource delete \
    --resource-group $sigResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateRhelByosSig001

# get image version created by AIB, this always starts with 0.*
sigDefImgVersion=$(az sig image-version list \
   -g $sigResourceGroup \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefName \
   --subscription $subscriptionID --query [].'name' -o json | grep 0. | tr -d '"')

# delete image version
az sig image-version delete \
   -g $sigResourceGroup \
   --gallery-image-version $sigDefImgVersion \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefName \
   --subscription $subscriptionID

# delete image definition
az sig image-definition delete \
   -g $sigResourceGroup \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefName \
   --subscription $subscriptionID

# delete SIG
az sig delete -r $sigName -g $sigResourceGroup

# delete RG
az group delete -n $sigResourceGroup -y
```

## Next Steps
* Want to learn more???
    * Explore the documentation in the [MS Teams channel](https://teams.microsoft.com/l/channel/19%3a03e8b2922c5b44eaaaf3d0c7cd1ff448%40thread.skype/General?groupId=a82ee7e2-b2cc-49e6-967d-54da8319979d&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47) (Files).
    * Look at the composition of the Image Builder Template, look in the 'Properties' you will see the source image, customization script it runs, and where it distributes it.

    ```bash
    cat helloImageTemplateRhelByosSig.json
    ```

* Want to try more???
* Image Builder does support deployment through Azure Resource Manager, see here in the repo for [examples](https://github.com/danielsollondon/azvmimagebuilder/tree/master/armTemplates), you will also see how you can use a RHEL ISO source too, and manu other capabilities.
