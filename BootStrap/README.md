# OSS bench (PHASE 2) — internal

**Users run one file:** [`../Merit-Hub/Merit-Hub.ps1`](../Merit-Hub/Merit-Hub.ps1) saved as `C:\Tools\Merit-Hub.ps1`.

This folder is **not** a second product. Hub **J** dotsources [`_oss.ps1`](_oss.ps1) and continues in the same window as **PHASE 2 of 3** (green). Laptop is PHASE 1 (cyan). Private-Vault is PHASE 3 (magenta, key **3**).

`MERIT_BootStrap.cmd` / `.ps1` are **legacy names** — they forward to `Merit-Hub.ps1 -OssPhase`.

## PHASE 2 keys (do not reuse laptop 1 / P / S)

| Key | Action |
|-----|--------|
| **D** | Seed / update `merit-demo` |
| **G** | Validate OSS (`closeout` + `smoke`) — freeware done |
| **U** | Status in plain English |
| **F** | Help (flow + vault teaser) |
| **3** | PHASE 3 Private-Vault (optional; OSS checklist first) |
| **0** | Back to PHASE 1 laptop menu |

After a step, type the next key at the pause (example: **D** then **G**).

## Status file

Laptop status is **`%MYMERITAPP%\oss-bench.json`** with human field names (`benchFolder`, `skillsFolder`, `demoFolder`, `skillsPin`, `lastValidateOk`, …).

Old `BootStrap/MERIT.json` (`testBench`, `publicSeeds`, `pinTag`, `ossValidationLastCheck`) is **migrated automatically** on first PHASE 2 save.

## Pathway

Hub **J** → PHASE 2 D → G → stop (or **3** if you have vault GitHub access). Flowchart: [docs/bootstrap_pathway.md](../docs/bootstrap_pathway.md).
