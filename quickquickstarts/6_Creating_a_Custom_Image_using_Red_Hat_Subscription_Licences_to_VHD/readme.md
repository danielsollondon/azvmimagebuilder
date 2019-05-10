# Create a custom RHEL image using a RHEL ISO where you can use eligible Red Hat licences and export to VHD

This article is to show you how you can create a basic customized RHEL image using the Azure VM Image Builder and export it to VHD.

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
imageResourceGroup=aibRhelRgVhd

# location (see possible locations in main docs)
location=westUS2

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=<INSERT YOUR SUBSCRIPTION ID HERE>

# name of the image to be created
runOutputName=aibCustomRHELRoVhd01

# create resource group
az group create -n $imageResourceGroup -l $location

# assign permissions for that resource group
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role Contributor \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

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

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/6_Creating_a_Custom_Image_using_Red_Hat_Subscription_Licences_to_VHD/helloImageTemplateRhelBYOSVhd.json -o helloImageTemplateRhelBYOSVhd.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateRhelBYOSVhd.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" helloImageTemplateRhelBYOSVhd.json
sed -i -e "s/<region>/$location/g" helloImageTemplateRhelBYOSVhd.json
sed -i -e "s/<rhelChecksum>/$rhelChecksum/g" helloImageTemplateRhelBYOSVhd.json
sed -i -e "s%<rhelLinkAddress>%$rhelLinkAddress%g" helloImageTemplateRhelBYOSVhd.json
sed -i -e "s/<rhelLinkAddress>/\&/g" helloImageTemplateRhelBYOSVhd.json
sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateRhelBYOSVhd.json
```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateRhelBYOSVhd.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateRhelBYOSVhd01

# wait approx 15mins (AIB is downloading the ISO)


# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateRhelBYOSVhd01 \
     --action Run 

# wait approx 15mins
```

## Step 4 : Get the URL to the VHD
```bash
az resource show \
    --ids "/subscriptions/$subscriptionID/resourcegroups/$imageResourceGroup/providers/Microsoft.VirtualMachineImages/imageTemplates/helloImageTemplateRhelBYOSVhd01/runOutputs/$runOutputName"  \
    --api-version=2019-05-01-preview | grep artifactUri
```

>>Note!! Once the VHD has been created, copy it to an alternative location, as soon as possible. The VHD is stored in a storage account in the temporary Resource Group created when the Image Template is submitted to the AIB service. If you delete the Image Template, then you will loose this VHD. 

## Clean Up
```bash
az resource delete \
    --resource-group $imageResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateRhelBYOSVhd01

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
