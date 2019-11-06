$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Test-webAppInstall-install" {

    $siteInstalled = Get-IISSite
    $siteSvcState = Get-IISSite "ImageBuilderWebApp"
    $appTest= Invoke-WebRequest http://localhost:8080  -Method 'GET' 
    $content = $appTest.Content 

    
    It 'Check website exist is installed' {
        $siteInstalled.Name  | Should -Contain 'ImageBuilderWebApp'

    }
    It 'Check website service is Started' {
        $siteSvcState.State | Should -Be 'Started'
    }

    It 'Check page response status code' {
        $appTest.StatusCode | Should -Be '200'

    }
    It 'Check page contents status contains Overview' {
        $content | Should -Contain 'Overview'

    }

} 
