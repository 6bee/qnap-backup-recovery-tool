# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-RequestInventory-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
$NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "request-inventory-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($true) {
  Try {
    $files = Get-ChildItem $PendingDirectory -Filter $pattern -Verbose:$Verbose
    If ($files.Count -gt 0) {
      $file = $(Move-Item -LiteralPath $files[0].FullName -Destination $ProcessingDirectory -PassThru -Verbose:$Verbose).FullName
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose        
        Set-AwsCredentials $config.AccessKey $(ConvertFrom-ProtectedString $config.ProtectedSecretKey) -Verbose:$Verbose
        $config.Vaults | ForEach-Object {
          $job = Send-AwsCommand glacier initiate-job `
            "--account-id=$($config.AccountId)" `
            "--region=$($config.Region)" `
            "--vault-name=$($_.VaultName)" `
            "--job-parameters" "Type=inventory-retrieval" `
            -JsonResult `
            -Verbose:$Verbose
          
          If (!$job) {
            Throw "Failed to initiate inventory-retrieval job for vault name '$($_.VaultName)'"
          }

          $nextTaskFile = Join-Path $NextTaskDirectory "poll-inventory-job-[job#$(Get-StringStart -InputString $job.jobId -Length $env:MaxIdSize)].json"
          "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host
          $config `
            | Get-ShallowCopy -ExcludeProperty "Vaults" `
            | Add-Member VaultName $_.VaultName -PassThru -Verbose:$Verbose `
            | Add-Member JobId $job.jobId -PassThru -Verbose:$Verbose `
            | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
        }

        Move-Item -LiteralPath $file -Destination $SucceessDirectory -Verbose:$Verbose
      }
      Catch {
        Move-Item -LiteralPath $file -Destination $FailureDirectory -Verbose:$Verbose
        Throw $_.Exception
      }
    } Else {
      Start-RandomSleep -Verbose:$Verbose
    }
  }
  Catch {
    "Exception: '$($_.Exception.Message)'" | Out-Log -Level Error | Write-Error
    Start-Sleep -Seconds 60 -Verbose:$Verbose
  }
}