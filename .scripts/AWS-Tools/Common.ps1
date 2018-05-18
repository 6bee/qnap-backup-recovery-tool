# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<# 
 .Synopsis
  Set AWS Credentials

 .Description
  Sets AWS Credentials to corresponding environment variables

 .Parameter AccessKey
  AccessKey

 .Parameter SecretKey
  SecretKey

 .Example
  Get-Vaults "123456789012" "us-central-1"
#>
Function Set-AwsCredentials {
  [CmdletBinding()] Param (
    [string]$AccessKey,
    [string]$SecretKey
  )
  If($env:AWS_ACCESS_KEY_ID -ne $AccessKey) {
    Write-Verbose "Set-AwsCredentials AccessKey: $AccessKey, SecretKey: ******"
    $env:AWS_ACCESS_KEY_ID = $AccessKey
    $env:AWS_SECRET_ACCESS_KEY = $SecretKey	
  }
}



<# 
 .Synopsis
  Write AWS Account Info template

 .Description
  Generate an AWS Account Info template json file

 .Example
  Write-AwsConfigurationTemplate
#>
Function Write-AwsConfigurationTemplate {
  [CmdletBinding()] Param (
    [string]$File
  )

  Get-AwsConfigurationTemplate | Write-JsonFile -Path $File
}



<# 
.Synopsis
  Get AWS Account Info template object

.Description
  Get an AWS Account Info template object

.Example
  Get-AwsConfigurationTemplate
#>
Function Get-AwsConfigurationTemplate {
  [CmdletBinding()] Param ()

  $template = ConvertFrom-Json @"
{
  "AccountId": "123456789012",
  "Region": "eu-central-1",
  "AccessKey": "123456",
  "SecretKey": "123456/abcdef",
  "Vaults": [
    {
      "VaultName": "vault_1"
    },
    {
      "VaultName": "vault_2"
    }
  ],
  "S3Buckets": [
    {
      "S3Uri": "s3://bucket_1"
    },
    {
      "S3Uri": "s3://bucket_2/foo/bar"
    }
  ],
  "DecryptionPassword": "abcdefghijklmnopqrstuvwxyz",
  "RestoreDirectory": "restore-decrypted-decompressed"
}
"@

  $PSCmdlet.WriteObject($template)
}



<# 
 .Synopsis
  Run AWS Glacier Command

 .Description
  Sends a command to AWS Glacier CLI. 
  For more info about AWS Glacier CLI see http://docs.aws.amazon.com/cli/latest/reference/glacier/index.html#cli-aws-glacier'.

 .Parameter Arguments
  Argument list

 .Example
   Send-AwsCommand
#>
Function Send-AwsCommand {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$True, ValueFromRemainingArguments=$True)]
    [object[]]$Arguments,
    [switch]$JsonResult
  )
  "Send-AwsCommand aws $Arguments" | Out-Log | Write-Verbose

  $tools = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.tools"))
  $result = & "$tools\AWSCLI\AWSCLI-1.15\aws.exe" $Arguments

  If ($JsonResult) {
    $json = -join $($result | ForEach-Object { "$($_.Trim()) " } )
    "JSON RESULT: $json" | Out-Log | Write-Verbose
    $obj = ConvertFrom-Json -InputObject $json
    $PSCmdlet.WriteObject($obj)
  } Else {
    "RESULT: $result" | Out-Log | Write-Verbose
    $PSCmdlet.WriteObject($result)
  }
}
