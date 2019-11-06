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
  
