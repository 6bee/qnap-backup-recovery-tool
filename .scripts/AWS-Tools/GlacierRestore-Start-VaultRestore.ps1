# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
 .Synopsis
  Start Restore of AWS Glacier Vault

 .Description
  Triggers restor of one or more AWS Glacier Vaults

 .Example
  Start-AwsGlacierVaultRestore "configuration.json"
#>
Function Invoke-TriggerAwsGlacierVaultRestore {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [object]$Configuration
  )

  $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
  $env:Logger = "TriggerAwsGlacierVaultRestore"

  $GlacierRequestInventoryPending = Join-Path $GlacierRequestInventory $env:pending

  New-DirectoryIfNotExists $GlacierRequestInventoryPending -Verbose:$Verbose

  $count = $(Get-ChildItem -Path $GlacierRequestInventory -Include "request-inventory-*.json" -Recurse).Count + 1
  $taskFile = Join-Path $GlacierRequestInventoryPending "request-inventory-$count.json"

  $Configuration `
    | Get-ShallowCopy -ExcludeProperty @("SecretKey", "DecryptionPassword") `
    | Add-Member ProtectedSecretKey $(ConvertTo-ProtectedString $Configuration.SecretKey) -PassThru -Verbose:$Verbose `
    | Add-Member ProtectedDecryptionPassword $(ConvertTo-ProtectedString $Configuration.DecryptionPassword) -PassThru -Verbose:$Verbose `
    | Invoke-Script {
      "Restore '$($config.VaultName)' --> Creating Task File: $taskFile" | Out-Log -Level Information | Write-Host
      } `
    | Write-JsonFile -Path $taskFile -Verbose:$Verbose
}