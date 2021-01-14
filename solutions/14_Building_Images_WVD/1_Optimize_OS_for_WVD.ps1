 # OS Optimizations for WVD
 write-host 'OS Optimizations for WVD'
 $appName = 'optimize'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath
 $osOptURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'
 $osOptURLexe = 'Windows_10_VDI_Optimize-master.zip'
 $outputPath = $LocalPath + '\' + $osOptURLexe
 Invoke-WebRequest -Uri $osOptURL -OutFile $outputPath
 write-host 'Starting OS Optimizations script'
 Expand-Archive -LiteralPath 'C:\\Optimize\\Windows_10_VDI_Optimize-master.zip' -DestinationPath $Localpath -Force -Verbose
 Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
 Set-Location -Path C:\\Optimize\\Virtual-Desktop-Optimization-Tool-master
 .\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Verbose
 write-host 'Starting OS Optimizations script'


 Start-Process -FilePath $outputPath -Args "/install /quiet /norestart /log vcdist.log" -Wait
 write-host 'Finished Install the latest Microsoft Visual C++ Redistributable'

