# CS-Cart vBackup Script

## Introduction
This Bash script is designed to automate the backup process of a CS-Cart installation from a remote server. It includes features for backing up both the database and the files, listing and removing old backups, and ensuring data integrity through checksum verification.

## Requirements
- Bash shell
- SSH access to the remote server
- Docker installed on the remote server
- `scp` and `md5sum` utilities
- Properly set up `config.sh` file with necessary variables (`REMOTE_CERT`, `REMOTE_USER`, `REMOTE_HOST`, `LOCAL_DIR`, etc.)

## Installation
1. Clone the repository or download the script.
2. Ensure the script (`backup_script.sh`) is executable:
   ```bash
   chmod +x backup_script.sh
   ```
3. Create and configure the `config.sh` file with your server and local directory details.

## Usage
Run the script from your terminal:
```bash
./backup_script.sh
```
The script will connect to the remote server, execute the backup process, and transfer the latest backup file to the local directory specified in `config.sh`.

## Troubleshooting
- Ensure all configurations in `config.sh` are correct.
- Verify that the SSH keys are properly set up and have the correct permissions.
- Check if Docker is running on the remote server.
- Ensure the local directory has sufficient space and permissions for the backup files.
