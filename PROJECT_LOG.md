# 612 RP — Project Log

Running record of everything installed, versions, config changes, and open issues.
Updated at the end of every step.

## Project constants

| Item | Value |
|---|---|
| Server name | **612 RP** (Minneapolis area code 612) |
| Style | Semi-serious RP, public at launch, optional allowlist for police / EMS / gangs |
| Target | 64+ concurrent US players within 6 months |
| Framework | QBox (qbx_core) + ox_lib, ox_inventory, ox_target, oxmysql |
| Host | Ubuntu 22.04 VPS, 6 vCPU / 16 GB / NVMe, US-Central (Chicago) |
| Upgrade trigger | >64 players → 8 vCPU / 32 GB |
| Panel / DB | txAdmin / MariaDB |
| Monetization | Tebex only, compliant with Cfx.re PLA + Creator Platform terms |
| Budget | $300 one-time scripts, $60/month hosting cap |
| Perf target | < 0.05 ms idle per resource (resmon) |

## Build phases

| Phase | Name | Status |
|---|---|---|
| 0 | Planning & project log | ✅ Done |
| 1 | VPS hardening & base OS setup | 🟡 Scripts ready — awaiting run on VPS |
| 2 | MariaDB + FXServer + txAdmin install | ⏳ Next |
| 3 | QBox core stack (recipe deploy) | ⬜ |
| 4 | Branding: server.cfg identity, loading screen, Discord | ⬜ |
| 5 | Core gameplay: jobs, economy, housing, vehicles, phone | ⬜ |
| 6 | Whitelisted departments: police, EMS, gangs + Discord allowlist | ⬜ |
| 7 | Admin, anticheat, logging, backups | ⬜ |
| 8 | Performance pass & load testing | ⬜ |
| 9 | Tebex store (compliant cosmetics/QoL only) | ⬜ |
| 10 | Soft launch → public launch → scale to 64+ | ⬜ |

## Installed resources

| Resource | Version | Source | License | Paid? | Idle ms | Notes |
|---|---|---|---|---|---|---|
| _none yet_ | | | | | | |

## Config changes

| Date | File | Change | Reason |
|---|---|---|---|
| 2026-09-26 | `/etc/ssh/sshd_config.d/00-612rp-hardening.conf` | Key-only SSH, no root login, `AllowUsers deploy` | Phase 1 hardening |
| 2026-09-26 | UFW | Default deny inbound; allow 22 (limit), 30120 tcp/udp, 40120 tcp | Only game + panel + SSH exposed; 3306 stays closed |
| 2026-09-26 | `/etc/fail2ban/jail.d/612rp-sshd.local` | sshd jail: 5 tries / 10 min → 1 h ban | Stop brute-force attempts |
| 2026-09-26 | `/etc/apt/apt.conf.d/20auto-upgrades`, `52-612rp-unattended` | Daily security updates, no auto-reboot | Patch the OS without surprise restarts |
| 2026-09-26 | `/etc/sysctl.d/99-612rp.conf` | UDP/TCP buffers 16 MB, swappiness 10 | Game network traffic |
| 2026-09-26 | `/swapfile` | 4 GB swap | OOM safety net |
| 2026-09-26 | hostname / timezone | `612rp-prod`, `America/Chicago` | txAdmin restart schedules in local time |

_Planned changes. Nothing is applied until you run `scripts/phase1/` on the VPS._

## Budget tracker

| Item | Type | Cost | Running total |
|---|---|---|---|
| Paid scripts | one-time | $0 | $0 / $300 |
| VPS | monthly | TBD ($40–60) | TBD / $60 |

## Open issues

1. **Slot limit above 48.** FiveM servers above 48 slots require a Cfx.re Element Club subscription tier. That cost must fit alongside the upgraded 8-core/32 GB VPS under the $60/month cap, or the cap needs revisiting before we pass 48. Verify current tier pricing before Phase 10.
2. **Cfx.re license key.** Needed from portal.cfx.re before Phase 2 (tie it to the VPS IP).
3. **Discord server + bot.** Needed before Phase 6 (allowlist roles) and Phase 7 (logging webhooks).
4. **VPS provider.** Not chosen yet. Criteria are in `docs/phase1-vps-setup.md` §0: high single-thread CPU, DDoS protection that covers UDP, Chicago, ≤$60/month.
5. **txAdmin port 40120 is open to the internet** unless `TXADMIN_ALLOW_IP` is set. Acceptable with a strong txAdmin password and 2FA (set up in Phase 2); consider restricting it to your IP or putting it behind a reverse proxy later.
6. **Phase 1 not yet run on a real VPS.** The scripts pass a syntax check only. Confirm with `verify.sh` (18/18) after running.

## Changelog

- **2026-09-26 — Step 0:** Project kickoff. Created PROJECT_LOG.md with constants, phase plan, budget tracker, and open issues. Nothing installed.
- **2026-09-26 — Phase 1:** Added `scripts/phase1/01-harden-base.sh` (stage A: packages, users `deploy` + `fivem`, UFW, fail2ban, unattended-upgrades, swap, sysctl, hostname/timezone), `02-lock-ssh.sh` (stage B: key-only SSH; aborts if no authorized key, validates with `sshd -t`), `verify.sh` (18 read-only checks), and the guide `docs/phase1-vps-setup.md`.
