#!/bin/sh
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${REPO_ROOT}/deploy/host/car-ics-vortex.conf"
DEST="/etc/nginx/sites-available/car-ics-vortex.conf"
TMP="$(mktemp)"

cp "$SRC" "$TMP"

if [ ! -f /etc/letsencrypt/live/api-cms.car.ics-vortex.com/fullchain.pem ]; then
  echo "Note: api/cms TLS cert missing; api.car and cms.car HTTPS may fail until issued" >&2
fi

if [ ! -f /etc/letsencrypt/live/car.ics-vortex.com/fullchain.pem ]; then
  echo "Note: car.ics-vortex.com cert missing; using ics-vortex.com cert temporarily" >&2
  sed -i 's|/etc/letsencrypt/live/car.ics-vortex.com/|/etc/letsencrypt/live/ics-vortex.com/|g' "$TMP"
fi

cp "$TMP" "$DEST"
rm -f "$TMP"
ln -sf "$DEST" /etc/nginx/sites-enabled/car-ics-vortex.conf
rm -f /etc/nginx/sites-enabled/car-ics-vortex-acme.conf
nginx -t
systemctl reload nginx
echo "Host nginx reloaded: car.ics-vortex.com → 127.0.0.1:8081"
