#!/usr/bin/env bash
# 612 RP — Phase 1, stage A: base OS hardening for Ubuntu 22.04.
# Safe to re-run. Does NOT disable SSH password login (that is stage B).
#
# Usage (as root):
#   ADMIN_USER=deploy ADMIN_PUBKEY="ssh-ed25519 AAAA... you@pc" ./01-harden-base.sh
# Optional:
#   TXADMIN_ALLOW_IP=203.0.113.10   restrict txAdmin (40120) to your home IP
#   SWAP_SIZE=4G                    swap file size (default 4G)
set -euo pipefail

ADMIN_USER="${ADMIN_USER:-deploy}"
ADMIN_PUBKEY="${ADMIN_PUBKEY:-}"
SERVICE_USER="fivem"
SERVER_HOSTNAME="612rp-prod"
TIMEZONE="America/Chicago"
SWAP_SIZE="${SWAP_SIZE:-4G}"
TXADMIN_ALLOW_IP="${TXADMIN_ALLOW_IP:-}"

log() { printf '\n==> %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "Run as root."; exit 1; }
grep -q 'VERSION_ID="22.04"' /etc/os-release || { echo "Expected Ubuntu 22.04."; exit 1; }

log "Updating packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y ufw fail2ban unattended-upgrades apt-listchanges \
  curl wget git xz-utils ca-certificates jq htop tmux rsync

log "Hostname and timezone"
hostnamectl set-hostname "$SERVER_HOSTNAME"
grep -q "$SERVER_HOSTNAME" /etc/hosts || echo "127.0.1.1 $SERVER_HOSTNAME" >> /etc/hosts
timedatectl set-timezone "$TIMEZONE"
timedatectl set-ntp true

log "Admin user: $ADMIN_USER (sudo)"
if ! id "$ADMIN_USER" &>/dev/null; then
  adduser --disabled-password --gecos "" "$ADMIN_USER"
  echo "Set a sudo password for $ADMIN_USER:"
  passwd "$ADMIN_USER"
fi
usermod -aG sudo "$ADMIN_USER"
install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
AUTH_KEYS="/home/$ADMIN_USER/.ssh/authorized_keys"
touch "$AUTH_KEYS"
if [[ -n "$ADMIN_PUBKEY" ]] && ! grep -qF "$ADMIN_PUBKEY" "$AUTH_KEYS"; then
  echo "$ADMIN_PUBKEY" >> "$AUTH_KEYS"
fi
chown "$ADMIN_USER:$ADMIN_USER" "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"

log "Service user: $SERVICE_USER (no sudo, no SSH login) — runs FXServer + txAdmin"
if ! id "$SERVICE_USER" &>/dev/null; then
  adduser --system --group --home "/home/$SERVICE_USER" --shell /bin/bash "$SERVICE_USER"
fi
install -d -m 750 -o "$SERVICE_USER" -g "$SERVICE_USER" \
  "/home/$SERVICE_USER/fxserver" "/home/$SERVICE_USER/txData" "/home/$SERVICE_USER/backups"

log "Firewall (UFW)"
ufw default deny incoming
ufw default allow outgoing
ufw limit OpenSSH comment 'SSH (rate limited)'
ufw allow 30120/tcp comment 'FiveM game TCP'
ufw allow 30120/udp comment 'FiveM game UDP'
if [[ -n "$TXADMIN_ALLOW_IP" ]]; then
  ufw allow from "$TXADMIN_ALLOW_IP" to any port 40120 proto tcp comment 'txAdmin (admin IP only)'
else
  ufw allow 40120/tcp comment 'txAdmin web panel'
fi
# MariaDB (3306) is intentionally NOT opened; it binds to localhost in Phase 2.
ufw --force enable

log "fail2ban (sshd jail)"
cat > /etc/fail2ban/jail.d/612rp-sshd.local <<'EOF'
[sshd]
enabled  = true
backend  = systemd
maxretry = 5
findtime = 10m
bantime  = 1h
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

log "Unattended security upgrades (no automatic reboots)"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
cat > /etc/apt/apt.conf.d/52-612rp-unattended <<'EOF'
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

log "Swap ($SWAP_SIZE)"
if ! swapon --show | grep -q .; then
  fallocate -l "$SWAP_SIZE" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
else
  echo "Swap already present, skipping."
fi

log "Kernel tuning (network buffers, swappiness)"
cat > /etc/sysctl.d/99-612rp.conf <<'EOF'
# 612 RP — game server tuning
vm.swappiness = 10
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.core.netdev_max_backlog = 5000
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_syncookies = 1
EOF
sysctl --system >/dev/null

log "Stage A complete"
cat <<EOF
Next:
  1. From your PC, open a NEW terminal and confirm:  ssh $ADMIN_USER@<server-ip>
  2. Confirm sudo works:                              sudo whoami   (prints root)
  3. Only then run stage B:                           sudo ./02-lock-ssh.sh
Keep this root session open until stage B is verified.
EOF
