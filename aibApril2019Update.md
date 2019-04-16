# Azure VM Image Builder March 2019 Update

Release Date : 15th April 2100 PST
This is an exciting release, this is the high level:
* We now have enabled the Azure Shared Image Gallery as a source, incombination with the Azure VM Image Builder, you now how a full image management system, with image versioning, region replication, scale management, and Role Based Access. 
* Ability to copy in files to the image, such as you build share files, without having to write your own code.

## Feature Details
* Additional Source
    * SharedImageVersion - Use existing Shared Image Gallery (SIG) images - Take your SIG image version as a source, you can customize, then put it back into the SIG, and then recustomize that version again. This is currently Linux only, but expect Windows support very soon!!!
* Additional Customizer
    * File - Select a location for your files and destination path inside your image, then image builder will handle the rest.

## New Microsoft.VirtualMachineImages API Version : 2019-05-01-preview 
The new API version is required for all the additional features listed, this will also become the default API used by Azure Resource Manager and Azure CLI. If you submit your templates now, it will require you to update you AIB configuration templates.

## Action : Update Your AIB Configuration Templates
In the 2019-05-01-preview API there are two breaking changes between 2019-05-01-preview and 2019-02-01-preview APIs.

* customize 
    * type:Shell
        * 'script' property is now 'scriptUri'
    * type:PowerShell
        * 'script' property is now 'scriptUri'

Example:
```json
        "customize": [
            {
                "type": "PowerShell",
                "name": "CreateBuildPath",
                "scriptUri": "https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/testPsScript.ps1"
            },
```
        
* distribute
    * type: All distribution types except 'VHD'
    * 'tags' property is now 'artifactTags'

Example:
```json
        "distribute": 
        [
            {   
                "type": "SharedImage",
                "galleryImageId": "/subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/galleries/<sharedImageGalName>/images/<imageDefName>",
                "runOutputName": "<imageDefName>",
                "artifactTags": {
                    "source": "azureVmImageBuilder",
                    "baseosimg": "ubuntu1804"
                },
                "replicationRegions": [
                  "<region1>",
                  "<region2>"
                ]
            }
        ]
    }
```

If you try to deploy your 2019-02-01-preview API Image Builder templates after this May release, these will fail with incorrect type errors. 

### Remediation
#### Update your templates
Please review your templates against the changes to the type properties above, and update the AIB configuration template apiVersion to '2019-05-01-preview'. 

```json
    "type": "Microsoft.VirtualMachineImages",
    "apiVersion": "2019-05-01-preview",
```
#### Defer template updates
If you want to continue using the previous API version, you can leave the templates as-is, then update the CLI command for creating the template and building the image:

```bash
az resource create \
    --resource-group $imageResourceGroup \
    --properties @<aib-2019-02-01-Template>.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    --api-version "2019-02-01-preview"  \
    -n <templateName>

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n <templateName> \
     --api-version "2019-02-01-preview"  \
     --action Run 
```
>> Note! This should be a short term workaround!

## Documentation
This will be updated once the release has been completed.