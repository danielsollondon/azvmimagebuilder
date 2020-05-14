# SERVICE UPDATE May 2020: ACTION NEEDED - Please Review

We are making key changes to Azure Image Builder security model, this will be a breaking change, therefore we require you to take these before **26th May 0700 Pacific Time**.

**The change** - Azure Image Builder Templates (AIB) must contain a populated [`identity`](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json#identity) property, and the user assigned identity must have permissions to read and write images.

**Impact** - From the 26th May 0700 we will not accepting any new AIB Templates or process existing AIB Templates that do not contain a populated [`identity`](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json#identity). This also means any templates being submitted with api versions earlier than `2019-05-01-preview` will not be be accepted either.

**Why?** - As well as allow us to prepare for future features, we are simplifying and improving the AIB security model, so instead of you granting permissions the AIB Service Principal Name, to build and distribute custom images, and then a user identity to you will now use a single user identity to get access to other Azure resources.

## Actions Required
### [1. Create a user assigned 'identity'](https://github.com/danielsollondon/azvmimagebuilder/blob/master/aibPermissions.md#creating-an-azure-user-assigned-managed-identity)
### 2. Grant the permissions to the user assigned identity, ([AZ CLI](https://github.com/danielsollondon/azvmimagebuilder/blob/master/aibPermissions.md#az-cli-examples), [PowerShell](https://github.com/danielsollondon/azvmimagebuilder/blob/master/aibPermissions.md#azure-powershell-examples)) to the resource groups
### 3. [Update your JSON templates with the 'identity'](https://github.com/danielsollondon/azvmimagebuilder/blob/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json#L30), adding this property to the template:

```
    "identity": {
        "type": "UserAssigned",
                "userAssignedIdentities": {
                "<imgBuilderId>": {}
                    
            }
```
Then update `<imgBuilderId>` with the user identity resourceId, using PowerShell:
```PowerShell
$idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
```
AZ CLI:
```bash
imgBuilderId=/subscriptions/$subscriptionID/resourcegroups/$imageResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$idenityName
```
### 4. Submit your JSON template to the service.

### 5. Remove the old version of the template that does not contain property.

If you want to see end to end examples, all the [quick starts](https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts) and [Azure Docs](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-overview) have been updated with user assigned idenity support.

### 6. Remove previously granted role assignments from the SPN
```powershell

$aibSpnId=$(Get-AzADServicePrincipal -ServicePrincipalName cf32a0cc-373c-47c9-9156-0db11f6a6dfc)

Remove-AzRoleAssignment -ObjectId $aibSpnId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

## contributor is also an example of a RoleDefinitionName
```

```bash
az role assignment delete \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role "Azure Image Builder Service Image Creation Role" \ # contributor is also an example of a role
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup
```

## FAQ
* **Can I delete the AIB Service Principal now?** No, you should not delete the AIB Service Principal, as this is required for creating the temporary staging *IT_* resource groups. But you can remove permissions / actions granted to your resource groups that you use in the image build, such as source image or distribution resource groups.

* **What is the plan for the Azure AIB DevOps task?**
The AIB DevOps task will continue to work as-is, until the 4th June, it will then be automatically updated to support `identity`. We will release an update to the Unstable AIB DevOps task before, so you can prepare, more details to follow, please monitor this page and the Teams channel for updates.

* **Are there any more service updates scheduled soon?**
We will be releasing a new API version (2020-02-14) on the 26th May too, existing templates that already support the above change, should continue to work, with an exception change to templates that use existing VNETs, a minor update will be required, this will be:

In the 2019-05-01-preview API Version you would specify:
```bash
    "vnetConfig": {
        "name": "<vnetName>",
        "subnetName": "<subnetName>",
        "resourceGroupName": "<vnetRgName>"
```
The three properties are no longer supported in new API, instead you need to just need to provide the resourceID of the subnet:
```bash
    "vnetConfig": {
        "subnetId": "<subnetResourceID>",
```
The subnetId is expected in this format:
`/subscriptions/<subId>/resourceGroups/<rgName>/providers/Microsoft.Network/virtualNetworks/<vnetName>/subnets/<subnetName>`

You can get the `subnetResourceID` from CLI/PS or Portal:
```powerShell
# VNET name
$vnetName=myexistingvnet01
# subnet name
$subnetName=subnet01
# VNET resource group name
$vnetRgName=existingVnetRG

$vnetConfig=$(Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRgName)
$subnetResourceId=$(Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnetConfig).Id
$subnetResourceId
```

```bash
# VNET name
vnetName=myexistingvnet01
# subnet name
subnetName=subnet01
# VNET resource group name
vnetRgName=existingVnetRG
subnetResourceId=$(az network vnet subnet show -g $vnetRgName -n $subnetName --vnet-name $vnetName --query id -o json | tr -d '"')
echo subnetResourceId
```


* **Why is there a date of 1st June on the [Azure Docs page](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-overview#permissions) for this change?** We needed to bring the change forward, due to dependencies, the page is being updated on 19th May, but the date for rejection of templates without 'identity' is 26th May.

* More questions, pl


