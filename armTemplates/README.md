# Deploying Image Builder Templates with Azure Resource Manager (ARM) 
This repo contains deployment templates and parameters files - this will allow you to create an ImageTemplate immediately using ARM. The beauty of these examples, they are heavily parameterized, so you just need to drop in your own details, then begin image building! 

There are two files required for creating the Image Template, deployment template and parameters file, you can recognise the pair, as the only difference in the file name is 'deploy' and 'param', for example:
* rhel_iso_image_params_mdi.json - parameters file
* rhel_iso_image_deploy_mdi.json - associated deployment template file

Format:
'<source>_<template_type>_<distribution_target>.json'

* source e.g. iso or azplatform (azure marketplace image (Ubuntu))
* template_type e.g. deploy or params, deploy is the ARM deployment template, the params represents the parameter file, which you will need to apply your own settings.
* distribution_target e.g. mdi (managed disk image) or sig (shared image gallery)
* All examples include at least 1 customization


e.g.
* rhel_iso_image_deploy_sigmdi.json - RHEL 73 ISO, ARM deployment template, distributing to Shared Image Gallery (SIG), and MDI (Managed Image)
* azplatform_image_params_sig.json - Azure Platform Image, ARM parameters file, distributing to Shared Image Gallery (SIG).

## How to deploy the templates using ARM
Once you have copied the parameters file locally and populated, note the Image Template Name, you will need this to invoke the image build.

**!! NOTE !!**
* Ensure the Shared Image Gallery and Image Definition is created before you continue!! See the [SIG Quick QuickStarts](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/1_Creating_a_Custom_Linux_Shared_Image_Gallery_Image).
* If using a source Platform Image, the version cannot be 'latest'.

### Submit the Image Template to the VM Image Builder
```bash
# template path must be the RAW git path!

declare resourceGroupName=""
declare deploymentName=""
declare templateFilePath="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/armTemplates/azplatform_image_deploy_sigmdi.json"
declare parametersFilePath="pathToLocalParamsFile.json"

az group deployment create --name $deploymentName --resource-group $resourceGroupName --template-uri $templateFilePath --parameters $parametersFilePath 
```

### Create image
```bash
az resource invoke-action \
     --resource-group <rgname> \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n <imageTemplateName> \
     --action Run 
```

### Check image build status
```bash
az resource show \
    --resource-group <rgname> \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n <imageTemplateName>
```
### Deleting image artifact
This will remove the image artifact, and its associated resource group, that is used to store image artifact metadata, such as the RHEL ISO, and shell scripts, you can identify the resource group, as it is named in this format *IT_<DestinationResourceGroup>_<TemplateName>*.

*!!DO NOT delete the Image Builder Resource Groups directly, or try to modify them, to remove them, delete the image artifact, as shown below!!*

Deleting the image template artifact will not delete any created images, this is purely metadata just used by the image builder.

```bash
az resource delete \
    --resource-group <rgname> \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n <imageTemplateName>
```
### Create a VM

#### Managed Image Image
```bash
az vm create \
  --resource-group <vmResourceGroup> \
  --name <vmName> \
  --location <region - must be the same as image> \
  --admin-username <userName> \
  --image /subscriptions/<subid>/resourceGroups/<imageResourceGroup>/providers/Microsoft.Compute/images/<managedImagename> \
  --ssh-key-value /../.../.pub    
```
#### Shared Image Gallery Image
```bash
az vm create \
  --resource-group <vmResourceGroup> \
  --name <vmName> \
  --location <region - must be the same as image> \
  --admin-username <userName> \
  --image /subscriptions/<subid>/resourceGroups/<imageResourceGroup>/providers/Microsoft.Compute/galleries/<imageGalName>/images/<ImageDefintionName>/versions/<ImageDefintionVersion> \
  --ssh-key-value /../.../.pub   
```