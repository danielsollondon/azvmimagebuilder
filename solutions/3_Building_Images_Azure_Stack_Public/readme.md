# Create RHEL Images with your eligble RHEL Subscription Licences for Azure Public and Azure Stack (TO BE UPDATED)
 
Currently, Azure supports RHEL Pay As You Go images, but if you have your own eligble RHEL licenses (BYOS), you would need to build an Azure image from an ISO. This involves:
* Multiple steps
* An automated build system
* Learn new tools to create images
* Maintain the images and build system
* Maintaining image parity between Azure Stack and Azure Public
 
## Solution : Use Azure Image Builder to create RHEL BYOS images for both Azure Public and Azure Stack
 
The Azure Image Builder (AIB) service, takes a simple image configuration, that defines a source, customizations to perform and multiple distribution targets.
 
In this case we can use AIB to use a source ISO URL from your RedHat Customer Portal, then use the customizer to apply any further customizations, such as install security baselines and applications, then deploy the image to a Shared Image Gallery and VHD. This will allow you to consume the exact same image in Azure Public and Azure Stack, using one pipeline. In addition, you do not need to know how to convert a RHEL ISO into a bootable Azure image, AIB knows how to do that!!!
 
## Implementation
There are multiple ways you can achieve this, we are going to show how you can set this up with Image Builder and Azure stack, we will break this down into:
* Creating the Image
* Distributing the Image
 
### Creating the Image
There are multiple ways you can create the image, you can immediately get started using the [Quick QuickStart examples](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/6_Creating_a_Custom_Image_using_Red_Hat_Subscription_Licences_to_VHD), then get the VHD URL and copy this to Azure Stack. 

### Distributing the Image
There are multiple copy options for [Azure Stack](https://docs.microsoft.com/en-us/azure-stack/user/azure-stack-storage-transfer).

NOTE: This article is still being worked on, a full end to end solution document in is progress, and will be published within 7days.