# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-PollInventoryJob-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
$NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "poll-inventory-job-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($true) {
  Try {
    Get-ChildItem $PendingDirectory -Filter $pattern | Move-Item -Destination $ProcessingDirectory -Force

    Get-ChildItem $ProcessingDirectory -Filter $pattern | ForEach-Object {
      $file = $_.FullName
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose        
        Set-AwsCredentials $config.AccessKey $(ConvertFrom-ProtectedString $config.ProtectedSecretKey) -Verbose:$Verbose    
        $job = Send-AwsCommand glacier describe-job `
          "--account-id=$($config.AccountId)" `
          "--region=$($config.Region)" `
          "--vault-name=$($config.VaultName)" `
          "--job-id=$($config.JobId)" `
          -JsonResult `
          -Verbose:$Verbose
    
        If($job.Completed) {
          If($job.StatusCode -eq "Succeeded") {
            $nextTaskFile = Join-Path $NextTaskDirectory "download-inventory-[job#$(Get-StringStart -InputString $config.JobId -Length $env:MaxIdSize)].json"
            "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host
            $config `
              | Get-ShallowCopy `
              | Add-Member Size $job.InventorySizeInBytes -PassThru -Verbose:$Verbose `
              | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
            Move-Item -LiteralPath $file -Destination $SucceessDirectory -Force -Verbose:$Verbose
          } Else {
            Throw "Polling inventory job failed (jobid=$($config.JobId)): $job"
          }
        } ElseIf(-Not $job) {
          "Polling inventory job returned no result (jobid=$($config.JobId))" | Out-Log -Level Warning | Write-Warning
        }
      }
      Catch {
        "Exception: '$($_.Exception.Message)'" | Out-Log -Level Error | Write-Error
        Start-Sleep -Seconds 60
      }
    }

    Start-Sleep -Seconds 300 -Verbose:$Verbose
  }
  Catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    "Exception: '$ErrorMessage' ($FailedItem)" | Out-Log -Level Error | Write-Error
    Start-Sleep -Seconds 10 -Verbose:$Verbose
  }
}