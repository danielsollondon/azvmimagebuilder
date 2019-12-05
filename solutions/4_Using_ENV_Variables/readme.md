# Using Environment Variables and Parameters with Image Builder
When  developing configuration templates for for Azure VM Image Builder (AIB), you may wish to use variables or parameters.

Out of the box, AIB allows you to specify multiple customizers, these maybe the same or different, for example, you may use multiple Shell customizers in the same configuration:

```json
        "customize": [
            {
                "type": "Shell",
                "name": "setupBuildPath",
                "inline": [
                    "sudo mkdir /buildArtifacts",
                    "sudo cp /tmp/index.html /buildArtifacts/index.html"
                ]
            },

            {
                "type": "Shell",
                "name": "InstallUpgrades",
                "inline": [
                    "sudo apt install unattended-upgrades"
                ]
            }

```
When AIB executes these customizers, they are run as different sessions, so you cannot set global environment variables in the first Shell customizer, then consume them in the other customizers. If you want to consume variables in a customizer, they must be declared in the same customizer.

These are just some options:
1. Use Azure Resource Manager (ARM) templates, and use their parameters to feed in variables from a commandline.
2. Store a script in Azure Storage that sets environment variables, then download this into the VM, and execute inside the customizers.
3. Using Azure DevOps, you can do:
    * Use AZ CLI task, use a parameterized ARM Template, and use the [DevOps pipeline variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch) from the commandline.
    * Use a repo to store a script that sets global environment variables, then using the Azure VM [Image Builder DevOps Task](https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/1_Azure_DevOps#documentation-for-the-azure-vm-image-builder-devops-task), this will be dropped into the VM. 

>>Note! When thinking about these options, consider the security aspects, for example, parameters can be seen in AIB configuration templates.

## Using ARM Templates to Set Environment Variables for the Image Build
In this example we are going to use ARM template, and call it from the commandline. You can do this from the command line, or using an [AZ CLI task](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-cli?view=azure-devops) in Azure DevOps, and integrate with the [pipeline variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch).

### Step 1: Set Variables Create Resource Group

```bash
# set your environment variables here!!!!

# name of destination image resource group
imgResourceGroup=aibVars

# location
svcLocation=westus

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=<subscriptionID>

# version number, generated from date
version=$(date +'%s')

# name of the image to be created
managedImageName=Ubuntu$version

# managed image resource group ID
managedImageResGroupId="/subscriptions/$subscriptionID/resourceGroups/$imgResourceGroup/providers/Microsoft.Compute/images/"

# image template name
imageTemplateName=tmpVarsUb$version

# image distribution metadata reference name
runOutputName=Ubuntu$version

# create resource group
az group create -n $imgResourceGroup -l $svcLocation

# assign permissions for that resource group
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role Contributor \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imgResourceGroup

```

### Step 1b Setup Variables for Template
```bash
packagesToInstall=nginx-light
targetOS=MoonlightOS 
```

### Step 2 Submit AIB Template from CmdLine, passing in params
```bash

templateUri='https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/4_Using_ENV_Variables/devOpsEnvTemplate.json'

 

az group deployment create -g $imgResourceGroup \
                            --template-uri $templateUri \
                            --parameters \
                            imageTemplateName=$imageTemplateName \
                            svcLocation=$svcLocation \
                            managedImageResGroupId=$managedImageResGroupId \
                            managedImageName=$managedImageName \
                            packagesToInstall=$packagesToInstall \
                            targetOS=$targetOS
```

When complete, you can check the template, and ensure the parameters have been set:
```bash
az resource show \
    --resource-group $imgResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n $imageTemplateName 
```

### Step 3 Initiate the Image Build
```bash
az resource invoke-action \
     --resource-group $imgResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n $imageTemplateName  \
     --action Run 
```

## Step 4 : Create the VM

```bash
az vm create \
  --resource-group $imgResourceGroup \
  --name aibImgVm0010 \
  --admin-username aibuser \
  --image $managedImageName \
  --location $svcLocation \
  --generate-ssh-keys

```

## Step 5 : Login into the VM and check config
```bash
ssh aibuser@<pubIp>
```

Check the MoonlightOS directory was created:
```bash
ls /
```
You should see:
```bash
MoonlightOS  boot ..
```

Check that the nginx-light package was installed:
```bash
apt list nginx-light
```
You should see this:
```bash
Listing... Done
nginx-light/bionic-updates,now 1.14.0-0ubuntu1.3 amd64 [installed]
```




## Clean Up
```bash
az resource delete \
    --resource-group $imgResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n $imageTemplateName 


az group delete -n $imgResourceGroup 
```

## Next Steps
If you loved or hated Image Builder, please go to next steps to leave feedback, contact dev team, more documentation, or try more examples [here](../../quickquickstarts/nextSteps.md)]

