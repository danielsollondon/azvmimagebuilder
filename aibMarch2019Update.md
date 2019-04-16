# Azure VM Image Builder March 2019 Update

Release Date : 12th March 1600 PST

## Features
* Windows Server Support
* Additional Customizers
    * Windows PowerShell (Script and Inline)
    * Windows-Restart
    * Linux Shell Inline command support
* Image Build Logs - for troubleshooting
* Use existing Custom Managed Images as a Base Image (Currently Linux only)
* Export Images to VHD

## New Microsoft.VirtualMachineImages API Version : 2019-02-01-preview 
The new API version is required for all the additional features listed, this will also become the default API used by Azure Resource Manager and Azure CLI. When the 2019-02-01-preview API version is released, it will require you to update you AIB configuration templates.

## Action : Update Your AIB Configuration Templates
In the 2019-02-01-preview API there are multiple types, such as specifying source, customizers, distribute targets. 

The "type" naming format is being changed between the 2018-02-01-preview and 2019-02-01-preview APIs, to Upper Camel Case, for example, distributing to the Shared Image Gallery in 2018-02-01-preview API, would use the distribute type *sharedImage*, now in the 2019-02-01-preview API is *SharedImage*.

If you try to deploy your 2018-02-01-preview API Image Builder templates after this March release, these will fail with incorrect type errors. 

### Remediation
#### Update your templates
Please review your templates against all these types used, below is the list of supported types in 2019-02-01-preview API.

* Source
    * ManagedImage
    * PlatformImage
    * ISO 
* Customize
    * Shell
    * PowerShell
    * Windows-Restart
* Distribute
    * ManagedImage
    * SharedImage
    * VHD

Update the AIB configuration template apiVersion to '2019-02-01-preview'. 

```json
    "type": "Microsoft.VirtualMachineImages",
    "apiVersion": "2019-02-01-preview",
```
#### Defer template updates
If you want to continue using the previous API version, you can leave the templates as-is, then update the CLI command for creating the template and building the image:

```bash
az resource create \
    --resource-group $imageResourceGroup \
    --properties @<aib2018Template>.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    --api-version "2018-02-01-preview"  \
    -n <templateName>

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n <templateName> \
     --api-version "2018-02-01-preview"  \
     --action Run 
```
>> Note! This should be a short term workaround!

## Documentation
This will be updated once the release has been completed.