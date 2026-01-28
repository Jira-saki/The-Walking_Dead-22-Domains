# The Walking Dead: 22 Domains
## A Technical Case Study in Persistent Malware Remediation & Infrastructure Hardening

---

## Executive Summary

In mid-2025, a sophisticated botnet infection was identified across **22 WordPress and Static sites** on shared hosting infrastructure. The attack leveraged advanced persistence mechanisms—**Linux Immutable Attributes** (`chattr +i`) combined with self-healing **Guardian watchdog scripts**—to achieve kernel-level file locking that resisted standard deletion.

This project documents the complete incident lifecycle: **identification → reverse-engineering → 100% eradication → hardened zero-trust baseline**.

**Outcome:** Zero reinfection; all persistence mechanisms eliminated; infrastructure hardened against similar attacks.

---

## Incident Overview

| Aspect | Status | Technical Detail |
|--------|--------|------------------|
| **Severity** | Critical | Full filesystem lockout + lateral movement across 22 domains |
| **Infection Type** | Zombie Botnet | High-persistence, self-healing PHP malware with kernel-level locks |
| **Initial Entry** | Vulnerable Plugin | Outdated WordPress plugin/library on patient-zero domain |
| **Attack Scope** | 22 Domains | Cross-site contamination via shared hosting permissions |
| **Eradication Rate** | 100% | Complete removal of backdoors, Guardian scripts, and immutable bits |
---

## The Threat: "Zombie" Persistence Mechanisms

The malware employed **two advanced persistence techniques** that defeated standard removal:

### 1. Immutable Locking (`chattr +i`)
Files were locked at the **kernel level** using Linux immutable attributes, rendering standard deletion commands useless—even for root:
```
----i----------C------ malware.php  # Immutable bit set
```
Standard `rm -rf` failed with: `Operation not permitted`

### 2. Guardian Watchdog Scripts
Self-healing PHP scripts monitored critical files (`index.php`, `.htaccess`). On deletion/modification, the Guardian automatically re-wrote malicious code, creating an infinite restoration loop.

**Combined Effect:** A two-layer defense that required sequential unlock-then-delete operations rather than direct removal.

---

## Remediation Strategy
### Phase 1: Neutralization (Permission Stripping)
Since direct deletion was blocked, I implemented a **"Freeze Strategy"**—removing all execution permissions:
```bash
chmod 0000 infected_file.php  # Render payload non-executable
```

### Phase 2: Immutable Bit Removal & Deletion
Once Guardian scripts were neutralized, unlock the immutable bit and delete:
```bash
sudo chattr -i malware.php  # Remove immutable lock
sudo rm malware.php         # Safe deletion
```

### Phase 3: Multi-Domain Audit & Hardening
Developed automated scanning and hardening across all 22 domains:

**Scanning:** Bash one-liner to find all immutable files and suspicious signatures:
```bash
sudo lsattr -R /path/to/sites | grep "\----i"
grep -rE "eval\(|base64_decode\(" /path/to/sites --include="*.php"
```

**Hardening Applied:**
- ✅ C2 Blockade: Firewall rules for known C2 servers (zvo4.xyz, zqg5ai.bnshgy.top)
- ✅ Config Lockdown: Injected `define('DISALLOW_FILE_EDIT', true)` in all wp-config.php
- ✅ Execution Block: Updated .htaccess to prevent PHP execution in /assets directories
- ✅ Immutable Verification: Confirmed all immutable bits stripped

---

## Lab Validation (Reproducible Proof)

To validate the removal strategy, the "Immutable Deadlock" was reproduced in a controlled Ubuntu (OrbStack) environment:

```bash
# 1. Create malicious payload
mest@ubuntu:~$ echo "<?php echo 'Zombie Active';" > malware.php

# 2. Lock with immutable bit
mest@ubuntu:~$ sudo chattr +i malware.php
mest@ubuntu:~$ lsattr malware.php
----i----------C------ malware.php

# 3. Confirm standard deletion fails
mest@ubuntu:~$ sudo rm -rf malware.php
rm: cannot remove 'malware.php': Operation not permitted

# 4. Unlock immutable bit
mest@ubuntu:~$ sudo chattr -i malware.php

# 5. Successful removal
mest@ubuntu:~$ sudo rm malware.php
✓ Eradicated
```

---

## Results & Impact

| **Metric** | **Result** |
|------------|-----------|
| Malware Eradication | **100%** |
| Backdoors Removed | Gecko Shell, Tiny File Manager, Obfuscated CSS/Image payloads |
| Persistence Broken | Guardian watchdog scripts + immutable bits eliminated |
| Domains Hardened | 22/22 (100% coverage) |
| Current Status | **Zero reinfection** for 9+ months; monitored via Wordfence Central |

---

## Technical Artifacts & Tools

### Custom Automation
- **[malware-scanner.sh](scripts/malware-scanner.sh)** — Production-grade multi-domain audit tool with 4-layer detection:
  1. Immutable file detection (`lsattr`)
  2. Signature scanning (dangerous PHP functions)
  3. Typo-squatting detection (obfuscated config files)
  4. Hardening validation (DISALLOW_FILE_EDIT checks)

### Technology Stack
| Category | Tools |
|----------|-------|
| **Analysis & Scanning** | grep, find, lsattr, cat, VS Code (Restricted Mode) |
| **Environment** | Linux (Ubuntu/OrbStack), SSH, Xserver |
| **Automation** | Bash scripting for multi-domain orchestration |
| **Monitoring** | Wordfence Central, custom audit scripts |

### Documentation
- **README.md** — Complete incident narrative + technical deep dive
- **[docs/malware-analysis.md](docs/malware-analysis.md)** — Extensible analysis framework for post-incident reports
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** — AI agent guidelines for codebase maintenance

## 🚀 How to use the Scanner

The included `malware-scanner.sh` is a tool I developed to automate the detection of the "Zombie" attributes across all 22 domains.

**Usage:**

1. Give execution permission: `chmod +x malware_scanner.sh`
2. Run against a directory: `./malware_scanner.sh /var/www/html`
