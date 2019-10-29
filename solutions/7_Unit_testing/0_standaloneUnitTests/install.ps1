$fsLogixURL="https://aka.ms/fslogix_download"
$installerFile="fslogix_download.zip"

Try
{
    $path ="c:\Apps"
    mkdir $path
    Invoke-WebRequest $fsLogixURL -OutFile $path\$installerFile
    Expand-Archive $path\$installerFile -DestinationPath $path\fsLogix\extract
    Start-Process -FilePath $path\fsLogix\extract\x64\Release\FSLogixAppsSetup.exe -Args "/install /quiet /norestart" -Wait
    Write-Host "Install Succeeded"
    
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage
    $FailedItem = $_.Exception.ItemName
    Write-Host $FailedItem
}
