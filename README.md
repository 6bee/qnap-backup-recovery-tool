# QNAP-BACKUP-RECOVERY-TOOL

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

**If anything goes wrong**

As long the data remains provisioned for recovery on AWS Glacier, *GlacierRestore-Run-BackgroundTasks.cmd* may be re-launched to resume on data recovery triggered earlier.

All processing is file based. Each process step takes it's input from the file system and writes it's output, as the next step's input, to the file system too. Each step's input file is moved along a folder structure, representing it's current state: 

1. `pending` contains json requests to be processed.
2. `processing` contains json requests which are currently being processed.
3. `success` contains json requests which have completed successfully.
4. `failure` contains json requests which have been processed unsuccessfully.
5. `data` contains the process step's results, e.g. downloaded files, decompressed files, etc.

To resume a failed request, the corresponding json file may simply be moved from *failure* directory back to *pending* to be picked-up and processed again.

A log file as well as all json files are stored in *%temp%\qnap-backup-recovery-tool*.

**File Name Recovery**
Since Glacier does not deal with files but handles binary blobs only, QNAP stores file information in the so called `ArchiveDescription` field which is part of the metadata than can be set for each blob:
```json
{
  "ArchiveId": "abc...",
  "ArchiveDescription": "{\"path\": \"/sample/1234.pdf\", \"type\": \"file\"}",
  "CreationDate": "2016-05-01T10:00:59Z",
  "Size": 8388,
  "SHA256TreeHash": "5ad1a94..."
 }
```

Hence, recovery scripts are extracting file name and path from the *ArchiveDescription*.

However, depending on the application and version used to create the backup, *ArchiveDescription* may be stored in different formats. While the above sample was created using the "Glacier" backup app, "Hybrid Backup Sync (HBS)" apparently sets the *ArchiveDescription* as xml with the file path encoded in *base64*:

```json
{
  "ArchiveId": "abc...",
  "ArchiveDescription": "<m><v>4</v><p>L3NhbXBsZS8xMjM0LnBkZg==</p><lm>20190501T100059Z</lm></m>",
  "CreationDate": "2019-05-01T10:00:59Z",
  "Size": 8388,
  "SHA256TreeHash": "5ad1a94..."
 }
```