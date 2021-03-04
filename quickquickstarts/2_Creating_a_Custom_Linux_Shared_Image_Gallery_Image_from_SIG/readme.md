# Create a Custom Image, from an existing Shared Image Gallery Custom Image then Distribute and Version over Multiple Regions

> **MAY 2020 SERVICE ALERT** - Existing users, please ensure you are compliant this [Service Alert by 26th May!!!](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review)

This article shows using Image Builder you how you can create a basic customized image from an existing custom image in the Azure [Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries).

This Quick Start assumes you have completed 1_Creating_a_Custom_Linux_Shared_Image_Gallery_Image, and therefore the variables below, will be preset to those variable names, for continuity, but you can always update them yourself.

To use this Quick Quickstarts, this can all be done using the Azure [Cloudshell from the Portal](https://azure.microsoft.com/en-us/features/cloud-shell/). Simply copy and paste the code from here, at a miniumum, just update the **subscriptionID** variable below.

## Step 1 : Set Permissions & Create Shared Image Gallery (SIG)

```bash
# set your environment variables here!!!!

# Create SIG  resource group
sigResourceGroup=aibsig

# location of SIG (see possible locations in main docs)
location=westus

# additional region to replication image to
additionalregion=eastus

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=$(az account show | grep id | tr -d '",' | cut -c7-)

# name of the shared image gallery to used, e.g. myCorpGallery
sigName=my21stSIG

# name of the image definition to be used, e.g. ProdImages
imageDefName=ubuntu1804images

# image distribution metadata reference name
runOutputName=u1804SigRo2

# get image version created in SIG from previous example
sigDefImgVersionId=$(az sig image-version list \
   -g $sigResourceGroup \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefName \
   --subscription $subscriptionID --query [].'id' -o json | grep 0. | tr -d '"' | tr -d '[:space:]' )

IFS=","
arr=($sigDefImgVersionId)
for i in "${!arr[@]}";do
echo Item $i:"${arr[$i]}"
done
unset IFS
echo "Completed"
latestSigId=${arr[@]:(-1)}

echo INFO Latest Image version : $latestSigId
```

>>Note! If you already have your own Shared Image Gallery, and did not follow the previous example, you will need to assign permissions for Image Builder to access the Resource Group, so it can access the SIG.

### Assign AIB user identiy permissions to distribute a Managed Image or Shared Image 
If you are continuing from *1_Creating_a_Custom_Linux_Shared_Image_Gallery_Image*, run this:

```bash
#get identity used previously
imgBuilderId=$(az identity list -g $sigResourceGroup --query "[?contains(name, 'aibBuiUserId')].id" -o tsv)
```
#### Optional
If you have NOT run *1_Creating_a_Custom_Linux_Shared_Image_Gallery_Image*, or cleaned up, you must run:
```bash
# create user assigned identity for image builder to access the storage account where the script is located
idenityName=aibBuiUserId$(date +'%s')
az identity create -g $sigResourceGroup -n $idenityName

# get identity id
imgBuilderCliId=$(az identity show -g $sigResourceGroup -n $idenityName | grep "clientId" | cut -c16- | tr -d '",')

# get the user identity URI, needed for the template
imgBuilderId=/subscriptions/$subscriptionID/resourcegroups/$sigResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$idenityName

# download preconfigured role definition example
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

imageRoleDefName="Azure Image Builder Image Def"$(date +'%s')

# update the definition
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$sigResourceGroup/g" aibRoleImageCreation.json
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json

# create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json

# grant role definition to the user assigned identity
az role assignment create \
    --assignee $imgBuilderCliId \
    --role $imageRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$sigResourceGroup

```

## Step 2 : Modify HelloImage Example

```bash

# download the example and configure it with your vars

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/2_Creating_a_Custom_Linux_Shared_Image_Gallery_Image_from_SIG/helloImageTemplateforSIGfromSIG.json -o helloImageTemplateforSIGfromSIG.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateforSIGfromSIG.json
sed -i -e "s/<rgName>/$sigResourceGroup/g" helloImageTemplateforSIGfromSIG.json
sed -i -e "s/<imageDefName>/$imageDefName/g" helloImageTemplateforSIGfromSIG.json
sed -i -e "s/<sharedImageGalName>/$sigName/g" helloImageTemplateforSIGfromSIG.json
sed -i -e "s%<sigDefImgVersionId>%$latestSigId%g" helloImageTemplateforSIGfromSIG.json

sed -i -e "s/<region1>/$location/g" helloImageTemplateforSIGfromSIG.json
sed -i -e "s/<region2>/$additionalregion/g" helloImageTemplateforSIGfromSIG.json
sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateforSIGfromSIG.json

sed -i -e "s%<imgBuilderId>%$imgBuilderId%g" helloImageTemplateforSIGfromSIG.json

```

## Step 3 : Create the Image

```bash
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $sigResourceGroup \
    --properties @helloImageTemplateforSIGfromSIG.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateforSIGfromSIG01


# start the image build

az resource invoke-action \
     --resource-group $sigResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateforSIGfromSIG01 \
     --action Run 

# wait minimum of 30mins (this includes replication time to both regions)
```


## Step 4 : Create the VM

```bash
az vm create \
  --resource-group $sigResourceGroup \
  --name aibImgVm001 \
  --admin-username aibuser \
  --location $location \
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
# BEWARE : This is DELETING the Image created for you, be sure this is what you want!!!

# delete AIB Template
az resource delete \
    --resource-group $sigResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateforSIGfromSIG01

# delete role assignment
az role assignment delete \
    --assignee $imgBuilderCliId \
    --role $imageRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$sigResourceGroup

az role definition delete --name $imageRoleDefName

az identity delete --ids $imgBuilderId

# list image versions created by AIB, this always starts with 0.*
az sig image-version list \
   -g $sigResourceGroup \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefName \
   --subscription $subscriptionID --query [].'name' -o json | grep 0. | tr -d '"'

# For each image version, run the delete cmd:
az sig image-version delete \
   -g $sigResourceGroup \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefName \
   --subscription $subscriptionID \
   --gallery-image-version <imageVersionNumber>
   #<imageVersionNumber e.g. 0.23725.5933> \

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
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../quickquickstarts/nextSteps.md)]
