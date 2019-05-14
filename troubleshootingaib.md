# Troubleshooting Azure VM Image Builder

## Collecting and Reviewing AIB Image Build Logs
The build logs are stored in a storage account in the temporary (Resource Group) (RG) AIB creates when you create an Image Template.
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

## Common Errors when using image builder

### Using 'latest' as Image Version
If you deploy an AIB Configuration template with 'latest', this will fail, for example:
```bash
        "source": {
            "type": "PlatformImage",
                "publisher": "MicrosoftWindowsServer",
                "offer": "WindowsServer",
                "sku": "2019-Datacenter",
                "version": "latest"
```
You must specify a version number, for example:
```bash
"version": "2019.0.20190214"
```

We are aware that many customers would like to use 'latest', this is on our backlog to resolve.

If you need to identify what is the latest version number, you can use 

#### Windows
[AZ PsCmdLets refence] https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage
```PowerShell
$skuName="<SKU>"
Get-AzVMImage -Location $locName -Publisher $pubName -Offer $offerName -Sku $skuName | Select Version
```
#### Linux
[az cli refence](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage)
```bash
az vm image list --location westus --publisher Canonical --offer UbuntuServer --sku 18.04-LTS --all --output table
```

### Image Template Submission
•	Image Template already exists - either rename the template, or delete the existing.
•	RHEL ISO token expired - these are bound to a time period, if this has been exceeded, AIB will not be able to download the ISO, so please refresh the URL.

### Image Build
* Unsupported Platform Image / RHEL ISO - We support a limited set, please refer to the 'Source' section of documentation for the list.
* Customizer Failure - If one script reports failure, then the customizer will report failure. Check your scripts ahead of time, and that they will run in < 45mins.

The customization errors will look something like this:
```bash
Deployment failed. Correlation ID: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx. Failed in building/customizing image: Failed while waiting for packerizer: Microservice has failed: Failed while processing request: Error when executing packerizer: Packer build command has failed: exit status 1
```
So what do i do now?? Collect AIB Build logs.

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

We are working to resolve this, ETA, end of May.

## Contact US / Further Support & Questions & Feedback
Please reach out to us on the:
* Raise an MS Support Case
* MS Teams Channel, ‘Azure VM Image Builder Community’


