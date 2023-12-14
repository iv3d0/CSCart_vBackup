#!/bin/bash

# Source the configuration file
source config.sh

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Clear the screen
clear

# Print the intro with "VEDO"
echo -e "${CYAN}██╗   ██╗███████╗██████╗  ██████╗ ${NC}"
echo -e "${CYAN}██║   ██║██╔════╝██╔══██╗██╔═══██╗${NC}"
echo -e "${CYAN}██║   ██║█████╗  ██║  ██║██║   ██║${NC}"
echo -e "${CYAN}╚██╗ ██╔╝██╔══╝  ██║  ██║██║   ██║${NC}"
echo -e "${CYAN} ╚████╔╝ ███████╗██████╔╝╚██████╔╝${NC}"
echo -e "${CYAN}  ╚═══╝  ╚══════╝╚═════╝  ╚═════╝ ${NC}"
echo -e "${CYAN}                                  ${NC}"

# Additional Intro Text
echo -e "${YELLOW}This script will perform operations securely and efficiently to backup cscart locally automatically.${NC}"
echo -e "${RED}Starting the backup process...${NC}\n"

# Check if LOCAL_DIR is accessible
if [ ! -d "$LOCAL_DIR" ] || [ ! -w "$LOCAL_DIR" ]; then
    echo -e "${RED}Error: Local directory $LOCAL_DIR not accessible. Exiting the program.${NC}"
    exit 1
fi

# Php Backup Part
ssh -i $REMOTE_CERT $REMOTE_USER@$REMOTE_HOST "docker exec eshtery bash -c 'php /var/www/html/cscart/admin.php -p --dispatch=datakeeper.backup --backup_database=Y --backup_files=Y --dbdump_schema=Y --dbdump_data=Y --dbdump_tables=all --extra_folders[0]=var/files --extra_folders[1]=var/attachments --extra_folders[2]=var/langs --extra_folders[3]=images'"

# List and remove old backups if more than 5 exist
ssh -i $REMOTE_CERT $REMOTE_USER@$REMOTE_HOST "
    echo -e  '${CYAN}Listing all backups sorted by date in $REMOTE_DIR: ${CYAN}'
    ls -lt $REMOTE_DIR || echo 'Failed to list backups. Check path and permissions.'
    
    backup_count=\$(ls -1 $REMOTE_DIR | wc -l)
    echo  \" ⦿ Total backups found: \$backup_count\"

    if [ \$backup_count -gt 5 ]; then
        echo 'More than 5 backups found. Removing the oldest backups...'
        ls -t $REMOTE_DIR | tail -n +6 | xargs -I {} rm -f $REMOTE_DIR/{}
    else
        echo 'Total backups found are not more than 5. Nothing to remove.'
    fi
"

# Command to find the latest file in the remote directory
LATEST_FILE_CMD="ls -t $REMOTE_DIR | head -1"

# Execute the command on the remote server to get the latest file name
LATEST_FILE=$(ssh -i $REMOTE_CERT $REMOTE_USER@$REMOTE_HOST "$LATEST_FILE_CMD")

# Check if the latest file was found
if [ -z "$LATEST_FILE" ]; then
    echo "No file found in the remote directory."
    exit 1
fi

# Full path of the remote file
REMOTE_FILE_PATH="$REMOTE_DIR/$LATEST_FILE"

# Calculate checksum on remote file
REMOTE_CHECKSUM=$(ssh -i $REMOTE_CERT $REMOTE_USER@$REMOTE_HOST "md5sum $REMOTE_FILE_PATH | cut -d ' ' -f 1")

# Use SCP to copy the latest file to the local directory
scp -i $REMOTE_CERT "$REMOTE_USER@$REMOTE_HOST:$REMOTE_FILE_PATH" "$LOCAL_DIR"

# Calculate checksum on local file
LOCAL_FILE_PATH="$LOCAL_DIR/$LATEST_FILE"
LOCAL_CHECKSUM=$(md5sum "$LOCAL_FILE_PATH" | cut -d ' ' -f 1)
echo -e "${PURPLE}Local checksum: $LOCAL_CHECKSUM${NC}"
echo -e "${PURPLE}Server checksum: $REMOTE_CHECKSUM${NC}"
# Compare checksums
if [ "$REMOTE_CHECKSUM" != "$LOCAL_CHECKSUM" ]; then
    echo -e "${RED}Error: Checksum mismatch. File may be corrupted. Deleting downloaded file.${NC}"
    rm -f "$LOCAL_FILE_PATH"
    exit 1
else
    echo -e "${GREEN} ✓ Checksum verified. File downloaded successfully.${NC}"
fi

