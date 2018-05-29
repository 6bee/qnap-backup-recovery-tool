# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-PollArchiveJob-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
$NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "poll-archive-job-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($true) {
  Try {
    Get-ChildItem $PendingDirectory -Filter $pattern | Move-Item -Destination $ProcessingDirectory

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
    
        If ($job.Completed) {
          If ($job.StatusCode -eq "Succeeded") {
            $nextTaskFile = Join-Path $NextTaskDirectory "download-archive-[job#$(Get-StringStart -InputString $config.JobId -Length $env:MaxIdSize)].json"
            If ($job.ArchiveSizeInBytes -ne $config.Size) {
              "Size for archive file given in vault inventory ($($config.Size) bytes) is different from archive download job description ($($job.ArchiveSizeInBytes) bytes)" | Out-Log -Level Warning | Write-Host
            }
            "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host
            $config `
              | Get-ShallowCopy `
              | Add-Member Size $job.ArchiveSizeInBytes -PassThru -Verbose:$Verbose `
              | Add-Member SHA256Hash $job.ArchiveSHA256TreeHash.ToLower() -PassThru -Verbose:$Verbose `
              | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
            Move-Item -LiteralPath $file -Destination $SucceessDirectory -Verbose:$Verbose
    	    } Else {
            Throw "Polling archive job failed (jobid=$($config.JobId)): $job"
          } 
        } ElseIf(-Not $job) {
          "Polling archive job returned no result (jobid=$($config.JobId))" | Out-Log -Level Warning | Write-Warning
        }

        Start-RandomSleep -Maximum 2000 -Verbose:$Verbose
      }
      Catch {
        Move-Item -LiteralPath $file -Destination $FailureDirectory -Verbose:$Verbose
        Throw $_.Exception
      }
    }

    Start-Sleep -Seconds 600 -Verbose:$Verbose
  }
  Catch {
    "Exception: '$($_.Exception.Message)'" | Out-Log -Level Error | Write-Error
    Start-Sleep -Seconds 60 -Verbose:$Verbose
  }
}