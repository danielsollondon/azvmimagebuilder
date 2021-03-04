# Adding Tags to the Staging Resource Group
When you submit a template to Azure Image Builder (AIB), a Staging resource group will be IT_<templateName>_<resourceGroup>_guid, natively AIB does not provide an option to add [Azure Tags](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources) to this group. However AIB does apply Tags it uses for the service, these must not be removed, but you can add additional Tags, should you require these for billing, identificaton.


The examples below will appends tags, you must not remove the existing ones after you submit the template to the service, which creates the staging resource group.

>>Note! Sometimes the names of the template and resource group can be truncated, so please test to identify the right predicates for the filters below.

## PowerShell

```PowerShell
# Submit template
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2020-02-14" -imageTemplateName $imageTemplateName -svclocation $location

# Add tags
$imageResourceGroup="aibImageRG000033"
$imageTemplateName="davecesarworking"
$location="westus2"

$resourceGroupName=Get-AzResourceGroup -Location $location| Where ResourceGroupName -like IT_$imageResourceGroup"_"$imageTemplateName*
$Tags = (Get-AzResourceGroup -Name $resourceGroupName.ResourceGroupName).Tags
$Tags += @{"Status5"="Approved"}
Set-AzResourceGroup -Name $resourceGroupName.ResourceGroupName -Tag $Tags
```

## Linux 
```bash
# Submit template
az resource create \
    --resource-group $imageResourceGroup \
    --properties @helloImageTemplateLinux.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplateLinux01

# Add tags
imageResourceGroup="aibImageRG000033"
imageTemplateName="davecesarworking"

resourceGroupName=$(az group list --query "[?contains(name, 'IT_$imageResourceGroup"_"$imageTemplateName')].[name]" --output tsv)

az group update --resource-group $resourceGroupName --set tags.Status3=Approved
```

