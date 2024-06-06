# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory = $null
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-GenerateArchiveRequests-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
If ($NextTaskDirectory) {
  $NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
}
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "generate-archive-requests-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($true) {
  Try {
    $files = Get-ChildItem $PendingDirectory -Filter $pattern
    If ($files.Count -gt 0) {
      $file = $(Move-ItemToDirectory -LiteralPath $files[0].FullName -Destination $ProcessingDirectory -Force -PassThru -Verbose:$Verbose).FullName
      Out-Log "Received $file" -Level Verbose
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose
        Out-Log "Parsed $file" -Level Verbose
        Out-Log "Start with inventory $($config.InventoryFile)" -Level Verbose

        Read-JsonFile $config.InventoryFile `
          | Select-Object -ExpandProperty ArchiveList `
          | ForEach-Object {
            $archiveId=$($_.ArchiveId);
            $size=$_.Size;
            $sha256TreeHash=$_.SHA256TreeHash;
            $desc=($_.ArchiveDescription -join "").Trim()

            function parse_json() {
              Out-Log "Parsing ArchiveDescription as json: '$desc'" -Level Verbose
              $d=$(ConvertFrom-Json -InputObject $desc)
              @{Type=$d.type; Path=$d.path}
            }

            function parse_xml() {
              Out-Log "Parsing ArchiveDescription as xml: '$desc'" -Level Verbose
              $base64=$(Select-Xml -Content $desc -XPath "//m/p").ToString()
              $path=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
              Out-Log "retrieved path from xml: '$path'" -Level Verbose
              @{Type="file"; Path=$path}
            }

            function handle_default() {
              Out-Log "Unknown format of ArchiveDescription: '$desc'" -Level Warning
              @{Type="unknown"; Path="undefined"}
            }

            switch ($desc[0]) {
              '{' { $f=parse_json }
              '<' { $f=parse_xml }
              default { $f=handle_default }
            }

            @{
              ArchiveId=$archiveId;
              Size=$size;
              SHA256TreeHash=$sha256TreeHash;
              Path=$f.Path;
              Type=$f.Type;
            } } `
          | Where-Object { $_.Type -eq 'file' } `
          | ForEach-Object {
            $nextTaskFile = Join-Path $NextTaskDirectory "request-archive-[obj#$(Get-StringStart -InputString "$($_.ArchiveId)" -Length $env:MaxIdSize)].json"
            "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host
            $config `
              | Get-ShallowCopy -ExcludeProperty JobId, InventoryFile, Predecessor `
              | Add-Member ArchivePath $_.Path -PassThru -Verbose:$Verbose `
              | Add-Member ArchiveId "$($_.ArchiveId)" -PassThru -Verbose:$Verbose `
              | Add-Member Size $_.Size -PassThru -Verbose:$Verbose `
              | Add-Member SHA256Hash $_.SHA256TreeHash -PassThru -Verbose:$Verbose `
              | Add-Member Predecessor $([System.IO.Path]::GetFileName($file)) -PassThru -Verbose:$Verbose `
              | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
            }

        Move-ItemToDirectory -LiteralPath $file -Destination $SucceessDirectory -Force -Verbose:$Verbose
      }
      Catch {
        Move-ItemToDirectory -LiteralPath $file -Destination $FailureDirectory -Force -Verbose:$Verbose
        Throw $_.Exception
      }
    } Else {
      Start-RandomSleep -Verbose:$Verbose
    }
  }
  Catch {
    "Exception: '$($_.Exception.Message)'" | Out-Log -Level Error | Write-Error
    Start-Sleep -Seconds 10 -Verbose:$Verbose
  }
}