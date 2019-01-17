# Raw Image Builder Templates
These are examples of Azure VM Image Builder Template, you can use these when submitting an Image Template directly to the Azure Resource Provider, and they are also good for understanding basic templates. If you want to see a full example in an Azure Resource Manager Template (ARM), see [here](https://github.com/danielsollondon/azvmimagebuilder/tree/master/armTemplates).

Format:
'<os_major_minor>_<source>_<number of customizations>_<distribution_target>.json'

* os_major_minor e.g. rhel73
* source e.g. iso or mp (azure marketplace image)
* number of customizations e.g. 1customize
* distribution_target e.g. mdi (managed disk image) or sig (shared image gallery)

e.g.
* rhel73_iso_1customize_sigmdi
* ubuntu1804_mp_1customize_mdi

## How to deploy the templates using ARM

*!! If you are using Shared Image Gallery, you must ensure the Shared Image Gallery and Image Definition is created before you continue!!*

### Submit the Image Template to the VM Image Builder
```bash
az resource create --resource-group <rgname> --properties @/.../templateName.json --is-full-object --resource-type Microsoft.VirtualMachineImages/imageTemplates -n <imageTemplateName> 
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

**!! NOTE !!**
* Ensure the Shared Image Gallery and Image Definition is created before you continue!!
* If using a Platform Image, the version cannot be 'latest'.

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