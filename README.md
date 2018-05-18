# QNAP-BACKUP-RECOVERY-TOOL

## Description
QNAP-BACKUP-RECOVERY-TOOL is a Powershell based application to restore backup records saved by QNAP (Hybrid Backup Sync) from `AWS S3` and `AWS Glacier`.


## How-to 

### Generate Configuration Template
Run `Generate-AWS-Configuration-Template.cmd`

### Restore S3 Bucket
Save `config.json` configuration file with the following structure and run the configuration with `Restore-S3-Bucket.cmd` for data recovery from S3 to the restore directory:
```
{
  "AccessKey": "123456",
  "SecretKey": "123456/abcdef",
  "S3Buckets": [
    {
      "S3Uri": "s3://bucket_1"
    },
    {
      "S3Uri": "s3://bucket_2/foo/bar"
    }
  ],
  "DecryptionPassword": "abcdefghijklmnopqrstuvwxyz",
  "RestoreDirectory": "C:\\restore-decrypted-decompressed\\S3"
}
```

### Restore Glacier Vault
Run `GlacierRestore-Run-BackgroundTasks.cmd` to run background processes and monitor progress.
Save `config.json` configuration file with the following structure and run the configuration with `GlacierRestore-Start-VaultRestore.cmd` to trigger async data recovery from Glacier to the restore directory:
```
{
    "AccountId":  "123456789012",
    "Region":  "eu-central-1",
    "AccessKey":  "123456",
    "SecretKey":  "123456/abcdef",
    "Vaults":  [
                   {
                       "VaultName":  "vault_1"
                   },
                   {
                       "VaultName":  "vault_2"
                   }
               ],
    "DecryptionPassword":  "abcdefghijklmnopqrstuvwxyz",
    "RestoreDirectory":  "C:\\restore-decrypted-decompressed\\Glacier"
}
```
