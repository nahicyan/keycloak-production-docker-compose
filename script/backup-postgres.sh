#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backup/postgres"
ENV_FILE="$PROJECT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

: "${POSTGRES_USER:?POSTGRES_USER is not set}"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/keycloak_${TIMESTAMP}.sql.gz"

echo "Starting PostgreSQL backup..."
docker exec keycloak_postgres pg_dump -U "$POSTGRES_USER" keycloak | gzip > "$BACKUP_FILE"

# Retain last 7 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete

echo "Backup saved: $BACKUP_FILE"
