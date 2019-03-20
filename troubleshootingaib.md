# Troubleshooing Azure VM Image Builder

These are some of the most common reasons for AIB failures.

Check the run error messages, this will show you the lastRunStatus, and error messages:

## Using 'latest' as Image Version
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

### Windows
[AZ PsCmdLets refence] https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage
```PowerShell
$skuName="<SKU>"
Get-AzVMImage -Location $locName -Publisher $pubName -Offer $offerName -Sku $skuName | Select Version
```
### Linux
[az cli refence](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage)
```bash
az vm image list --location westus --publisher Canonical --offer UbuntuServer --sku 18.04-LTS --all --output table
```

## Image Template Submission
•	Image Template already exists - either rename the template, or delete the existing.
•	RHEL ISO token expired - these are bound to a time period, if this has been exceeded, AIB will not be able to download the ISO, so please refresh the URL.

## Image Creation
* Unsupported Platform Image / RHEL ISO - We support a limited set, please refer to the 'Source' section of documentation for the list.
* Customizer Failure - If one script reports failure, then the customizer will report failure. Check your scripts ahead of time, and that they will run in < 45mins.

The customization errors will look something like this:
```bash
Deployment failed. Correlation ID: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx. Failed in building/customizing image: Failed while waiting for packerizer: Microservice has failed: Failed while processing request: Error when executing packerizer: Packer build command has failed: exit status 1
```
So what do i do now??

## Collecting and Reviewing AIB Logs
The build logs are stored in a storage account in the temporary (Resource Group) (RG) AIB creates when you create an Image Template.
```bash
IT_<ImageResourceGroupName>_<TemplateName>
```

For example, in Quick Quickstart 1 'Creating a Custom Linux Managed Image', this would be: 

IT_aibmdi_helloImageTemplateLinux01

Go to the RG > Storage Account > Blobs > packerlogs >  click on the directory > customization.log

Download the customization.log, search / grep for ERROR.

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

Note! This is a private preview, not all the errors are refined yet, we are working to improve these all the time.

## Image Re-Customization
Note : This is only currently supported on Linux!!

If you find your re-customized image has not been created properly, such as fails to boot, login, has errors, please check the source image first, by creating a VM from it. Then check it boots, and errors.

## RHEL ISOs

## Ubuntu Image Builds


## Contact US / Further Support & Questions & Feedback
Please reach out to us on the MS Teams Channel, ‘Azure VM Image Builder Community’.


