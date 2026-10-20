#!/bin/sh
# Run on the VPS as root (normal OS or rescue with ROOT=/mnt).
set -eu

ROOT="${ROOT:-/}"

install_key() {
  mkdir -p "${ROOT}/root/.ssh"
  chmod 700 "${ROOT}/root/.ssh"
  grep -qF 'AAAAICTGmpqCEPHdLpavL8msTTXaMkcZ/E9J4b6ZVw6seAPj' "${ROOT}/root/.ssh/authorized_keys" 2>/dev/null \
    || cat >> "${ROOT}/root/.ssh/authorized_keys" << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICTGmpqCEPHdLpavL8msTTXaMkcZ/E9J4b6ZVw6seAPj vasyl.komarychyn@gmail.com
EOF
  chmod 600 "${ROOT}/root/.ssh/authorized_keys"
}

prepare_dirs() {
  mkdir -p /opt/car-portal
  chmod 755 /opt/car-portal
}

enable_ssh_pubkey() {
  cfg="${ROOT}/etc/ssh/sshd_config"
  [ -f "$cfg" ] || return 0
  sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$cfg"
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$cfg"
}

install_key
if [ "$ROOT" = "/" ]; then
  prepare_dirs
  enable_ssh_pubkey
  systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
fi

echo "OK: root SSH key installed under ${ROOT}/root/.ssh/authorized_keys"
[ "$ROOT" = "/" ] && echo "OK: /opt/car-portal ready"
