# OPTIONAL: Create VNET \ Subnet \ NSG (only if you do not have an existing VNET)

This is to used with '01a_Creating_a_Custom_Linux_Image_on_Existing_VNET' example.

```bash
az group create -n $vnetRgName -l $location

# NOTE! The VNET must always be in the same region as the AIB service region.
```

## OPTIONAL - create an existing VNET for AIB to use (for the demo, it will be created in the same RG)

```bash
az network vnet create \
    --resource-group $vnetRgName \
    --name $vnetName --address-prefix 10.0.0.0/16 \
    --subnet-name $subnetName --subnet-prefix 10.0.0.0/24

## create base NSG to simulate an existing NSG
az network nsg create -g $vnetRgName -n $nsgName

az network vnet subnet update \
    --resource-group $vnetRgName \
    --vnet-name $vnetName \
    --name $subnetName \
    --network-security-group $nsgName
    
#  NOTE! The VNET must always be in the same region as the AIB service region.

```