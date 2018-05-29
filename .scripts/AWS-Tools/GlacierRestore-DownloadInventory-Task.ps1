# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory = $null
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-DownloadInventory-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
$DataDirectory = Join-Path $TaskDirectory $env:data
If ($NextTaskDirectory) {
  $NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
}
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $DataDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "download-inventory-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($true) {
  Try {
    $files = Get-ChildItem $PendingDirectory -Filter $pattern
    If ($files.Count -gt 0) {
      $file = $(Move-Item -LiteralPath $files[0].FullName -Destination $ProcessingDirectory -PassThru -Verbose:$Verbose).FullName
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose
        
        Set-AwsCredentials $config.AccessKey $(ConvertFrom-ProtectedString $config.ProtectedSecretKey) -Verbose:$Verbose

		    $outfile = Join-Path $DataDirectory "inventory-[job#$(Get-StringStart -InputString $config.JobId -Length $env:MaxIdSize)].json"

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
            Throw "Download inventory task failed (jobid=$($config.JobId))"
          }
          $size = (Get-Item -LiteralPath $outfile).Length
          If ($size -ne $config.Size) {
            "Size of downloaded inventory file '$outfile' does not match expected file size of $($config.Size) bytes: $size" | Out-Log -Level Warning | Write-Host
          }
          If ($NextTaskDirectory) {
            Read-JsonFile $outfile `
              | Select-Object -ExpandProperty ArchiveList `
              | ForEach-Object { @{Archive=$_; Description=$(ConvertFrom-Json -InputObject $_.ArchiveDescription)} } `
              | Where-Object { $_.Description.type -eq 'file' } `
              | Invoke-Script { 
                "Retieved inventory of vault '$($config.VaultName)' containing $($_.Count) archives" | Out-Log -Level Information | Write-Host
                } `
              | ForEach-Object {
                $nextTaskFile = Join-Path $NextTaskDirectory "request-archive-[obj#$(Get-StringStart -InputString $_.Archive.ArchiveId -Length $env:MaxIdSize)].json"
                "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host
                $config `
                  | Get-ShallowCopy -ExcludeProperty "JobId" `
                  | Add-Member ArchivePath $_.Description.path -PassThru -Verbose:$Verbose `
                  | Add-Member ArchiveId $_.Archive.ArchiveId -PassThru -Verbose:$Verbose `
                  | Add-Member Size $_.Archive.Size -PassThru -Verbose:$Verbose `
                  | Add-Member SHA256Hash $_.Archive.SHA256TreeHash -PassThru -Verbose:$Verbose `
                  | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
                }
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
          Throw "Downloading inventory failed (job#$($config.JobId)): DownloadResponse: '$result', JobStatus: '$job'"
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