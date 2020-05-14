# Updating Image Builder Templates

> **MAY 2020 SERVICE ALERT** - Existing users, please ensure you are compliant this [Service Alert by 26th May!!!](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review)

Once you submit an Image Builder Template to the service and it is stored as an Image Builder Template artifact, you cannot update it. We have heard asks to support updating Image Builder Template artifacts, we are looking at ways this can be done, and would welcome your feedback on the ways you want this to work, on MS Teams.

One way you could workaround this, is creating multiple templates using a name versioning.

A later date, we will document a PS version of the below.

## Examples : Linux
1. You modify the AIB json template, add in an version tag. 
As of ApiVersion "2019-05-01-preview", we now have the ability to add tags to the image builder template, so you can add a tag there for the version, and put a placeholder : "templateVersion"

```json
{
    "type": "Microsoft.VirtualMachineImages/imageTemplates",
    "apiVersion": "2019-05-01-preview",
    "location": "<region>",
    "tags":{
        "templateVersion" : "<imgTemplateName>"
    },
    "dependsOn": [],
    "properties": {
        "source": {
            "type": "PlatformImage",
```

2.  Create an Image Name Variable with using Epoch time

In the existing quick starts, you can modify the examples:

* Add a template name variable
```bash
# image template name

imgTemplateName=helloImageTemplateWin01-$(date +'%s')
```
* Update the place holder
```bash
sed -i -e "s/<imgTemplateName>/$imgTemplateName/g" helloImageTemplateVersion.json
```

# Submit the image confiuration to the VM Image Builder Service
3. When you submit it to AIB, you use the variable for the template name.
```bash
az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateVersion.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n $imgTemplateName
# wait approx 1-3mins, depending on external links

# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n $imgTemplateName \
     --action Run 

# wait approx 15mins

# delete, if needed
az resource delete \
    --resource-group $imageResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n $imgTemplateName
```
