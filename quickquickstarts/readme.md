# Azure VM Image Builder Quick QuickStarts

Welcome to the Azure VM Image Builder QuickStarts, these are some key scenarios you can test using Azure CloudShell in the Portal, or Azure CLI.

## Quick Starts (Linux)
1. [Create a Custom Image from an Azure Platform Vanilla OS Image.](./0_Creating_a_Custom_Linux_Managed_Image/readme.md)
2. [Create a Custom Image, then Distribute and Version over Multiple Regions.](./1_Creating_a_Custom_Linux_Shared_Image_Gallery_Image/readme.md)
3. [Creating a custom RHEL image using a RHEL ISO where you can use eligible Red Hat licenses.](./2_Creating_a_Custom_Image_using_Red_Hat_Subscription_Licences/readme.md)   

Any questions, please ask on the [MS Teams Channel](https://teams.microsoft.com/l/channel/19%3a03e8b2922c5b44eaaaf3d0c7cd1ff448%40thread.skype/General?groupId=a82ee7e2-b2cc-49e6-967d-54da8319979d&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47), the Azure Image Builder Dev team is there during the week, Pacific time.

These are designed to get you started quickly, where at a minimum you just need to supply your subscriptionID (except for the RHEL example), showing you how the Azure VM Image Builder can be used to build images to meet these requirements:

* Security & Compliance - e.g. building corporate golden images, that meet your organizations security and compliance requirements.
* Licensing - e.g. building RHEL images using your eligible Red Hat Subcription licenses.
* Performance - e.g. creating images with applications pre-installed
* Management - e.g. managing images updates and global region replication

## Next Steps
* Want to learn more???
    * Explore the detailed documentation in the [MS Teams channel](https://teams.microsoft.com/l/channel/19%3a03e8b2922c5b44eaaaf3d0c7cd1ff448%40thread.skype/General?groupId=a82ee7e2-b2cc-49e6-967d-54da8319979d&tenantId=72f988bf-86f1-41af-91ab-2d7cd011db47) (Files).

* Want to try more???
* Image Builder does support deployment through Azure Resource Manager, see here in the repo for [examples](https://github.com/danielsollondon/azvmimagebuilder/tree/master/armTemplates), you will also see how you can use a RHEL ISO source too, and manu other capabilities.
