# Azure VM Image Builder Template Repo
!!!!!Azure VM Image Builder is now in PUBLIC Preview!!!!!


Get started now, this repo contains mutliple examples and test templates for Azure VM Image Builder.

What is Image Builder??
Get started with the short intro video below, or go straight to the Quick Starts below.


[<img src="./introToAIB.png" alt="drawing" width="325"/>](https://youtu.be/nalr2rHRDew)


1. [Quick QuickStarts Examples](/quickquickstarts/readme.md).
You can run these immediately using the Azure CloudShell from the Portal, and see multiple scenarios that the VM Image Builder supports. 


2. [Azure Resource Manager (ARM) Image Builder Examples](/armTemplates/README.md). 
The beauty of these examples, they are heavily parameterized, so you just need to drop in your own details, then begin image building, or integrate them to existing pipelines.

3. Release Information

## Latest Release Information

### Timelines
GA - Early 2020

### December 2019 Updates
We constantly update the Image Builder Service, and its been a while since we summarized recent updates here:

* [PowerShell Customizer Elevated Permissions](https://github.com/danielsollondon/azvmimagebuilder/blob/a6f9692efa17f2ec8b96b0caf9890e81fa770fcc/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json#L31)
    * PowerShell Support for running commands and scripts with elevated permissions
* [Checksum File Validation](https://github.com/danielsollondon/azvmimagebuilder/blob/a6f9692efa17f2ec8b96b0caf9890e81fa770fcc/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json#L37)
    * PowerShell / Shell / File Customizer Support for checkSum
    * Checksum the file a file locally, then Image Builder will checksum and validate.
* [Increase Build Time](https://github.com/danielsollondon/azvmimagebuilder/blob/a6f9692efa17f2ec8b96b0caf9890e81fa770fcc/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json#L11)
    * The default timeout of the image is currently 4hours, but can be reduced or increased upto 16hours.
* [Change Build VM Size](https://github.com/danielsollondon/azvmimagebuilder/blob/a6f9692efa17f2ec8b96b0caf9890e81fa770fcc/quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json#L13)
    * By default Image Builder will use a "Standard_D1_v2" build VM, but you may want to use a different VM size, since you may restrict this through Azure Policy, you have customizations that are compute intensive, or you need customize images that can only be run on certain types of VM Size types, e.g. if you want to customize an Image for a GPU VM, you need a GPU VM size.
* [Windows Client / Virtual Desktop OS Support](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/1_Creating_a_Custom_Win_Shared_Image_Gallery_Image)
    * Many customers are testing Image Builder to support customizing Windows Desktop images, see the PowerShell example on how you can get started building Win10 Images.
    * Win10 client images supported [here](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-overview#os-support).
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
    * [Create a Windows Custom Image and distibute to Managed Image](https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/5_PowerShell_deployments#using-powershell-to-create-a-windows-10-custom-image-using-azure-vm-image-builder-preview-example)


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
