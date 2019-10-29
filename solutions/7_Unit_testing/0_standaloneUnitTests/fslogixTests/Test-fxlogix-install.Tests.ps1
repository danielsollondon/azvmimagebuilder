$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Test-fxlogix-install" {

    $fxlogixRunning=Get-Service -Name frxsvc | Where-Object {$_.Status -eq "Running"}
    $fxlogixVersion=(Get-Item 'C:\Program Files\FSLogix\Apps\frxsvc.exe').VersionInfo.FileVersion

    It 'Check fslogix Service is Running' {
        $fxlogixRunning.Status | Should -Be 'runnin'
    }

    It 'Check fslogix Service Executable Version' {
        $fxlogixVersion | Should -Be '2.9.7205.27375'

    }

}
