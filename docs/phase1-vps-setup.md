# 612 RP — Phase 1: VPS setup & hardening

Target: Ubuntu 22.04, 6 vCPU / 16 GB / NVMe, Chicago.
Result: patched OS, sudo admin user with SSH keys only, locked-down firewall,
fail2ban, auto security updates, swap, network tuning, and a `fivem` service user
ready for Phase 2.

## 0. Pick the VPS (if not done yet)

What matters for FiveM, in order:
1. **Single-thread CPU speed.** FXServer's main thread is the bottleneck. Choose "high-frequency" or dedicated-CPU plans (Ryzen or high-clock Xeon), not shared burst CPUs.
2. **DDoS protection that handles game UDP.** RP servers get attacked. Ask whether their filtering covers UDP on 30120.
3. **Chicago location.** Gives about 20–50 ms to most of the continental US.
4. **Price within $60/month** for 6 cores / 16 GB / NVMe. Leave room for the Element Club tier later (see open issue #1).

Before you pay, check current prices and whether they sell Chicago game-server plans with DDoS filtering.

## 1. Create an SSH key on your PC (skip if you already have one)

Windows PowerShell, macOS, or Linux:
```bash
ssh-keygen -t ed25519 -C "612rp-admin"
# Windows: type $env:USERPROFILE\.ssh\id_ed25519.pub
# macOS/Linux:
cat ~/.ssh/id_ed25519.pub
```
Copy the single line that starts with `ssh-ed25519`.

## 2. Copy the scripts to the server

```bash
# From your PC, inside this repo:
scp -r scripts/phase1 root@<SERVER_IP>:/root/phase1
ssh root@<SERVER_IP>
```

## 3. Stage A: base hardening (as root)

```bash
cd /root/phase1
ADMIN_USER=deploy \
ADMIN_PUBKEY="ssh-ed25519 AAAA...your key... 612rp-admin" \
TXADMIN_ALLOW_IP=<your home IP, optional> \
./01-harden-base.sh
```
The script asks you to set a sudo password for `deploy`.

**Keep this root session open.** From a **new** terminal on your PC:
```bash
ssh deploy@<SERVER_IP>
sudo whoami        # must print: root
```
Continue only if both commands work.

## 4. Stage B: SSH lockdown

In the `deploy` session:
```bash
sudo cp -r /root/phase1 ~/phase1 && sudo chown -R deploy: ~/phase1
cd ~/phase1
sudo ADMIN_USER=deploy ./02-lock-ssh.sh
```
From a **third** terminal, check that `ssh deploy@<SERVER_IP>` still works and that `ssh root@<SERVER_IP>` is refused. Then close the root session.

If you get locked out, use your provider's web console (VNC/KVM) to roll back:
```bash
rm /etc/ssh/sshd_config.d/00-612rp-hardening.conf && systemctl reload ssh
```

## 5. Verify

```bash
sudo ~/phase1/verify.sh      # expect: 18 passed, 0 failed
```

## What changed on the server

| Path | Purpose |
|---|---|
| `/etc/hostname`, `/etc/hosts` | Hostname `612rp-prod` |
| timedatectl | Timezone `America/Chicago`, NTP on |
| `/home/deploy/.ssh/authorized_keys` | Your admin key |
| `/home/fivem/{fxserver,txData,backups}` | Folders for Phase 2 (owner `fivem`, mode 750) |
| UFW rules | Deny all incoming except 22 (rate-limited), 30120 tcp+udp, 40120 tcp |
| `/etc/fail2ban/jail.d/612rp-sshd.local` | 5 failed logins in 10 min = 1 h ban |
| `/etc/apt/apt.conf.d/20auto-upgrades`, `52-612rp-unattended` | Daily security updates, **no auto-reboot** |
| `/swapfile` + `/etc/fstab` | 4 GB swap |
| `/etc/sysctl.d/99-612rp.conf` | Larger UDP/TCP buffers, swappiness 10 |
| `/etc/ssh/sshd_config.d/00-612rp-hardening.conf` | Key-only login, no root, AllowUsers deploy |

## Test checklist

- [ ] `ssh deploy@<IP>` works with your key and no password prompt
- [ ] `ssh root@<IP>` is refused
- [ ] Password login is refused: `ssh -o PubkeyAuthentication=no deploy@<IP>` fails
- [ ] `sudo whoami` returns `root`
- [ ] `sudo ufw status verbose` shows only 22, 30120/tcp, 30120/udp, 40120/tcp
- [ ] `sudo fail2ban-client status sshd` shows the jail is active
- [ ] `free -h` shows about 4 GB of swap
- [ ] `timedatectl` shows America/Chicago and "System clock synchronized: yes"
- [ ] `sudo ~/phase1/verify.sh` reports 0 failed
- [ ] Reboot once (`sudo reboot`), then check that SSH, UFW, fail2ban and swap all come back
