# Azure VM Image Builder Template Repo
!!!!!Azure VM Image Builder is now in Private Preview!!!!!
To use this, see this [blog](https://azure.microsoft.com/en-us/blog/announcing-private-preview-of-azure-vm-image-builder/) and sign up!

This repo contains mutliple examples and test templates for Azure VM Image Builder.


1. [Quick QuickStarts Examples](/quickquickstarts/readme.md).
You can run these immediately using the Azure CloudShell from the Portal, and see multiple scenarios that the VM Image Builder supports. 


2. Detailed Examples
* [Azure Resource Manager (ARM) Image Builder Templates](/armTemplates/README.md). 
The beauty of these examples, they are heavily parameterized, so you just need to drop in your own details, then begin image building, or integrate them to existing pipelines.

3. Release Information
* [March 2019 Release (latest)](/aibMarch2019Update.md)
* Features added:
    * Windows Server Support
    * Additional Customizers
        * [Windows PowerShell (Script and Inline)](quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json)
        * [Windows-Restart](quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json)
        * [Linux Shell Inline command support](quickquickstarts/0_Creating_a_Custom_Linux_Managed_Image/helloImageTemplateLinux.json)
    * [Image Build Logs](/troubleshootingaib.md#collecting-and-reviewing-aib-logs) - for troubleshooting
    * [Use existing Custom Managed Images as a Base Image](quickquickstarts/5_Creating_a_Custom_Image_from_Custom_Managed_Image)
    * [Export Images to VHD](/quickquickstarts/4_Creating_a_Custom_Linux_Image_to_VHD)

4. [Troubleshooting](/troubleshootingaib.md)
