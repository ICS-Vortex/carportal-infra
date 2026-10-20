#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
docker compose --env-file .env -f docker-compose.prod.yml exec -T cms \
  php bin/console doctrine:migrations:migrate --no-interaction
