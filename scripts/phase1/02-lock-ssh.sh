#!/usr/bin/env bash
# 612 RP — Phase 1, stage B: key-only SSH, no root login.
# Refuses to run unless the admin user already has an authorized key,
# and validates sshd config before reloading so you cannot lock yourself out.
#
# Usage (as root or via sudo):  ADMIN_USER=deploy ./02-lock-ssh.sh
set -euo pipefail

ADMIN_USER="${ADMIN_USER:-deploy}"
AUTH_KEYS="/home/$ADMIN_USER/.ssh/authorized_keys"
DROPIN="/etc/ssh/sshd_config.d/00-612rp-hardening.conf"

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }
id "$ADMIN_USER" &>/dev/null || { echo "User $ADMIN_USER does not exist. Run stage A first."; exit 1; }
if ! grep -qE '^(ssh-(ed25519|rsa)|ecdsa-sha2-)' "$AUTH_KEYS" 2>/dev/null; then
  echo "ABORT: $AUTH_KEYS has no public key. You would be locked out."
  exit 1
fi

# 00- prefix: sshd uses the first value it reads, so this beats cloud-init's 50-*.conf.
cat > "$DROPIN" <<EOF
# 612 RP SSH hardening
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowUsers $ADMIN_USER
EOF
chmod 644 "$DROPIN"

if ! sshd -t; then
  echo "sshd config test FAILED — removing drop-in, nothing changed."
  rm -f "$DROPIN"
  exit 1
fi
systemctl reload ssh

echo
echo "SSH locked down. Effective settings:"
sshd -T | grep -Ei '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|allowusers) '
echo
echo "Test from a NEW terminal before closing this one:  ssh $ADMIN_USER@<server-ip>"
echo "Rollback if needed:  sudo rm $DROPIN && sudo systemctl reload ssh"
