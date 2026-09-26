#!/usr/bin/env bash
# 612 RP — Phase 1 verification. Read-only; prints PASS/FAIL per check.
# Usage: sudo ./verify.sh
set -uo pipefail

pass=0; fail=0
check() {
  local name="$1"; shift
  if "$@" &>/dev/null; then echo "PASS  $name"; ((pass++)); else echo "FAIL  $name"; ((fail++)); fi
}

check "Ubuntu 22.04"                 grep -q 'VERSION_ID="22.04"' /etc/os-release
check "Hostname is 612rp-prod"       test "$(hostname)" = 612rp-prod
check "Timezone America/Chicago"     bash -c 'timedatectl show -p Timezone --value | grep -qx America/Chicago'
check "NTP synchronized"             bash -c 'timedatectl show -p NTPSynchronized --value | grep -qx yes'
check "fivem service user exists"    id fivem
check "fivem user has no sudo"       bash -c '! id -nG fivem | grep -qw sudo'
check "UFW active"                   bash -c 'ufw status | grep -q "Status: active"'
check "UFW allows 30120/tcp"         bash -c 'ufw status | grep -q "30120/tcp"'
check "UFW allows 30120/udp"         bash -c 'ufw status | grep -q "30120/udp"'
check "UFW allows 40120/tcp"         bash -c 'ufw status | grep -q "40120/tcp"'
check "UFW does NOT open 3306"       bash -c '! ufw status | grep -q 3306'
check "fail2ban sshd jail running"   fail2ban-client status sshd
check "Unattended upgrades enabled"  grep -q 'Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades
check "Swap active"                  bash -c 'swapon --show | grep -q .'
check "Swappiness = 10"              bash -c 'test "$(sysctl -n vm.swappiness)" = 10'
check "UDP rmem_max tuned"           bash -c 'test "$(sysctl -n net.core.rmem_max)" = 16777216'
check "SSH root login disabled"      bash -c 'sshd -T | grep -qx "permitrootlogin no"'
check "SSH password auth disabled"   bash -c 'sshd -T | grep -qx "passwordauthentication no"'

echo
echo "Result: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
