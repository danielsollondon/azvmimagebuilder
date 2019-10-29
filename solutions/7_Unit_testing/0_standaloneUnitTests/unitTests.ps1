# Download, Install Pester, Upgrade, and run Unit test

# set test file location
$Testfxlogixinstall = 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/7_Unit_testing/0_standaloneUnitTests/fslogixTests/Test-fxlogix-install.ps1'
$TestfxlogixinstallTests = 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/7_Unit_testing/0_standaloneUnitTests/fslogixTests/Test-fxlogix-install.Tests.ps1'


# install Pester, and run install unit tests
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force


Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force

## this installs the oldest
# Cert is different from PS Gallery so we need to do some additional parameters
Install-Module -Name Pester -Force -SkipPublisherCheck

# Now you can update the module
Update-Module -Name Pester

# force update to right module
Import-Module -Name Pester

# Quick look at the commands
Get-Command -Module Pester


Try
{
    $path ="c:\pester"
    mkdir $path\tests
}

Catch
{
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage
    $FailedItem = $_.Exception.ItemName
    Write-Host $FailedItem
}


# copy down tests from git

Invoke-WebRequest $Testfxlogixinstall -OutFile $path\tests\Test-fxlogix-install.ps1
Invoke-WebRequest $TestfxlogixinstallTests -OutFile $path\tests\Test-fxlogix-install.Tests.ps1    

cd $path\tests
$resultsFile = "$path\tests\TestResults.xml"
$result = Invoke-Pester -PassThru -OutputFile $resultsFile -OutputFormat NUnitXml


If ($result.FailedCount -ne 0) {
  Write-host 'More than one test has failed, details:' $resultsFile

  }  Else {

  Write-host 'Tests have passed...Yeee haaaaaa'

} 
  
