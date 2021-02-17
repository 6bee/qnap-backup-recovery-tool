# QNAP-BACKUP-RECOVERY-TOOL
Version: 0.1

Author: christof.senn@gmail.com

Copyright © Christof Senn 2018

## Description
QNAP-BACKUP-RECOVERY-TOOL is a Powershell based application to restore backup records saved by *QNAP (Hybrid Backup Sync)* from *AWS S3* and *AWS Glacier*.


## How-to 

### Generate Configuration Template
Run *Generate-AWS-Configuration-Template.cmd* to generate a template file to be configured and used as *config.json* for data recovery.

### Restore S3 Buckets
Save *config.json* configuration file with the following structure and run the configuration with *Restore-S3-Bucket.cmd* for data recovery from AWS S3 to local restore directory:
```json
{
  "AccessKey": "123456",
  "SecretKey": "123456/abcdef",
  "S3Buckets": [
    { "S3Uri": "s3://bucket_1" },
    { "S3Uri": "s3://bucket_2/foo/bar" }
  ],
  "DecryptionPassword": "abcdefghijklmnopqrstuvwxyz",
  "RestoreDirectory": "C:\\restore-decrypted-decompressed\\S3"
}
```

### Restore Glacier Vaults
Data recovery from AWS Glacier requires multiple process to run:
1. Run *GlacierRestore-Run-BackgroundTasks.cmd* to run background processes and monitor progress.
2. Save *config.json* configuration file with the following structure and run the configuration with *GlacierRestore-Start-VaultRestore.cmd* to trigger asynchronous data recovery from AWS Glacier to local restore directory:
```json
{
  "AccountId": "123456789012",
  "Region": "eu-central-1",
  "AccessKey": "123456",
  "SecretKey": "123456/abcdef",
  "Vaults": [
    { "VaultName": "vault_1" },
    { "VaultName": "vault_2" }
  ],
  "DecryptionPassword": "abcdefghijklmnopqrstuvwxyz",
  "RestoreDirectory": "C:\\restore-decrypted-decompressed\\Glacier"
}
```

Note: As long the data remains provisioned for recovery on AWS Glacier, *GlacierRestore-Run-BackgroundTasks.cmd* may be re-launched to resume on data recovery triggered earlier.