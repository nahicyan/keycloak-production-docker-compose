#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.external-cert.yml"
ENV_FILE="$PROJECT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

: "${POSTGRES_USER:?POSTGRES_USER is not set}"

DEFAULT_DIR="$PROJECT_DIR/backup/postgres"
read -rp "Enter backup directory [$DEFAULT_DIR]: " BACKUP_DIR
BACKUP_DIR="${BACKUP_DIR:-$DEFAULT_DIR}"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "Directory not found: $BACKUP_DIR"
  exit 1
fi

mapfile -t FILES < <(find "$BACKUP_DIR" -maxdepth 1 -name "*.sql.gz" | sort -r)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "No .sql.gz backup files found in $BACKUP_DIR"
  exit 1
fi

echo ""
echo "Available backups:"
for i in "${!FILES[@]}"; do
  echo "  [$((i+1))] $(basename "${FILES[$i]}")"
done
echo ""

read -rp "Select backup (1-${#FILES[@]}): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt ${#FILES[@]} ]; then
  echo "Invalid selection."
  exit 1
fi

SELECTED="${FILES[$((SELECTION-1))]}"
echo ""
echo "Selected: $(basename "$SELECTED")"
read -rp "This will overwrite the current keycloak database. Continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "Restoring..."
gunzip -c "$SELECTED" | docker compose -f "$COMPOSE_FILE" exec -T keycloak_postgres psql -U "$POSTGRES_USER" keycloak
echo "Restore complete."
