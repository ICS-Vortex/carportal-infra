#!/usr/bin/env bash
# Trust the mkcert development CA so https://carmain.localhost.com opens without warnings.
set -euo pipefail

if [[ -x "${HOME}/.local/bin/mkcert" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

if ! command -v mkcert >/dev/null 2>&1; then
  echo "mkcert not found. Run ./scripts/dev-tls.sh first."
  exit 1
fi

CAROOT="$(mkcert -CAROOT)"
CA_FILE="${CAROOT}/rootCA.pem"

if [[ ! -f "${CA_FILE}" ]]; then
  echo "Missing ${CA_FILE}. Run ./scripts/dev-tls.sh first."
  exit 1
fi

ensure_certutil() {
  if command -v certutil >/dev/null 2>&1; then
    return 0
  fi

  local cache="${HOME}/.cache/car-portal-certutil"
  if [[ -x "${cache}/certutil" ]]; then
    export PATH="${cache}:${PATH}"
    return 0
  fi

  echo "Downloading certutil (libnss3-tools) for user NSS trust..."
  mkdir -p "${cache}"
  local tmp
  tmp="$(mktemp -d)"
  (
    cd "${tmp}"
    apt-get download libnss3-tools >/dev/null
    dpkg-deb -x libnss3-tools*.deb .
    install -m 0755 usr/bin/certutil "${cache}/certutil"
  )
  rm -rf "${tmp}"
  export PATH="${cache}:${PATH}"
}

install_nss_trust() {
  ensure_certutil
  local db="sql:${HOME}/.pki/nssdb"
  mkdir -p "${HOME}/.pki/nssdb"
  certutil -d "${db}" -D -n "mkcert development CA" 2>/dev/null || true
  certutil -d "${db}" -A -t "C,," -n "mkcert development CA" -i "${CA_FILE}"
  echo "Trusted mkcert CA in ${HOME}/.pki/nssdb (Firefox / NSS)."
}

install_nss_trust

echo ""
echo "System trust (once per machine): sudo ${HOME}/.local/bin/mkcert -install"
echo ""
echo "If sudo prints 'already installed in the system trust store' and then"
echo "'no Firefox and/or Chrome security databases found' — ignore the second line."
echo "Under sudo, mkcert cannot open your user Chrome profile; OS trust is enough"
echo "for Google Chrome installed from .deb."
echo ""
echo "Then:"
echo "  1. Fully quit Chrome (all windows), reopen https://carmain.localhost.com"
echo "  2. If it still says Not secure: remove the old exception (lock icon →"
echo "     turn security warnings back on, or Site settings → Clear data)."
echo "  3. Or import manually: Manage certificates → Authorities →"
echo "     ${CAROOT}/rootCA.pem (copy also at nginx/certs/mkcert-rootCA.pem)"
