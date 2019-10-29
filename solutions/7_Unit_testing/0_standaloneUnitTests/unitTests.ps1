  # Download, Install Pester, Upgrade, and run Unit test


  Try
  {
   # set test file location
      $Testfxlogixinstall = 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/7_Unit_testing/0_standaloneUnitTests/fslogixTests/Test-fxlogix-install.ps1'
      $TestfxlogixinstallTests = 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/7_Unit_testing/0_standaloneUnitTests/fslogixTests/Test-fxlogix-install.Tests.ps1'
  
  
      # install Pester, and run install unit tests
      #Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope CurrentUser, not needed if usng -executionpolicy bypass in calling command, which AIB does.
  
  
      Write-host 'Installing Nuget'
      Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force
  
      Write-host 'Installing Pester'
      ## this installs the oldest
      # Cert is different from PS Gallery so we need to do some additional parameters
      Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
      Import-Module -Name Pester -Force
  
      # Now you can update the module
      Update-Module -Name Pester
  
      # force update to right module
      Remove-Module -Name Pester
      Import-Module -Name Pester -Force
 
 
 
  
      # setup paths
      $path ="c:\pester"
      mkdir $path\tests
  
      # copy down tests from git
  
      Invoke-WebRequest $Testfxlogixinstall -OutFile $path\tests\Test-fxlogix-install.ps1
      Invoke-WebRequest $TestfxlogixinstallTests -OutFile $path\tests\Test-fxlogix-install.Tests.ps1    
  
      cd $path\tests
      $resultsFile = "$path\tests\TestResults.xml"
  }
  
  Catch
  {
      $ErrorMessage = $_.Exception.Message
      Write-Host $ErrorMessage
      $FailedItem = $_.Exception.ItemName
      Write-Host $FailedItem
  }
  
  
  # Run pester test
  Write-host 'Running Pester'
  $result = Invoke-Pester -PassThru -OutputFile $resultsFile -OutputFormat NUnitXml
  
  
  If ($result.FailedCount -ne 0) {
    Write-host 'More than one test has failed, details:' $resultsFile
    Write-Host $result.TestResult
    exit 11
  
    }  Else {
  
    Write-host 'Tests have passed...Yeee haaaaaa'
  
  } 
     
  s 
 