# Azure VM Image Builder Template Repo

## Service Updates and Latest Release Information


Release Date : 1st June 0900 PST

## Features
* NEW Api `2020-02-14`, containing:
    * Distribute updates:
        * Support for more Shared Image Gallery (SIG) properties:
            * Specify your own SIG version
            * storageAccountType
            * excludeFromLatest
    * Source updates:
        * Support for Plan_Info
        * Specify paid Market Place Offerings as a source
    * Control Plane updates:
        * Cancel build - You can now cancel a running build!
*  Security model updates:
    * Simplified model - Now you do not grant the AIB permissions to your resources, now you use a single user identity, for more details see the [May 2020 Update](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review).
* DevOps Task Actions Required and Updates
    * **The existing AIB task, 'stable' will be updated on *4th June* to support user identity and the new API. This will break existing deployments, For more details see [here](https://aka.ms/azvmimagebuilderdevops).**
    * We now have an ['Unstable' AIB Task](https://marketplace.visualstudio.com/items?itemName=AzureImageBuilder.devOps-task-for-azure-image-builder-canary), this allows us to put in the latest updates and features, allow customers to test them, before we promote it to the 'stable' task, approx 1 week later. 
    * Support has been added to the task to support user identity.
    * Mutliple Bug fixes to address source custom images
    

## Deprecations & Notifications
* As of the 4th of June, the service will reject templates that do not contain "identity", with a user assigned identity. 
* This means any templates created before `2019-05-01-preview` will not be run, and not supported.
* The `2020-02-14` API requires:
    * identity is mandatory
    * vnetConfig is now one property, `subnetId`, this is the resourceID of the subnet.
* Please see the [May 2020 Update]() for details on how to mitigate the above.


## Whats coming!
* AIB AZ CLI module / PS cmdlets - this will simplify the image creation even more!
* GA - Early Q3 2020

## June 2020 Update

## More details on features in API `2020-02-14`!
These details are being added to Azure docs and examples now, but for those who want a sneak peak...

### Support for more Shared Image Gallery (SIG) Properties
* Specify your own SIG version (optional)
Previously AIB would automatically generate a montonic version based on datetime, this works well if you just want to keep re-running the template every month, as you don't need to modify the SIG distribution. However, feedback was that many customers would like to use existing versioning schemes, to use these, simply append a version to the SIG resourceID:


```json
"galleryImageId": "/subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/galleries/<sharedImageGalName>/images/<imageDefName>/versions/1.1.1"
}
```
* storageAccountType (optional)
AIB supports specifying these types of storage for the image version that is to be created:
   * "Standard_LRS"
   * "Standard_ZRS"

For more information on these options, see [SIG documentation](https://docs.microsoft.com/en-us/cli/azure/sig/image-version?view=azure-cli-latest#az-sig-image-version-create-optional-parameters)
* excludeFromLatest (optional)
This allows you to mark the image version you create not be used as the latest version in the SIG definition, the default is 'false'.

A complete example, showing all the properties:
```json
{   
    "type": "SharedImage",
    "galleryImageId": "/subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/galleries/<sharedImageGalName>/images/<imageDefName>//versions/1.1.1",
    "runOutputName": "<runOutputName>",
    "artifactTags": {
        "source": "azureVmImageBuilder",
        "baseosimg": "windows2019"
    },
    "replicationRegions": [
        "<region1>",
        "<region2>"
    ],
    "storageAccountType" : "Standard_ZRS",
    "excludeFromLatest" : true

}
```
#### Support for Plan_Info
Specify paid Market Place Offerings as a source:
```json
    "source": {
        "type": "PlatformImage",
        "publisher": "RedHat",
        "offer": "rhel-byos",
        "sku": "rhel-lvm75",
        "version": "7.5.20190620",
        "planInfo": {
            "planName": "rhel-lvm75",
            "planProduct": "rhel-byos",
            "planPublisher": "redhat"
       }
```
#### Cancel a running build
If you are running an image build that you believe is incorrect, waiting for user input, or you feel will never complete successfully, then you can cancel the build.

The build can only be cancelled during the customization phase, if the distribution phase has started you cannot cancel, and you will need to wait for the distribution to occur.

Examples of `cancel` commands:

```powerShell
Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion >> API  "2019-05-01-preview" -Action Cancel -Force
```

```bash
az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n helloImageTemplateLinux01 \
     --action Cancel 
```


> **MAY 2020 SERVICE ALERT** - Existing users, please ensure you are compliant this [Service Alert by 26th May!!!](https://github.com/danielsollondon/azvmimagebuilder#service-update-may-2020-action-needed-by-26th-may---please-review)


Get started now, this repo contains mutliple examples and test templates for Azure VM Image Builder (Public Preview).

What is Image Builder??
Get started with the short intro video below, or go straight to the Quick Starts below.


[<img src="./introToAIB.png" alt="drawing" width="325"/>](https://youtu.be/nalr2rHRDew)


1. [Quick QuickStarts Examples](/quickquickstarts/readme.md).
You can run these immediately using the Azure CloudShell from the Portal, and see multiple scenarios that the VM Image Builder supports. 


2. [Azure Resource Manager (ARM) Image Builder Examples](/armTemplates/README.md). 
The beauty of these examples, they are heavily parameterized, so you just need to drop in your own details, then begin image building, or integrate them to existing pipelines.


## SERVICE UPDATE May 2020: ACTION NEEDED by 26th May - Please Review

We are making key changes to Azure Image Builder security model, this will be a breaking change, therefore we require you to take these before **26th May 0700 Pacific Time**.

**The change** - Azure Image Builder Templates (AIB) **must** contain a populated [`identity`](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json#identity) property, and the user assigned identity **mus**t have permissions to read and write images.

**Impact** - From the 26th May 0700 we will not accepting any new AIB Templates or process existing AIB Templates that do not contain a populated [`identity`](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json#identity). This also means any templates being submitted with api versions earlier than `2019-05-01-preview` will not be be accepted either.

**Why?** - As well as allow us to prepare for future features, we are simplifying and improving the AIB security model, so instead of you granting permissions the AIB Service Principal Name, to build and distribute custom images, and then a user identity to you will now use a single user identity to get access to other Azure resources.

## Actions Required
### [1. Create a user assigned 'identity'](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#1-create-a-user-assigned-identity)

### [2. Grant the permissions to the user assigned identity to the resource groups](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#2-grant-the-permissions-to-the-user-assigned-identity-az-cli-powershell-to-the-resource-groups)

### 3. [Update your JSON templates with the `identity` property.](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#3-update-your-json-templates-with-the-identity-adding-this-property-to-the-template)

### 4. [Submit your JSON template to the service.](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#4-submit-your-json-template-to-the-service)

### 5. [Remove the old version of the template that does not contain property.](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#5-remove-the-old-version-of-the-template-that-does-not-contain-property)

### 6. [Remove previously granted role assignments from the SPN](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#6-remove-previously-granted-role-assignments-from-the-spn)

For full details and the next potential breaking change, please review the [May Service Update](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#service-update-may-2020-action-needed---please-review) document.

If you have any questions, please review the above and [FAQs](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#faq), and if you cannot find them, please raise questions on GitHub issues.

Thanks,


## 27th May 2020 Update - NEW API VERSION - ACTION REQUIRED
As you may have noticed, we have now made `identity` a mandatory parameter in the template, this has multiple advantages, as described above, but this was also needed in preparation for our new API release, `2020-02-14`, that will be available in all regions on the 27th May, by 0700 Pacific.

We are in the process of updating all the documentation, new features, and end to end examples, but the main breaking changes are:
* `identity` is a mandatory requirement, please review the [May Service Update](https://github.com/danielsollondon/azvmimagebuilder/blob/master/MayServiceAlert01.md#service-update-may-2020-action-needed---please-review) document, on how to add this to your templates.
* `vnetConfig` - this specification is changing, from providing, name, subnetName, resourceGroupName to just `subnetId`, for example:

```json
    "vnetConfig": {
        "subnetId": "/subscriptions/<subscriptionID>/resourceGroups/<vnetRgName>/providers/Microsoft.Network/virtualNetworks/<vnetName>/subnets/<subnetName>"
        }
    }
```
#### What does this mean for existing templates and new templates created?
#### New Templates 
If you create a new AIB template, and do not specify the API version in the calling client like below, then the template will be created using the new API version. This is because the calling client API version will override whatever exists in the AIB template.
```bash
az resource create \
    --resource-group $imageResourceGroup \
    --properties @existingVNETLinux.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n existingVNETLinuxTemplate01
```
If you specify the API version using the calling client, like below, this will be created using the specified API version:
```powerShell
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2019-05-01-preview" -imageTemplateName $imageTemplateName -svclocation $location
```
#### Existing Templates
Once the new API is released, calling clients will default to use the new API version. Therefore, if you have existing templates that were created using the previous API version `2019-05-01-preview`, in order to run, view properties, or delete them, you will need to specify the API version in the calling client, for example:

Getting the template status AZ CLI:
```bash
az resource show \
    --resource-group <imageTemplateResourceGroup> \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    --api-version 2019-05-01-preview
    -n <imageTemplateName>
```

Getting the template status PowerShell:

If you use the current [documented](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image#query-the-image-template-for-current-or-last-run-status-and-image-template-settings) method, then ensure the API version matches the previous API version `2019-05-01-preview`.
```PowerShell
$urlBuildStatus = [System.String]::Format("{0}subscriptions/{1}/resourceGroups/$imageResourceGroup/providers/Microsoft.VirtualMachineImages/imageTemplates/{2}?api-version=2019-05-01-preview", $managementEp, $currentAzureContext.Subscription.Id,$imageTemplateName)
```

Deleting Templates AZ CLI:
```bash
az resource delete \
    --resource-group <imageTemplateResourceGroup> \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    --api-version 2019-05-01-preview
    -n <imageTemplateName>
```
Deleting Templates PowerShell:
```PowerShell
Remove-AzResource -ResourceId $resTemplateId.ResourceId -Force -ApiVersion "2019-05-01-preview"
```

#### FAQs
* *What about the AIB Azure DevOps?* - The DevOps task is hard coded to use an API version, this will be updated, but continue to work without interuption. 

* *When will we announce the new functionality?* - The new features will be documented by 28th May
* *Can I use existing documentation?* - Yes, examples that have breaking changes will be updated.


### March 2020 Updates
It has been a busy year already, and we are so pleased to announce this new functionality:
* [Removal of Public IP address requirement, and use an existing VNET](./aibNetworking.md)
    * You can now allow image builder to use your existing VNET, so you can connect to existing configuration servers (DSC, Chef, Puppet etc.), file shares, or any other routable servers/services.
    * Try the end 2 end [Windows](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/1a_Creating_a_Custom_Win_Image_on_Existing_VNET#create-a-windows-linux-image-allowing-access-to-an-existing-azure-vnet) and [Linux](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/1a_Creating_a_Custom_Linux_Image_on_Existing_VNET#create-a-custom-linux-image-allowing-access-to-an-existing-azure-vnet) examples now!
* [European Region Support](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-overview?toc=/azure/virtual-machines/windows/toc.json&bc=/azure/virtual-machines/windows/breadcrumb/toc.json#regions)
    * We now the AIB service in *NorthEurope* and *WestEurope*! 
* [Windows Update customizer](https://github.com/danielsollondon/azvmimagebuilder/blob/f7aac8e6f57fb8ee332af3390a7da303a425d88b/quickquickstarts/1a_Creating_a_Custom_Win_Image_on_Existing_VNET/existingVNETWindows.json#L80)
    * The [community Windows Update Provisioner](https://packer.io/docs/provisioners/community-supported.html) for Packer was integrated into Image Builder, that allows Windows Updates to be installed, and handles reboots during the process. 
* ['Latest'](https://github.com/danielsollondon/azvmimagebuilder/blob/master/quickquickstarts/1a_Creating_a_Custom_Win_Image_on_Existing_VNET/existingVNETWindows.json#L47) image version support
    * Instead of you need to specify a version for Azure Market Place (AMP) images, you can now specify. When the image is created, AIB will use the latest version. This means you can rerun the same image template after the source images in AMP are updated, such as monthly. 
* [Permissions documentation](./aibPermissions.md)
    * We listened to feedback for clarity on permissions required for AIB, and be more granular on permissions required.
    * The quickstarts and solutions are being updated with new permission enablement steps over time.
* [Networking documentation](./aibNetworking.md)
    * We have documented details for AIB networking, options, and requirements.
* DevOps Task Update
    * [Windows Update](https://github.com/danielsollondon/azvmimagebuilder/blob/master/solutions/1_Azure_DevOps/DocsReadme.md#windows-update-task) - Support for running Windows Update at end of task
    * [Change VM size](https://github.com/danielsollondon/azvmimagebuilder/blob/master/solutions/1_Azure_DevOps/DocsReadme.md#optional-settings) - Change the VM size to make resource intensive image builds faster, and also build on specilist VM sizes, such as GPU or HPC enabled sizes.
* RHEL ISO Source Deprecation
    * We are removing this functionality from image builder, as there are now [RHEL Bring Your Own Subscription images](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/redhat/byos), please review the timelines below:
        * 31st March - Image Templates with RHEL ISO sources will now longer be accepted by the resource provider.
        * 30th April - Image Templates that contain RHEL ISO sources will not be processed any more.

The offical Microsoft docs for image builder will be updated this month to relect these updates.


### December 2019 Updates Part 2
The work never ends, latest customization support:

* [osDiskSizeGB](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json#osdisksizegb)

* There will be more updates in January! On behalf of the team, thank you to everyone who has tried Image Builder, and given feedback, we really appreciate it. Happy Holidays!!!!

### December 2019 Updates
We constantly update the Image Builder Service, and its been a while since we summarized recent updates here:

* [PowerShell Customizer Elevated Permissions](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#powershell-customizer)
    * PowerShell Support for running commands and scripts with elevated permissions
* [Checksum File Validation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#powershell-customizer)
    * PowerShell / Shell / File Customizer Support for checkSum
    * Checksum the file a file locally, then Image Builder will checksum and validate.
* [Increase Build Time](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#properties-buildtimeoutinminutes)
    * The default timeout of the image is currently 4hours, but can be reduced or increased upto 16hours.
* [Change Build VM Size](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#vmprofile)
    * By default Image Builder will use a "Standard_D1_v2" build VM, but you may want to use a different VM size, since you may restrict this through Azure Policy, you have customizations that are compute intensive, or you need customize images that can only be run on certain types of VM Size types, e.g. if you want to customize an Image for a GPU VM, you need a GPU VM size.
* [Windows Client / Virtual Desktop OS Support](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-overview#os-support)
    * Many customers are testing Image Builder to support customizing Windows Desktop images, see the PowerShell example on how you can get started building Win10 Images.
    * Change [this](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/1_Creating_a_Custom_Win_Shared_Image_Gallery_Image) quickstart to start building custom WVD images with the Shared Image Gallery.
* [DevOps Task Updates](https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/1_Azure_DevOps#the-azure-vm-image-builder-devops-task)
    * Specify source Azure Market Place OS image versions
    * Improved performance and reliability enhancements for Windows builds
    * Improved Build Log support
        * Source Azure Market Place Image Pub/offer/SKU/Version emitted into DevOps variables.
  
* Supportability
    * Improved error messages, with log error location
    * Multiple bug and reliability enhancements
    * Support for raising image builder Microsoft support cases
    * [Join the Image Builder Community MS Teams Channel](https://aka.ms/aibfeedback)
        * Give feedback, share ideas, contact the engineering team

* [Shared Image Gallery Version Modifications](https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/11_Modifying_SIG_Versions_Post_Build#modifying-shared-image-gallery-versions-post-image-build)
    * Support for Image Version updates post image build, such as updating regions, replicas etc is now supported.

* PowerShell examples
    * [Create a Windows Custom Image and distibute to Shared Image Gallery](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/1_Creating_a_Custom_Win_Shared_Image_Gallery_Image)


### May 2019 Release

* Release Date : 10th May 1000 PST
    This is an exciting release, image builder has just [PUBLIC PREVIEW](https://cloudblogs.microsoft.com/opensource/2019/05/07/announcing-the-public-preview-of-azure-image-builder/)!!!!!

    The whole team is excited to make this milestone, and thanks the Private preview community for their engagement, feedback, and helping shape the product. 

    You will be glad to know there are no API changes this month! But just wanted to share with you an exciting feature additions:

    1. [Preview Azure DevOps Extension](https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/1_Azure_DevOps) - This simplfies using Image Builder in Azure DevOps release pipelines, you just fill in Source / Customizations / Distribute, then the task will create the image, it also will copy in you Build pipeline artifacts!!!

        It is so cool, please try it, and give us feedback.

    2. [Image Builder Public Docs](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-overview)
    
        The quickstarts are in the process of bring migrated to Azure Docs, but the quick starts will be maintained until there is a full transition, and you will be notified.


### [April 2019 Release](/aibApril2019Update.md)
* Features added (links to example config templates):
    * Patch your Windows Custom Images - select existing [Windows Custom SIG Images](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/8_Creating_a_Custom_Win_Shared_Image_Gallery_Image_from_SIG) and [Custom Windows Managed Images](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image)!!!
    * Seemless authentication with Azure Storage - using [Managed User-Assigned Identity](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/7_Creating_Custom_Image_using_MSI_to_Access_Storage) and authenticating with Azure storage accounts. 
    * [Azure Shared Image Gallery](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/8_Creating_a_Custom_Linux_Shared_Image_Gallery_Image_from_SIG) as a source
    * [Add in files to the image](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image)
    * Support for [long duration image builds](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image)
    * Abililty to [override the Image Builder image generalization commands](https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md#vms-created-from-aib-images-do-not-create-successfully)


* [March 2019 Release](/aibMarch2019Update.md)
* Features added (links to example config templates):
    * [Windows Server Support](quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json)
    * Additional Customizers
        * [Windows PowerShell (Script and Inline)](quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json)
        * [Windows-Restart](quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json)
        * [Linux Shell Inline command support](quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json)
    * [Image Build Logs](/troubleshootingaib.md#collecting-and-reviewing-aib-logs) - for troubleshooting
    * [Use existing Custom Managed Images as a Base Image (Currently Linux only)](quickquickstarts/5_Creating_a_Custom_Image_from_Custom_Managed_Image)
    * [Export Images to VHD](/quickquickstarts/4_Creating_a_Custom_Linux_Image_to_VHD)

4. [Troubleshooting](/troubleshootingaib.md)
