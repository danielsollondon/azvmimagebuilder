$fsLogixTestURL=


# install Pester, and run install unit tests

Install-Module -Name Pester -Force

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
cd $path\tests

Invoke-WebRequest $fsLogixTestURL -OutFile $path\$installerFile


$resultsFile = "$path\tests\TestResults.xml"
$result = Invoke-Pester -PassThru -OutputFile $resultsFile -OutputFormat NUnitXml


If ($result.FailedCount -ne 0) {
  Write-host 'More than one test has failed, details:' $resultsFile
  Write-host $details

  }  Else {

  Write-host 'Tests have passed...Yeee haaaaaa'

} 
 