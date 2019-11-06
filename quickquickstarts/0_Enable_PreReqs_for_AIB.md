# Enabling PreReqs for AIB

For Image Builder to work, you need to register for Azure Features, please see the relevent AZCLI or PowerShell.

## AZ CLI
### Register for Image Builder / VM / Storage Features
```bash
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview

az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview | grep state

# register and enable for shared image gallery
az feature register --namespace Microsoft.Compute --name GalleryPreview

# wait until it says registered

# check you are registered for the providers

az provider show -n Microsoft.VirtualMachineImages | grep registrationState

az provider show -n Microsoft.Storage | grep registrationState

az provider show -n Microsoft.Compute | grep registrationState

az provider show -n Microsoft.KeyVault | grep registrationState
```

If they do not saw registered, run the commented out code below.
```bash
## az provider register -n Microsoft.VirtualMachineImages

## az provider register -n Microsoft.Storage

## az provider register -n Microsoft.Compute

## az provider register -n Microsoft.KeyVault

```

## PowerShell

