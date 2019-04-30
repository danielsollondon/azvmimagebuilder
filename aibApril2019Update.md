# Azure VM Image Builder April 2019 Update

Release Date : 30th April 0900 PST
This is an exciting release, there is just so much, here is the high level:
* Patch your Windows Custom Images
    * Now you can select existing [Windows Custom SIG Images](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/8_Creating_a_Custom_Win_Shared_Image_Gallery_Image_from_SIG) and [Custom Windows Managed Images](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image)!!!
* Seamless authentication with Azure Storage
    * No need to create file or script URLs with externally accessible SAS tokens on blobs anymore!! Image Builder now supports using [Managed User-Assigned Identity](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/7_Creating_Custom_Image_using_MSI_to_Access_Storage) and authenticating with Azure storage accounts. Smooth...yesss!!!
* [Azure Shared Image Gallery](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/8_Creating_a_Custom_Linux_Shared_Image_Gallery_Image_from_SIG) as a source
    * In combination with the Azure VM Image Builder, you now have a full image management system, with image versioning, region replication, scale management, and Role Based Access. 
* [Add in files to the image](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image)
    * Such as your build share files, without having to write your own code.
* Support for [long duration image builds](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image)
    * Previously image builder was set to a 60min build timeout, now you can override this upto 16hrs.
* Abililty to [override the Image Builder deprovision commands](https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md#vms-created-from-aib-images-do-not-create-successfully)
    * By default Image Builder run commands that prepare the image for reuse for you. The commands are either Windows Sysprep, or Linux waagent command. However, we are aware that many users will have custom Sysprep and waagent commands to work with certain software installs.


## Feature Details
See documentation from MS Teams site for full details.

* Additional Template Properties
    * [buildTimeoutMinutes](https://github.com/danielsollondon/azvmimagebuilder/blob/1e720cf4f078f2b9c48ff3ff6882dd89a984af9e/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json#L11) - Customize your build timeout.
    * [identity](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/7_Creating_Custom_Image_using_MSI_to_Access_Storage) - Add in your Azure MSI user identify.
    * [tags](https://github.com/danielsollondon/azvmimagebuilder/blob/1e720cf4f078f2b9c48ff3ff6882dd89a984af9e/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json#L6) - Add tags to the template.
* Additional Source
    * [SharedImageVersion](https://github.com/danielsollondon/azvmimagebuilder/blob/1e720cf4f078f2b9c48ff3ff6882dd89a984af9e/quickquickstarts/8_Creating_a_Custom_Win_Shared_Image_Gallery_Image_from_SIG/helloImageTemplateforSIGfromWinSIG.json#L8) - Use existing Shared Image Gallery (SIG) images - Take your SIG image version as a source, you can customize, then put it back into the SIG, and then recustomize that version again. 
* Additional Customizer
    * [File](https://github.com/danielsollondon/azvmimagebuilder/blob/1e720cf4f078f2b9c48ff3ff6882dd89a984af9e/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json#L30) - Select a location for your files and destination path inside your image, then image builder will handle the rest.
* [Additional Deprovision Command Customization](https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md#vms-created-from-aib-images-do-not-create-successfully)
    * You can add your own deprovision command in a file, then this will be read and executed by Image Builder.


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