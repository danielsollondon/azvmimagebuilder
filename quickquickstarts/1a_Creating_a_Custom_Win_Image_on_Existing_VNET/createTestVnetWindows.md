# OPTIONAL: Create VNET \ Subnet \ NSG (only if you do not have an existing VNET)

This is to used with '01a_Creating_a_Custom_Win_Image_on_Existing_VNET' example.

```powerShell
New-AzResourceGroup -Name $vnetRgName -Location $location

## Create base NSG to simulate an existing NSG
New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $vnetRgName -location $location
```

## OPTIONAL - create an existing VNET for AIB to use (for the demo, it will be created in the same RG)
>>>> NOTE! The VNET must always be in the same region as the AIB service region.

```powerShell

$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $vnetRgName 

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.1.0/24" -PrivateLinkServiceNetworkPoliciesFlag "Disabled" -NetworkSecurityGroup $nsg

New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRgName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet
```



