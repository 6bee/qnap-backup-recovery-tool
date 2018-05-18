# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
  Parts of this module use the OpenSSL program.
  OpenSSL is licensed under the Apache License 1.0.
  www.openssl.org
#>

# setup
If (-Not (Test-Path Variable:openssl)) {
  $env:OPENSSL_CONF = Join-Path $Tools "OpenSSL\bin\openssl.cnf"
  $openssl = Join-Path $Tools "OpenSSL\bin\openssl.exe"
}

<# 
 .Synopsis
  Decrypt file

 .Description
  Decrypt file previously encrypted by QNAP backup program using OpenSSL
  
 .Parameter SourceFilePath
  Source file
  
 .Parameter DestinatonFilePath
  Destinatoin file
  
 .Parameter Key
  Key

 .Example
  Invoke-DecryptFile "C:\Encrypted.dat" "C:\Decrypted.dat" "abcdefghijklmnopqrstuvxyz"
#>
Function Invoke-DecryptFile {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true)]
    [string]$SourceFilePath,
    [Parameter(Mandatory=$true)]
    [string]$DestinatonFilePath,
    [Parameter(Mandatory=$true)]
    [string]$Key
  )
  $result = & "$openssl" "enc" "-d" "-aes-256-cbc" "-k" $Key "-in" $SourceFilePath "-out" $DestinatonFilePath
  Write-Verbose "$result"
  Write-Verbose "Decrypted '$SourceFilePath' -> '$DestinatonFilePath'"
}
  

<# 
 .Synopsis
  Encrypt string

 .Description
  Encrypt string using Windows Data Protection API (DPAPI)
  
 .Parameter Plaintext
  Plaintext

 .Example
  ConvertTo-ProtectedString $plaintext
#>
Function ConvertTo-ProtectedString {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$Plaintext
  )
  $ciphertext = $($Plaintext | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString)
  $PSCmdlet.WriteObject($ciphertext)
}
  
  

<# 
 .Synopsis
  Decrypt string

 .Description
  Decrypt string using Windows Data Protection API (DPAPI)
  
 .Parameter Ciphertext
  Ciphertext

 .Example
  ConvertFrom-ProtectedString $ciphertext
#>
Function ConvertFrom-ProtectedString {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$Ciphertext
  )
  $securestring = $ciphertext | ConvertTo-SecureString
  try {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
    $plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  } finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }  
  $PSCmdlet.WriteObject($plaintext)
}
