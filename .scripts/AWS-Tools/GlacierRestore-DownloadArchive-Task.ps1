# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory = $null
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-DownloadArchive-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
$DataDirectory = Join-Path $TaskDirectory $env:data
If ($NextTaskDirectory) {
  $NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
}
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $DataDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "download-archive-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($true) {
  Try {
    $files = Get-ChildItem $PendingDirectory -Filter $pattern
    If ($files.Count -gt 0) {
      $file = $(Move-Item -LiteralPath $files[0].FullName -Destination $ProcessingDirectory -PassThru -Verbose:$Verbose).FullName
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose
        
        Set-AwsCredentials $config.AccessKey $(ConvertFrom-ProtectedString $config.ProtectedSecretKey) -Verbose:$Verbose

        $outfile = Join-Path $DataDirectory "archive-[obj#$(Get-StringStart -InputString $config.ArchiveId -Length $env:MaxIdSize)].dat"

        $result = Send-AwsCommand glacier get-job-output `
          "--account-id=$($config.AccountId)" `
          "--region=$($config.Region)" `
          "--vault-name=$($config.VaultName)" `
          "--job-id=$($config.JobId)" `
          $outfile `
          -JsonResult `
          -Verbose:$Verbose
    
        If ($result.status -eq 200) {
          If (-Not (Test-Path -LiteralPath $outfile)) {
            Throw "Download archive task failed (jobid=$($config.JobId)) (archiveid=$($config.ArchiveId))"
          }
          $size = (Get-Item -LiteralPath $outfile).Length
          If ($size -ne $config.Size) {
            "Size of downloaded archive file '$outfile' does not match expected file size of $($config.Size) bytes: $size" | Out-Log -Level Warning | Write-Host
          }
          $hash = (Get-FileHash -LiteralPath $outfile -Algorithm SHA256).Hash.ToLower()
          If ($hash -ne $config.SHA256Hash) {
            "SHA256 hash of downloaded archive file '$outfile' does not match expected hash $($config.SHA256Hash): $hash" | Out-Log -Level Warning | Write-Host
          }
          If ($NextTaskDirectory) {
            $nextTaskFile = Join-Path $NextTaskDirectory "decrypt-archive-[obj#$(Get-StringStart -InputString $config.ArchiveId -Length 20)].json"
            "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host
            @{
              ArchiveId = $config.ArchiveId
              ArchivePath = $config.ArchivePath
              ProtectedDecryptionPassword = $config.ProtectedDecryptionPassword
              RestoreDirectory = $config.RestoreDirectory
              VaultName = $config.VaultName
              SourceFile = $outfile
            } | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
          }
          
          Move-Item -LiteralPath $file -Destination $SucceessDirectory -Verbose:$Verbose
        } Else {
          Try {
            $job = Send-AwsCommand glacier describe-job `
              "--account-id=$($config.AccountId)" `
              "--region=$($config.Region)" `
              "--vault-name=$($config.VaultName)" `
              "--job-id=$($config.JobId)" `
              -JsonResult `
              -Verbose:$Verbose
          } Catch { }
          Throw "Downloading archive failed (job#$($config.JobId)): DownloadResponse: '$result', JobStatus: '$job'"
        }
      }
      Catch {
        Move-Item -LiteralPath $file -Destination $FailureDirectory -Verbose:$Verbose
        Throw $_.Exception
      }
    } Else {
      Start-RandomSleep -Minimum 30000 -Maximum 60000 -Verbose:$Verbose
    }
  }
  Catch {
    "Exception: '$($_.Exception.Message)'" | Out-Log -Level Error | Write-Error
    Start-Sleep -Seconds 60 -Verbose:$Verbose
  }
}