# Quick Quickstarts : Hello Image Examples

## Step 0 : Register for the Image Builder Private Preview
<<<>>>
## Step 1 : Enable Prereqs:

### Register for Image Builder / VM / Storage Features
```bash
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview

az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview

## until it says registered

az provider register -n Microsoft.VirtualMachineImages

az provider show -n Microsoft.VirtualMachineImages

az provider register -n Microsoft.Storage
```
### Set Permissions for Image Builder

## Create Resource Group for Image Builder Images

```bash
# set variables

# destination image resource group
imageResourceGroup=imageRg

# location (see possible locations in main docs)
location=WestUS2

# your subscription
subcriptionID=



az group create -n $aibResourceGroup -l $location

az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role Contributor \
    --scope /subscriptions/$subcriptionID/resourceGroups/$aibResourceGroup
```

## Step 2 : Modify HelloImage Example

```bash
# download the example

curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/helloImageTemplate.json -o helloImageTemplate.json


```