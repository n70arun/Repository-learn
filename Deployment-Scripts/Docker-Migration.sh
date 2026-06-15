#!/bin/bash
# ===========================================================================
# Paperless Stack Migration Script (Production-safe)
# Source: Dell Inspiron
# Target: HP EliteDesk
# Author: Arun
# ===========================================================================

# -------------------------
# CONFIGURATION
# -------------------------

# Target HP EliteDesk SSH details
TARGET_HOST="hp-elite.local"   # or IP address
TARGET_USER="youruser"
TARGET_BASE_PATH="/srv/paperless"  # Base directory on target

# Docker Compose location on source
SOURCE_COMPOSE="/home/user/paperless/docker-compose.yml"
SOURCE_BASE_PATH="/home/user/paperless"

# List of Paperless volumes (if using Docker volumes)
VOLUMES=("paperless-data" "paperless-db")

# Host-mounted directories (if applicable)
HOST_DIRS=("/home/user/paperless/data" "/home/user/paperless/media")

# Temporary backup location
BACKUP_DIR="/tmp/paperless_migration_backup"
mkdir -p "$BACKUP_DIR"

# -------------------------
# PRE-MIGRATION VALIDATION
# -------------------------
echo "Step 1: Pre-migration validation"

# Check Docker and docker-compose availability
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker or Docker Compose not found. Aborting."
    exit 1
fi

# Check running containers
echo "Checking running Paperless containers..."
docker-compose -f "$SOURCE_COMPOSE" ps

read -p "Do you want to stop the Paperless stack now? (yes/no): " STOP_CONFIRM
if [[ "$STOP_CONFIRM" == "yes" ]]; then
    docker-compose -f "$SOURCE_COMPOSE" down
    echo "Paperless stack stopped."
else
    echo "Aborting migration. Please stop containers manually."
    exit 1
fi

# -------------------------
# BACKUP VOLUMES
# -------------------------
echo "Step 2: Backing up Docker volumes..."
for VOL in "${VOLUMES[@]}"; do
    echo "Backing up volume: $VOL"
    docker run --rm -v "${VOL}:/volume" -v "$BACKUP_DIR:/backup" alpine \
        tar czf "/backup/${VOL}.tar.gz" -C /volume .
done

# -------------------------
# BACKUP HOST DIRECTORIES
# -------------------------
echo "Step 3: Backing up host-mounted directories..."
for DIR in "${HOST_DIRS[@]}"; do
    BASENAME=$(basename "$DIR")
    echo "Backing up directory: $DIR"
    rsync -avh --progress "$DIR/" "$BACKUP_DIR/$BASENAME/"
done

# -------------------------
# TRANSFER BACKUP TO TARGET
# -------------------------
echo "Step 4: Transferring backup to HP EliteDesk..."
ssh "${TARGET_USER}@${TARGET_HOST}" "mkdir -p $TARGET_BASE_PATH/backup"
rsync -avh --progress "$BACKUP_DIR/" "${TARGET_USER}@${TARGET_HOST}:$TARGET_BASE_PATH/backup/"

# -------------------------
# RESTORE ON TARGET
# -------------------------
echo "Step 5: Restoring volumes on HP EliteDesk..."
ssh "${TARGET_USER}@${TARGET_HOST}" bash -c "'
# Restore Docker volumes
for VOL in ${VOLUMES[@]}; do
    echo \"Restoring volume: \$VOL\"
    docker volume create \$VOL
    docker run --rm -v \$VOL:/volume -v $TARGET_BASE_PATH/backup:/backup alpine \
        sh -c \"cd /volume && tar xzf /backup/\$VOL.tar.gz\"
done

# Restore host-mounted directories
for DIR in ${HOST_DIRS[@]}; do
    BASENAME=\$(basename \$DIR)
    mkdir -p \$DIR
    rsync -avh $TARGET_BASE_PATH/backup/\$BASENAME/ \$DIR/
done
'"

# -------------------------
# POST-MIGRATION VALIDATION
# -------------------------
echo "Step 6: Post-migration validation"

echo "On HP EliteDesk, list restored volumes:"
ssh "${TARGET_USER}@${TARGET_HOST}" "docker volume ls"

echo "Check host directories:"
for DIR in "${HOST_DIRS[@]}"; do
    ssh "${TARGET_USER}@${TARGET_HOST}" "ls -lh $DIR | head -n 5"
done

read -p "Do you want to start the Paperless stack on HP now? (yes/no): " START_CONFIRM
if [[ "$START_CONFIRM" == "yes" ]]; then
    ssh "${TARGET_USER}@${TARGET_HOST}" "cd $TARGET_BASE_PATH && docker-compose up -d"
    echo "Paperless stack started on HP EliteDesk."
fi

# -------------------------
# CLEANUP
# -------------------------
echo "Step 7: Optional cleanup"
read -p "Do you want to delete the local backup on the source Inspiron? (yes/no): " CLEANUP_CONFIRM
if [[ "$CLEANUP_CONFIRM" == "yes" ]]; then
    rm -rf "$BACKUP_DIR"
    echo "Local backup removed."
else
    echo "Local backup retained at $BACKUP_DIR"
fi

echo "Migration script completed successfully!"
