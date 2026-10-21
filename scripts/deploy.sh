#!/bin/sh
# Build prod images locally, load on VPS, sync tree, compose up (keeps server .env).
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SSH_HOST="${DEPLOY_SSH_HOST:-contabo}"
REMOTE_DIR="${DEPLOY_REMOTE_DIR:-/opt/car-portal}"
TARGET="${1:-all}"
SSH_OPTS="${SSH_OPTS:--o BatchMode=yes -o ConnectTimeout=30}"
# shellcheck source=scripts/ssh-contabo.sh
. "$(dirname "$0")/ssh-contabo.sh"
ssh_r() { ssh_contabo "$@"; }

cd "$ROOT"

sync_tree() {
  echo "=== sync → $SSH_HOST:$REMOTE_DIR (keep .env) ==="
  ssh_r "mkdir -p '$REMOTE_DIR'"
  tar -C "$ROOT" \
    --exclude='.env' \
    --exclude='.git' \
    --exclude='mobile' \
    --exclude='frontend/node_modules' \
    --exclude='backend/node_modules' \
    --exclude='cms/vendor' \
    --exclude='nginx/certs/*.pem' \
    -czf - . \
    | ssh_r "tar -C '$REMOTE_DIR' -xzf -"
}

load_image() {
  img="$1"
  service="$2"
  echo "=== build $service → $img ==="
  docker compose -f docker-compose.prod.yml build "$service"
  echo "=== load $img on $SSH_HOST ==="
  docker save "$img" | ssh_r "docker load"
}

remote_up() {
  ssh_r "set -e
cd '$REMOTE_DIR'
if [ ! -f .env ]; then
  cp .env.prod.example .env
  pw=\$(openssl rand -hex 24)
  sed -i \"s/change-me/\$pw/g\" .env
  sed -i \"s|postgresql://car_portal:change-me@|postgresql://car_portal:\$pw@|\" .env 2>/dev/null || true
fi
docker compose --env-file .env -f docker-compose.prod.yml up -d --no-build --remove-orphans
"
}

case "$TARGET" in
  infra)
    sync_tree
    ssh_r "set -e
cd '$REMOTE_DIR'
[ -f .env ] || cp .env.prod.example .env
# Data + messaging only. nginx is updated with --no-deps so compose does not pull
# frontend/backend/cms via nginx depends_on (see docker-compose.prod.yml).
docker compose --env-file .env -f docker-compose.prod.yml up -d --no-build postgres redis rabbitmq
docker compose --env-file .env -f docker-compose.prod.yml up -d --no-build --no-deps nginx
$REMOTE_DIR/scripts/sync-host-nginx.sh
"
    ;;
  frontend)
    load_image car-portal-frontend:prod frontend
    sync_tree
    remote_up
    ;;
  backend)
    load_image car-portal-backend:prod backend
    sync_tree
    remote_up
    ;;
  cms)
    load_image car-portal-cms:prod cms
    sync_tree
    remote_up
    ssh_r "cd '$REMOTE_DIR' && sh scripts/run-cms-migrations.sh"
    ;;
  all)
    load_image car-portal-frontend:prod frontend
    load_image car-portal-backend:prod backend
    load_image car-portal-cms:prod cms
    sync_tree
    remote_up
    ssh_r "cd '$REMOTE_DIR' && sh scripts/run-cms-migrations.sh && sh scripts/sync-host-nginx.sh"
    ;;
  *)
    echo "usage: $0 [infra|frontend|backend|cms|all]" >&2
    exit 1
    ;;
esac

echo "=== done ($TARGET) ==="
