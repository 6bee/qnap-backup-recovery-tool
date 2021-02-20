# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.
#
# Display-Glacier-Vaults
#
[CmdletBinding()]
Param (
  [string]$ConfigurationFile = $( Read-Host "Input Account Info File Path, please" )
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module (Join-Path $PSScriptRoot "Utilities") -Force -Verbose:$Verbose
Import-Module (Join-Path $PSScriptRoot "AWS-Tools") -Force -Verbose:$Verbose

$configuration = Read-JsonFile -Path $ConfigurationFile -Verbose:$Verbose

Write-Verbose "Account Id: '$($configuration.AccountId)', Region: '$($configuration.Region)'"

Set-AwsCredentials $configuration.AccessKey $configuration.SecretKey -Verbose:$Verbose
Get-AwsGlacierVaults $configuration.AccountId $configuration.Region -Verbose:$Verbose
