# Documentation for the Azure VM Image Builder DevOps Task  
Task version: v1

## V1 Design Purpose
This task is designed to take your build artifacts, and inject them into a VM image, so you can install, configure your application, and OS.
 
## Installing the DevOps Task
Go to the [Visual Studio Marketplace](https://marketplace.visualstudio.com), search for 'Azure Image Builder', select 'Get it free' to install.
 
## Prereqs
* You must have a VSTS DevOps account, and a Build Pipeline created
* Create a Standard Azure Storage Account in the source image Resource Group, you can use other Resource Group/Storage accounts, but you must ensure the Image Builder has contributor permissions to the Storage account. This is used transfer the build artifacts from the DevOps task to the image.
```bash
# create storage account and blob in resource group
strResourceGroup=<ResourceGroupName>
location=westus
scriptStorageAcc=aibstordot$(date +'%s')
az storage account create -n $scriptStorageAcc -g $strResourceGroup -l $location --sku Standard_LRS
```

## Add the Task to the Release Pipeline
This is where the fun begins!!

Go to the Release Pipeline > Edit. On the User Agent, click the '+', and search for 'Image Builder', then add it.

Below we will discuss the task properties:

## Where you want to run this template

### Azure Subscription
Select from the drop down menu which subscription you want the Image Builder to run in, this must be the same subscription on where your source images are located, and where the images are to be distributed. You will need to 'Authorize' the image builder contributor access to the Subscription or Resource Group.

### Resource Group
This is the Resource Group where the temporary Image Template artifact will be stored. 
As discussed in the other docs, when creating a template artifact , this creates a temporary Image Builder resource group, ‘'IT_<DestinationResourceGroup>_<TemplateName>'. This stores the image metadata, such as scripts. At the end of the task, we delete the Image Template artifact, and therefore, temporary Image Builder Resource Group.
 
### Location
This is the location where the Image Builder will run, we only support a set amount of locations. The source images must be present in this location, so for example, if you are using Shared Image Gallery, a replica must exist in that region.

### Source
The source images must be of the supported Image Builder OS's. You can choose existing custom images in the same region as Image Builder is running from:
* Managed Image - You need to pass in the resourceId, for example:
```json
/subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/images/<imageName>
```
* Azure Shared Image Gallery - You need to pass in the resourceId of the image version, for example:
```json
/subscriptions/$subscriptionID/resourceGroups/$sigResourceGroup/providers/Microsoft.Compute/galleries/$sigName/images/$imageDefName/versions/<versionNumber>
```

* Marketplace Base Images
Image Builder will select the 'latest' version of the supported OS's, you cannot specify an image version.

### Customize

#### Provisioner
Initialy, we are just supporting two customerizers, 'Shell', and 'PowerShell' and we only support 'inline'. If you want to download scripts, then you can pass inline commands to do so.

For your OS, select with PowerShell, or Shell.

#### Build Path
This task has been initially designed to be able to inject DevOps Build release artifacts into the image. To make this work, you will need to setup a Build Pipeline, and in the setup of the Release pipeline, you must add specific the repo of the build artifacts.

![alt text](./step4.PNG "Add an Artifact")

Click on the Build Path button, to select the build folder you want to be placed on the image. The Image Builder task will copy all files and directories underneath it. 

When the image is being created, Image Builder will deploy them into different paths, depending on OS.

Lets use this example to explain how this works:
![alt text](./buildArtifacts.PNG "Add an Artifact")

* Windows - 
In the 'C:\\', a directory named 'buildArtifacts' will be created, with the webapp directory.

* Linux - 
In /tmp, the webapp directory will be created, with all files and directories, you MUST move the files from this directory, otherwise, they will be deleted.

You will need to use a customization command(s) to move the files.

#### Inline Customization Script
* Windows
You can enter powershell inline commands separated by commas, and if you want to run a script in your build directory, you can use:
```PowerShell
& 'c:\buildArtifacts\webapp\webconfig.ps1'
```

* Linux
Similar to the above, commands are separated by commas, but you need to move the files:
```bash
sudo mkdir /lib/buildArtifacts
sudo cp -r /tmp/webapp /lib/buildArtifacts/.
```

#### Total length of image build
This cannot be changed in the DevOps pipeline task yet, so it uses the default of 60mins. If you want to increase the '[buildTimeoutInMinutes](https://github.com/danielsollondon/azvmimagebuilder/blob/2834d0fcbc3e0a004b247f24692b64f6ef661dac/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json#L12)', then you can use an AZ CLI task in the Release Pipeline, and configure this to copy down a template, and submit it.


#### Storage Account
Select the storage account you created in the prereqs, if you do not see it in the list, Image Builder does not have permissions to it.

When the build starts, Image Builder will create a container called 'imagebuilder-vststask', this is where the build artifacts from the repo are stored.

Note!! You need to manually delete the storage account or container after each build!!! 

### Distribute
There are 3 distribute types supported:
* Managed Image
    * ResourceID:
    ```bash
    /subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/images/<imageName>
    ```
    * Locations
* Azure Shared Image Gallery - this must already exist! The 
    * ResourceID: 
    ```bash
    /subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/galleries/<galleryName>/images/<imageDefName>
    ```
    * Regions: list of regions, comma separated, e.g. westus, eastus, centralus
* VHD
    * You cannot pass any values to this, Image Builder will emit the VHD to the temporary Image Builder resource group, ‘'IT_<DestinationResourceGroup>_<TemplateName>', in the 'vhds' container. When you start the release build, image builder will emit logs, and when it has finished, it will emit the VHD URL.

## How it works
When you create the release, the task will:
1) Create a container in the storage account, named 'imagebuilder-vststask', it will zip and upload your build artifacts, and create a SAS Token on the that zip file.
2) Use the properties passed to the task, to create the Image Builder Template artifact, this will in turn:
    * Download the build artifact zip file, and any other associated scripts, and these are all saved in a storage account in the temporary Image Builder resource group, ‘'IT_<DestinationResourceGroup>_<TemplateName>'.
    * Create a template prefixed 't_' 10 digit monotonic integer, this is saved to your Resource Group you selected, you will see it for the duration of the build in the resource group. 
You can see the output in the 
```bash
start reading task parameters...
found build at:  /home/vsts/work/r1/a/_ImageBuilding/webapp
end reading parameters
getting storage account details for aibstordot1556933914
created archive /home/vsts/work/_temp/temp_web_package_21475337782320203.zip
Source for image:  { type: 'SharedImageVersion',
  imageVersionId: '/subscriptions/<subscriptionID>/resourceGroups/<rgName>/providers/Microsoft.Compute/galleries/<galleryName>/images/<imageDefName>/versions/<imgVersionNumber>' }
template name:  t_1556938436xxx
starting put template...
```
3) Start the image build, when this happens, you will see this in the release logs, whilst the build is running:
```bash
starting run template...
```
4) When the image build completes you will see the following:
```bash
2019-05-06T12:49:52.0558229Z starting run template...
2019-05-06T13:36:33.8863094Z run template:  Succeeded
2019-05-06T13:36:33.8867768Z getting runOutput for  SharedImage_distribute
2019-05-06T13:36:34.6652541Z ==============================================================================
2019-05-06T13:36:34.6652925Z ## task output variables ##
2019-05-06T13:36:34.6658728Z $(imageUri) =  /subscriptions/<subscriptionID>/resourceGroups/aibwinsig/providers/Microsoft.Compute/galleries/my22stSIG/images/winWAppimages/versions/0.23760.13763
2019-05-06T13:36:34.6659989Z ==============================================================================
2019-05-06T13:36:34.6663500Z deleting template t_1557146959485...
2019-05-06T13:36:34.6673713Z deleting storage blob imagebuilder-vststask\webapp/18-1/webapp_1557146958741.zip
2019-05-06T13:36:34.9786039Z blob imagebuilder-vststask\webapp/18-1/webapp_1557146958741.zip is deleted
2019-05-06T13:38:37.4884068Z delete template:  Succeeded
```
The image template, and ‘'IT_<DestinationResourceGroup>_<TemplateName>' will be deleted.

You can take the '$(imageUri)' VSTS variable and use this in the next task, or just take its value and build a VM.

## FAQ
1. Can i use an existing image template i have already created, outside of DevOps?
No, but stay tuned!!

2. Can i specifiy the image template name?
No, we generate a unique template name, then destroy it after.

3. The image builder failed, how can i troubleshoot, review the [troubleshooting guide](https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md)

