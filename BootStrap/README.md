# OSS bench internals

**Users run one file:** [`../Merit-Hub/Merit-Hub.ps1`](../Merit-Hub/Merit-Hub.ps1) saved as `C:\Tools\Merit-Hub.ps1`.

This folder is **not** a second product. Hub **2** (alias **J**) dotsources [`_oss.ps1`](_oss.ps1) in the same window.

**Do not** copy this folder to `%MYMERITAPP%\BootStrap\` or add `%MYMERITAPP%\MERIT_BootStrap.cmd`. Hub deletes that leftover if it reappears.

## Hub map (the only menu)

```
1 Setup laptop --> 2 Install OSS --+--> 3 Try it --> OC (OSS in the Cloud)
                                   +--> 4 Vault (still local) --> VC (Venture Capable)
                                   +--> 5 Join MERIT
                                   +--> Stop
```

Keys: **1 2 3 OC 4 VC 5 0**. Aliases **J**=2, **V**=4. Old D/G live inside **2**.

## Status file

Laptop status is **`%MYMERITAPP%\oss-bench.json`** (`benchFolder`, `skillsFolder`, `demoFolder`, `skillsPin`, `lastValidateOk`, `ocConsumerId`, …).

## Pathway

Hub **1** then **2** → **3** Try it locally → **OC** for a live merit-prod app (no here.now account on the laptop). **4** clones the vault locally. **VC** is operator/tenant grade vs freeware OC.
