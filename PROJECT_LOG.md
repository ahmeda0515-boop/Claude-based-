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
| 1 | VPS hardening & base OS setup | ⏳ Next |
| 2 | MariaDB + FXServer + txAdmin install | ⬜ |
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
| _none yet_ | | | |

## Budget tracker

| Item | Type | Cost | Running total |
|---|---|---|---|
| Paid scripts | one-time | $0 | $0 / $300 |
| VPS | monthly | TBD ($40–60) | TBD / $60 |

## Open issues

1. **Slot limit above 48.** FiveM servers above 48 slots require a Cfx.re Element Club subscription tier. That cost must fit alongside the upgraded 8-core/32 GB VPS under the $60/month cap, or the cap needs revisiting before we pass 48. Verify current tier pricing before Phase 10.
2. **Cfx.re license key.** Needed from portal.cfx.re before Phase 2 (tie it to the VPS IP).
3. **Discord server + bot.** Needed before Phase 6 (allowlist roles) and Phase 7 (logging webhooks).
4. **VPS provider.** Not chosen yet. Must be Chicago region, NVMe, and within budget.

## Changelog

- **2026-09-26 — Step 0:** Project kickoff. Created PROJECT_LOG.md with constants, phase plan, budget tracker, and open issues. Nothing installed.
