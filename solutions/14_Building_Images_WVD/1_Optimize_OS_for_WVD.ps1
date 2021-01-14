 # OS Optimizations for WVD
 write-host 'AIB Customization: OS Optimizations for WVD'
 $appName = 'optimize'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath
 $osOptURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'
 $osOptURLexe = 'Windows_10_VDI_Optimize-master.zip'
 $outputPath = $LocalPath + '\' + $osOptURLexe
 Invoke-WebRequest -Uri $osOptURL -OutFile $outputPath
 write-host 'AIB Customization: Starting OS Optimizations script'
 Expand-Archive -LiteralPath 'C:\\Optimize\\Windows_10_VDI_Optimize-master.zip' -DestinationPath $Localpath -Force -Verbose
 Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

 # Patch: overide the Win10_VirtualDesktop_Optimize.ps1 - setting 'Set-NetAdapterAdvancedProperty'(see readme.md)
 $updatePath= "C:\optimize\Virtual-Desktop-Optimization-Tool-master\Win10_VirtualDesktop_Optimize.ps1"
 ((Get-Content -path $updatePath -Raw) -replace 'Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB','#Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB') | Set-Content -Path $updatePath
 
# run script
 Set-Location -Path C:\\Optimize\\Virtual-Desktop-Optimization-Tool-master
 .\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Verbose
 write-host 'AIB Customization: Finished OS Optimizations script'


