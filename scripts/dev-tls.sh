#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="${ROOT}/nginx/certs"
mkdir -p "${CERT_DIR}"

DOMAINS=(
  carmain.localhost.com
  api.carmain.localhost.com
  cms.carmain.localhost.com
  rabbitmq.carmain.localhost.com
  pgadmin.localhost.com
  carmain.local
  api.carmain.local
  cms.carmain.local
  rabbitmq.carmain.local
  pgadmin.carmain.local
)

CERT_FILE="${CERT_DIR}/dev-fullchain.pem"
KEY_FILE="${CERT_DIR}/dev-key.pem"

if [[ -x "${HOME}/.local/bin/mkcert" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

if command -v mkcert >/dev/null 2>&1; then
  echo "Using mkcert (browser-trusted local certificates)."
  mkcert -install >/dev/null 2>&1 || true
  mkcert -cert-file "${CERT_FILE}" -key-file "${KEY_FILE}" "${DOMAINS[@]}"
else
  echo "mkcert not found; generating a self-signed certificate with openssl."
  echo "Install mkcert for certificates Chrome/Firefox trust without warnings:"
  echo "  https://github.com/FiloSottile/mkcert"
  SAN=""
  for domain in "${DOMAINS[@]}"; do
    SAN="${SAN}DNS:${domain},"
  done
  SAN="${SAN%,}"

  openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/CN=carmain.localhost.com" \
    -addext "subjectAltName=${SAN}"
fi

chmod 644 "${CERT_FILE}"
chmod 600 "${KEY_FILE}"

echo ""
echo "Certificates written to:"
echo "  ${CERT_FILE}"
echo "  ${KEY_FILE}"
echo ""
echo "Next steps:"
echo "  1. Set in .env:"
echo "       APP_BASE_URL=https://carmain.localhost.com"
echo "       API_BASE_URL=https://api.carmain.localhost.com"
echo "       CMS_BASE_URL=https://cms.carmain.localhost.com"
echo "       COOKIE_SECURE=true"
echo "  2. Add https://carmain.localhost.com to Google OAuth Authorized JavaScript origins."
echo "  3. docker compose up -d --force-recreate nginx backend frontend"
