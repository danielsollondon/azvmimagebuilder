Param ($endPoint, $jobId)
# script to setup IIS server
# step1 - enable telemetry, script expects $endpoint for endpoint to send messages and $jobId, just a monotonic int. 

## Enable Telemetry
##===========================
function send-aibRealTime {
# function to send customizer telemetry for AIB customizations, to call:
# send-aibRealTime -endpoint $endPoint -jobId $jobId -stepType $stepType -stepName $stepName -msg $msg -statusCode $statusCode -status $status
# $endpoint, $jobId is mandatory, 
Param ([string]$endPoint, [string]$jobId,[string]$stepType,[string]$stepName,[string]$msg,[string]$statusCode, [string]$status)

$sendBody = @{'jobId' = $jobId
              'stepType'= $stepType
              'stepName' = $stepName
              'msg' = $msg
              'statusCode' = $statusCode
              'status' = $status
              }
    try
        {
            $sendEvent = Invoke-WebRequest $endPoint  -Body  ($sendBody|ConvertTo-Json) -Method 'POST' -ContentType "application/json"
            Write-Host "AIB Event sent JobID: $jobId Message: $msg"
        }
    Catch
        {
            Write-Host "AIB Event Failed to Send: JobID"
            $ErrorMessage = $_.Exception.Message
        }
    }
 


## Step 2: Install IIS Server
##===========================
Try
{
        send-aibRealTime -endpoint $endPoint -jobId $jobId -stepType 'customize' -stepName 'iis install' -msg 'iis configuration starting' 
        
        # Install IIS Website
        Install-WindowsFeature -name Web-Server -IncludeManagementTools

        # Setup directory
        $path = "C:\ImageBuilderWebApp"
        If(!(test-path $path))
        {
        New-Item $path -type Directory
        }
        # Copy over build artifacts
        Copy-Item "C:\buildArtifacts\webApp\Default.htm" -Destination "C:\ImageBuilderWebApp" -Recurse -Force
        
        send-aibRealTime -endpoint $endPoint -jobId $jobId -stepType 'customize' -stepName 'iis install' -msg 'iis install completed' -status 'success'
}
Catch
{
        Write-Host "Website Feature Install Failed"
        $ErrorMessage = $_.Exception.Message

        send-aibRealTime -endpoint $endPoint -jobId $jobId -stepType 'customize' -stepName 'iis install' -msg $ErrorMessage -status 'failed'

        Write-Host $ErrorMessage

} 


## Step 3: Conig IIS Server
##===========================
Try
{

        # Create site
        New-IISSite -Name "ImageBuilderWebApp" -BindingInformation "*:8080:" -PhysicalPath "C:\ImageBuilderWebApp" 

        # Open firewall port for 8080
        New-NetFirewallRule -DisplayName "Allow Outbound Port 8080" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow

        send-aibRealTime -endpoint $endPoint -jobId $jobId -stepType 'customize' -stepName 'iis config' -msg 'iis setup and config completed' -status 'success'
}
Catch
{
        Write-Host "Website Feature Config Failed"
        $ErrorMessage = $_.Exception.Message

        send-aibRealTime -endpoint $endPoint -jobId $jobId -stepType 'customize' -stepName 'iis config' -msg $ErrorMessage -status 'failed'

        Write-Host $ErrorMessage
}  
