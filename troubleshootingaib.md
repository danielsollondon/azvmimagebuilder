# Troubleshooting Azure VM Image Builder

In this troubleshooting section, it will broken down into troubleshooting Image Template Submission errors, and Image Build errors.


### Template Submission Errors & Troubleshooting
If you submit an Image Template to the service, and there is a failure, the error message returned will be key to understanding the failure. The errors are returned by the calling code (PS/CLI etc), or by getting the output from the template submission, using the CLI below, the error will be in the `provisioningError` attribute.

```bash
az resource show \
    --resource-group <imageTemplateResourceGroup> \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n <imageTemplateName>
```

#### Image Version Failure
If you see an error similar to the below, you are likely to be using 'latest' as the source image version.

```bash
Build (Azure PIR Image) step failed: compute.VirtualMachineImagesClient#Get: Failure responding to request: StatusCode=400 -- Original Error: autorest/azure: Service returned an error. Status=400 Code="InvalidParameter" Message="The value of parameter version is invalid." Target="version"
Document this.
```
This is what your image source would look like:
```bash
        "source": {
            "type": "PlatformImage",
                "publisher": "MicrosoftWindowsServer",
                "offer": "WindowsServer",
                "sku": "2019-Datacenter",
                "version": "latest"
```
We currenty do not support latest, you must specify a version number, for example:
```bash
"version": "2019.0.20190214"
```

We are aware that many customers would like to use 'latest', this is on our backlog to resolve.

If you need to identify what is the latest version number, you can use:

[AZ PsCmdLets refence](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage)
```PowerShell
$skuName="<SKU>"
Get-AzVMImage -Location $locName -Publisher $pubName -Offer $offerName -Sku $skuName | Select Version
```

[az cli refence](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage)
```bash
az vm image list --location westus --publisher Canonical --offer UbuntuServer --sku 18.04-LTS --all --output table
```


#### Image Template Update/Upgrade Error
You may see the error below:
```bash
'Conflict'. Details: Update/Upgrade of image templates is currently not supported
```
We do not support updating existing Image Template artifact, you will need to either rename the new template, or delete the existing template.

If you want to iterate through multiple image builds, you can build an image versioning into the template name, see [here](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/9_Updating_Image_Builder_Templates#updating-image-builder-templates) for an example.

>> Please note, if you have submitted an Image Configuration template, and the submission initially failed, a failed template artifact will still exist, you must delete the failed template.

#### RHEL ISO Download Failures
When you submit an Image Configuration Template, you get an error similar to the below:
Downloading external file (https://access.cdn.redhat.com/content/.../rhel-server-7.4-x86_64-dvd.iso?[REDACTED] to local file (<guid>.iso) [attempt 6 of 10] failed: Error downloading 'https://access.cdn.redhat.com/content/.../rhel-server-7.4-x86_64-dvd.iso?[REDACTED] to '<guid>.iso': 'Bad status downloading from url 'https://access.cdn.redhat.com/content/../rhel-server-7.4-x86_64-dvd.iso?[REDACTED] 403 Forbidden'

This can happen for these reasons:
* Your Azure subscription security policies do not allow access to the URL.
* The URL is incorrect.
* RHEL ISO token expired - When you copy the URL from the Red Hat download site, these are bound to a time period, if this has been exceeded, AIB will not be able to download the ISO, so please refresh the URL, and run the image template submission straight away.


#### Permissions
When you submit the Image configuration template, the Image Builder service will validate that it has access to all the build dependencies, such as scripts, ISOs, Managed Images, Shared Image Gallery image versions all exist.

If you see a similar error to this:
```bash
Build (Managed Image) step failed: Error getting Managed Image '/subscriptions/.../providers/Microsoft.Compute/images/mymanagedmg1': Error getting managed image (...): compute.ImagesClient#Get: Failure responding to request: StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="AuthorizationFailed" Message="The client '......' with object id '......' does not have authorization to perform action 'Microsoft.Compute/images/read' over scope 
```

To allow Azure Image Builder to use existing source custom managed image or SIG image version, then the Azure Image Builder will need a minimum of ‘Reader’ access to those resource groups that contain the images,  you will need to provide ‘Reader’ permissions for the service "Azure Virtual Machine Image Builder" (app ID: cf32a0cc-373c-47c9-9156-0db11f6a6dfc) on the resource groups.

Whilst you are checking permissions, when the image build runs the actual image build, you must allow Azure VM Image Builder to distribute images to either the managed images or to a Shared Image Gallery (SIG), you will need to set 'Contributor' permissions for the service "Azure Virtual Machine Image Builder" (app ID: cf32a0cc-373c-47c9-9156-0db11f6a6dfc) on the resource groups.

#### Image Reference Errors
During the submission of the image template, the Image Builder Service will check that the destination Resource group for the managed image exist, and the Shared Image Gallery (SIG), and SIG Definition, and SIG Image Version. All of these must exist at the time of the submission and when the image build runs, if not, you will see a similar error, 'ResourceNotFound' to below during the submission:
```bash
Build (Shared Image Version) step failed for Image Version '/subscriptions/.../providers/Microsoft.Compute/galleries/.../images/... /versions/0.23768.4001': Error getting Image Version '/subscriptions/.../resourceGroups/<rgName>/providers/Microsoft.Compute/galleries/.../images/.../versions/0.23768.4001': Error getting image version '... :0.23768.4001': compute.GalleryImageVersionsClient#Get: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Compute/galleries/.../images/.../versions/0.23768.4001' under resource group '<rgName>' was not found."
```
#### Image Template Parameter Errors
We have been asked on some occasions how you can parameterize an Image Builder Template, if you do this incorrectly, you may get a similar error to this:
```bash
Downloading external file (<myFile>) to local file (xxxxx.0.customizer.fp) [attempt 1 of 10] failed: Error downloading '<myFile>' to 'xxxxx.0.customizer.fp'..
```

There are some ways you can get parameters into the image builder template, for example:
1. Use a stream editor to find and replace placeholders in an image configuration template, similar to quick start examples, using SED.
2. Use Azure Resource Manager templates, and use parameters and variables within them, please see these examples [here](https://github.com/danielsollondon/azvmimagebuilder/tree/master/armTemplates#deploying-image-builder-templates-with-azure-resource-manager-arm).

#### You cannot delete the Image Configuration Template Artifact
Typically this is caused when you have deleted the staging resource group.
>>>>>>>>>>>>>>>>>>>

## Image Build Errors & Troubleshooting
### Collecting and Reviewing AIB Image Build Logs
When the image build is running, logs are created, and stored in a storage account in the temporary Resource Group (RG), that AIB creates when you create an Image Template artifact.
```bash
IT_<ImageResourceGroupName>_<TemplateName>
```

For example, in Quick Quickstart 1 'Creating a Custom Linux Managed Image', this would be: 

IT_aibmdi_helloImageTemplateLinux01

Go to the RG > Storage Account > Blobs > packerlogs >  click on the directory > customization.log/RedHatBuilder.log

Download the customization.log/RedHatBuilder.log, search / grep for ERROR.

Here is an example when you do not run inline commands with the correct elevated user permissions:

```bash
PACKER ERR 2019/03/08 00:37:32 packer: 2019/03/08 00:37:32 [ERROR] Remote command exited with '1': chmod +x /tmp/script_9178.sh; PACKER_BUILDER_TYPE='azure-arm' PACKER_BUILD_NAME='azure-arm'  /tmp/script_9178.sh
PACKER OUT     azure-arm: touch: cannot touch '/buildArtifacts/imageBuilder.md': Permission denied
PACKER ERR 2019/03/08 00:37:32 packer: 2019/03/08 00:37:32 [INFO] RPC endpoint: Communicator ended with: 1
PACKER OUT ==> azure-arm: 
PACKER ERR 2019/03/08 00:37:32 [INFO] 2093 bytes written for 'stdout'
PACKER ERR 2019/03/08 00:37:32 [INFO] 0 bytes written for 'stderr'
PACKER ERR 2019/03/08 00:37:32 [INFO] RPC client: Communicator ended with: 1
```

In this case the fix was to prefix the command with 'sudo', but these logs are useful for identifying where the time is being spent in your image build process.

Note! This is a public preview, not all the errors are refined yet, we are working to improve these all the time.



### Customizer Failures
If one of the customizer (Shell/PowerShell/File etc) reports failure, then the customizer will report failure.

The customization errors will look something like this:
```bash
Deployment failed. Correlation ID: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx. Failed in building/customizing image: Failed while waiting for packerizer: Microservice has failed: Failed while processing request: Error when executing packerizer: Packer build command has failed: exit status 1
```
So what do i do now?? Collect AIB Build logs, and search for the customizer.

#### Customizer Timeout Failures
Typically, the build creation calling client or the Image Template `LastRunStatus` will return something similar to the below:
```bash
Deployment failed. Correlation ID: dxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx. Failed in building/customizing image: Failed while waiting for packerizer: Timeout waiting for microservice to complete: 'context deadline exceeded'
```
The next steps are to check the Image Build logs, look to see why the timeout was hit, this maybe a long running customization, these can be caused because:

1) Script customization may not supressing user interation for commands, such as `quiet` options, e.g. `apt-get install -y`, and the script execution is just waiting.
2) You are using the `File` customizer to download artifacts > 20MB, see below for workarounds.
2) Errors/dependencies in script cause the script to wait.
4) [buildTimeoutInMinutes](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json) value is too low, generally the default timeout of 60mins will be too small for Windows.

Before you troubleshoot further, run the scripts/commands on a VM from the commandline using the same OS / image build, and check they run correctly.

#### File Customizer Failures
The file customizer is only suitable for small file downloads, < 20MB. For larger file downloads use a Script or Inline command, the use code to download files, such as, Linux `wget` or `curl`, Windows, `Invoke-WebRequest`.

### SIG Distribution Errors
If the image builder cannot distribute to SIG or SIG Defintion, you will see errors.

The error below is atypical, where the SIG or SIG Definition does not exist at image build time, remember at image template submission, image builder checks the SIG and SIG Definition exist, `The Resource 'Microsoft.Compute/galleries/.../images/myimage100' under resource group '...' was not found."`

```bash
[Distribute 0] Error getting Shared Gallery Image location for GalleryID:/subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/galleries/.../images/myimage100, Location:. Error: Error returned from SIG client while getting shared gallery image location for sigResourceID: /subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/galleries/.../images/myimage100. Error: Error getting location of shared gallery image: Error while doing a GET on shared gallery image for shared gallery image id: /subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/galleries/.../images/myimage100. Error: compute.GalleryImagesClient#Get: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Compute/galleries/.../images/myimage100' under resource group '...' was not found."
```
The only resolution is to check that the SIG and SIG Image Definition exist before image build.


### Image Re-Customization Failures
If you find your re-customized image has not been created properly, such as fails to boot, login, has errors, please check the source image first, by creating a VM from it. Then check it boots, and errors.

### Status of an Image Build
```bash
imageBuilderTemplateResGrp=
imageTemplateName=
az resource show --resource-group $imageBuilderTemplateResGrp --resource-type  Microsoft.VirtualMachineImages/imageTemplates -n $imageTemplateName 
```

Review the 'lastRunStatus' for current runState.

### VMs created from AIB images do not create successfully

By default, the AIB will also run ‘deprovision’ code at the end of each image customization phase, to ‘generalize’ the image. Generalize is a process where the image is setup, so it can be reused to create multiple VMs, and you can pass in VM settings, such as hostname, username etc. In Windows, AIB executes Sysprep, and in Linux AIB runs ‘waagent -deprovision’. For Windows, we use a generic Sysprep command, however, it is understood, that this may not be suitable for every successful Windows generalization, so AIB will allow you to customize this command. Please note, AIB is an image automation tool, it is responsible for running Sysprep command successfully, but, you may need different Sysprep commands to make your image reusable. For Linux we use a generic 'waagent -deprovision+user' comand, see here for [documentation](https://github.com/Azure/WALinuxAgent#command-line-options). 


If you are migrating existing customization, and you are using different Sysprep/waagent commands, you can try the image builder generic commands, and if the VM creates fail, use your previous Sysprep/waagent commands.

>>>Note! If AIB creates a Windows custom image successfully, and you create a VM from it, then find the VM will not create successfully (i.e. the VM creation command does not complete/timeouts), you will need to review the Windows Server Sysprep documenation, or raise a support request with the Windows Server Sysprep Customer Services Support team, who can troubleshoot and advise on the correct Sysprep command.



#### Command Locations and Filenames
```bash
Windows: c:\DeprovisioningScript.ps1

Linux: /tmp/DeprovisioningScript.sh
```
#### Sysprep Command: Windows
```PowerShell
echo '>>> Waiting for GA to start ...'
while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }
while ((Get-Service WindowsAzureTelemetryService).Status -ne 'Running') { Start-Sleep -s 5 }
while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }
echo '>>> Sysprepping VM ...'
if( Test-Path $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml ){ rm $Env:SystemRoot\\windows\\system32\\Sysprep\\unattend.xml -Force} & $Env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit
while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 5  } else { break } }
```
#### Deprovision Command: Linux
```bash
/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync
```

#### Overriding the Commands
To override the commands, use the PowerShell or Shell script provisioners to create the command files with the exact file name, and put them in the directories above. AIB will read these commands, these are written out to the AIB logs, ‘customization.log’. See here on how to collect AIB logs: https://github.com/danielsollondon/azvmimagebuilder/blob/master/troubleshootingaib.md#collecting-and-reviewing-aib-logs

### You cannot delete an Image Template 
When you create an AIB Image Template, this will be stored in the Resource Group you have specified during creation. You cannot see this by default, when you look at the resources in the Portal. You must select 'Show Hidden Types'.
At the time you create the Image Template, an AIB staging resource group is setup, in the format: 
‘IT_<TemplateResourceGroup>_<TemplateName>’
This will contain a storage account of any files, scripts, ISO, that AIB needs for the image build, and will be there for the lifetime of the Image Template. You must not delete the ‘IT_<TemplateResourceGroup>_<TemplateName>’ resource group!

Should you delete it, you will not be able to delete the AIB Image Template artifact, you will get an error.

We are working to resolve this, but in the meantime, a workaroudn, if you have deleted the staging resource by accident, create a resource group with the same name.

### You use AIB to create images versions in the Azure Shared Image Gallery (SIG), but you cannot make changes the SIG Image version.
In the scenario where image builder has created images for the SIG, you will not be able to modify the version properties of that image. For example, if you want to replicate that image to more regions, using SIG commands / portal, this will fail, as the source image does not exist. 

We are working to resolve this, ETA, end of July.

## Contact US / Further Support & Questions & Feedback
Please reach out to us on the:
* Raise an MS Support Case
* MS Teams Channel, ‘Azure VM Image Builder Community’


