# Azure VM Image Builder Template Repo
!!!!!Azure VM Image Builder is now in PUBLIC Preview!!!!!
To use this, see this [blog](https://azure.microsoft.com/en-us/blog/announcing-private-preview-of-azure-vm-image-builder/) and sign up!

This repo contains mutliple examples and test templates for Azure VM Image Builder.


1. [Quick QuickStarts Examples](/quickquickstarts/readme.md).
You can run these immediately using the Azure CloudShell from the Portal, and see multiple scenarios that the VM Image Builder supports. 


2. [Azure Resource Manager (ARM) Image Builder Examples](/armTemplates/README.md). 
The beauty of these examples, they are heavily parameterized, so you just need to drop in your own details, then begin image building, or integrate them to existing pipelines.

3. Release Information

* May 2019 Release (latest)

    Release Date : 10th May 1000 PST
    This is an exciting release, image builder has just [PUBLIC PREVIEW](https://cloudblogs.microsoft.com/opensource/2019/05/07/announcing-the-public-preview-of-azure-image-builder/)!!!!!

    The whole team is excited to make this milestone, and thanks the Private preview community for their engagement, feedback, and helping shape the product. 

    You will be glad to know there are no API changes this month! But just wanted to share with you an exciting feature additions:

    1. [Preview Azure DevOps Extension](https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/1_Azure_DevOps) - This simplfies using Image Builder in Azure DevOps release pipelines, you just fill in Source / Customizations / Distribute, then the task will create the image, it also will copy in you Build pipeline artifacts!!!

        It is so cool, please try it, and give us feedback.

    2. [Image Builder Public Docs](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-overview)
    
        The quickstarts are in the process of bring migrated to Azure Docs, but the quick starts will be maintained until there is a full transition, and you will be notified.


* [April 2019 Release (latest)](/aibApril2019Update.md)
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
