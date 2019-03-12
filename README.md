# Azure VM Image Builder Template Repo
!!!!!Azure VM Image Builder is now in Private Preview!!!!!
To use this, see this [blog](https://azure.microsoft.com/en-us/blog/announcing-private-preview-of-azure-vm-image-builder/) and sign up!

This repo contains mutliple examples and test templates for Azure VM Image Builder.

>> **ALERT:**
AIB will be updated with a new [features](/aibMarch2019Update.md), and a Microsoft.VirtualMachineImages API update, we will start the release of these features from 12th March 1600 PDT, and completion should be approx. 13th March 1200 PDT. Please monitor the [MS Teams](https://launchpad.net/~cloud-init-dev/+archive/ubuntu/daily) channel for updates. You will need to update your AIB templates, please see this article for details.


1. [Quick QuickStarts Examples](/quickquickstarts/readme.md).
You can run these immediately using the Azure CloudShell from the Portal, and see multiple scenarios that the VM Image Builder supports.  

2. Detailed Examples
* [Azure Resource Manager (ARM) Image Builder Templates](/armTemplates/README.md). 
The beauty of these examples, they are heavily parameterized, so you just need to drop in your own details, then begin image building, or integrate them to existing pipelines.

* [Raw Image Builder Templates](/rawImageBuilderConfigTemplates/README.md). 
If you do not use ARM, you can use these when submitting an Image Template directly to the Azure Resource Provider, and they are also good for understanding basic templates.
