# Modifying Shared Image Gallery Versions Post Image Build
When the Azure VM Image Builder injects the image into the Shared Image Gallery, it will use an intermediate disk snapshot, once the image is injected, it is deleted. Because it is deleted, previously you could not modify the properties of the image version, such as replicating to additional regions.

This has now been resolved, however, you must register for the feature below to do this, eventually this requirement will be lifted, i will update this article then.

To register your subscription for this capability, please run the below:

## AZ CLI
```bash
az feature register --namespace Microsoft.Compute --name GalleryRemoveUserSourceDependency
```

## PowerShell
```PowerShell
Register-AzProviderFeature -FeatureName GalleryRemoveUserSourceDependency -ProviderNamespace Microsoft.Compute
```
