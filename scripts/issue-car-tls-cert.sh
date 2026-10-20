#!/bin/sh
# Issue/renew HTTP-01 cert for car portal hosts (run on VPS as root).
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEBROOT=/var/www/html
ACME_CONF=/etc/nginx/sites-available/car-ics-vortex-acme.conf
FULL_CONF=/etc/nginx/sites-available/car-ics-vortex.conf

mkdir -p "$WEBROOT/.well-known/acme-challenge"

restore_nginx() {
  sh "$REPO_ROOT/scripts/sync-host-nginx.sh" >/dev/null 2>&1 || true
}
trap restore_nginx EXIT

cp "$REPO_ROOT/deploy/host/car-ics-vortex-acme.conf" "$ACME_CONF"
ln -sf "$ACME_CONF" /etc/nginx/sites-enabled/car-ics-vortex-acme.conf
# Avoid broken HTTPS vhost until the dedicated cert exists.
rm -f /etc/nginx/sites-enabled/car-ics-vortex.conf
nginx -t
systemctl reload nginx

issue() {
  certbot certonly --webroot -w "$WEBROOT" \
    --cert-name car.ics-vortex.com \
    -d car.ics-vortex.com \
    -d api.car.ics-vortex.com \
    -d cms.car.ics-vortex.com \
    --non-interactive --agree-tos --register-unsafely-without-email \
    "$@"
}

if ! issue; then
  echo "webroot failed; trying nginx plugin (TLS-ALPN) ..."
  certbot certonly --nginx \
    --cert-name car.ics-vortex.com \
    -d car.ics-vortex.com \
    -d api.car.ics-vortex.com \
    -d cms.car.ics-vortex.com \
    --non-interactive --agree-tos --register-unsafely-without-email \
    "$@"
fi

cp "$REPO_ROOT/deploy/host/car-ics-vortex.conf" "$FULL_CONF"
ln -sf "$FULL_CONF" /etc/nginx/sites-enabled/car-ics-vortex.conf
rm -f /etc/nginx/sites-enabled/car-ics-vortex-acme.conf
nginx -t
systemctl reload nginx

HOOK=/etc/letsencrypt/renewal-hooks/deploy/car-portal-nginx.sh
mkdir -p "$(dirname "$HOOK")"
cat > "$HOOK" << 'EOF'
#!/bin/sh
nginx -t && systemctl reload nginx
EOF
chmod +x "$HOOK"

trap - EXIT
echo "TLS OK: /etc/letsencrypt/live/car.ics-vortex.com/"
