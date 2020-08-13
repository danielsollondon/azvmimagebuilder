# Create a custom RHEL image using a RHEL ISO where you can use eligible Red Hat licences and export to VHD

> NOTICE! We are deprecating the ability to create images from RHEL ISO sources, however if you want to bring your own RedHat subscriptions, you can using steps from this [article](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/redhat/byos), and pass in the plan information to image builder [here](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json&bc=%2Fazure%2Fvirtual-machines%2Fwindows%2Fbreadcrumb%2Ftoc.json#support-for-market-place-plan-information).


```bash
Timelines:
* 31st March - Image Templates with RHEL ISO sources will now longer be accepted by the resource provider.
* 30th April - Image Templates that contain RHEL ISO sources will not be processed any more.
```

If this is impacting you, please raise an issue on GitHub.