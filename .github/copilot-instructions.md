# Copilot Instructions: The Walking Dead - 22 Domains

## Project Overview
This is a technical case study documenting the identification, analysis, and remediation of a sophisticated multi-domain botnet infection. The project focuses on malware persistence mechanisms (Linux immutable attributes + self-healing scripts) and infrastructure hardening strategies.

**Key Goal:** Provide reproducible, documented evidence of malware eradication across 22 WordPress/Static sites and the hardening measures applied.

## Architecture & Key Concepts

### The Threat Model (Critical Context)
- **Persistence Layer:** Files locked with `chattr +i` (immutable) + "Guardian" watcher scripts that auto-restore malicious code
- **Attack Scope:** Cross-site contamination via shared hosting permissions
- **Eradication Strategy:** Three-phase approach (Neutralization → Audit → Hardening)

### Critical File Structure
- [README.md](README.md) - Comprehensive threat analysis, lab reproduction, and remediation steps
- [scripts/malware-scanner.sh](scripts/malware-scanner.sh) - Production audit tool (4 scanning layers)
- [docs/malware-analysis.md](docs/malware-analysis.md) - Reserved for detailed technical analysis (currently empty; expand here for post-incident reports)

## Developer Workflows & Commands

### Scanning for Malware Signatures
```bash
# Full multi-domain audit (from project root)
bash scripts/malware-scanner.sh /path/to/sites

# Standalone checks (referenced in script)
sudo lsattr -R /path/to/sites | grep "\----i"  # Immutable files
grep -rE "eval\(|base64_decode\(" /path/to/sites --include="*.php"  # Shell patterns
```

### Reproduction Lab (OrbStack/Ubuntu)
```bash
echo "<?php echo 'Zombie Active';" > malware.php
sudo chattr +i malware.php          # Lock file
sudo chattr -i malware.php          # Unlock file
sudo rm malware.php                 # Remove after unlock
```

## Project-Specific Patterns & Conventions

### Malware Scanner Design
The [malware-scanner.sh](scripts/malware-scanner.sh) follows a **4-layer audit pattern:**
1. **Immutable Detection:** `lsattr` for kernel-level locks (with macOS fallback)
2. **Signature Scanning:** `grep` for dangerous PHP functions (eval, base64_decode, shell_exec)
3. **Typo-Squatting Detection:** Find obfuscated config files (wp-confiq.php, wp-l0gin.php)
4. **Hardening Validation:** Check for `DISALLOW_FILE_EDIT` constants in wp-config.php

### Documentation Structure
- **README:** Incident narrative + technical deep dive + lab reproduction
- **docs/:** Reserved for post-remediation analysis and future incident logs
- **scripts/:** Production-grade automation (not proof-of-concept)

### Key Technical Details
- **Immutable Bits:** Linux capability preventing file deletion even by root (requires `chattr -i` unlock first)
- **Persistence Method:** PHP watcher scripts that trigger on file deletion/modification
- **Hardening Targets:** wp-config.php, .htaccess, asset directories, C2 blockade rules

## Common Tasks & Implementation Guidance

### Expanding the Audit Tool
When adding new scanning capabilities to [malware-scanner.sh](scripts/malware-scanner.sh):
- Maintain the 4-layer pattern (detection → signature → obfuscation → hardening)
- Include platform checks (`command -v`, macOS fallbacks)
- Follow error handling: suppress stderr with `2>/dev/null`, provide fallback messages
- Reference threat indicators from README.md

### Documenting New Findings
When adding to [docs/malware-analysis.md](docs/malware-analysis.md):
- Link back to specific threat indicators in README.md
- Include reproducible lab steps (see README simulation log format)
- Document eradication steps with before/after verification commands
- Focus on technical mechanisms, not threat actor attribution

### Security-First Approach
- All hardening recommendations must have:
  - Reproduction steps in lab environment (OrbStack/Ubuntu)
  - Specific file/config changes with examples from the README
  - Verification commands to confirm success
- Never assume malware absence; always verify with the scanner

## Integration Points & Dependencies

- **No external dependencies** for core scanning (bash, grep, find, lsattr)
- **Platform-specific:** Linux (Ubuntu/Debian) is the primary target; macOS gets graceful fallbacks
- **WordPress context:** Scanner excludes wp-admin/, wp-includes/, node_modules/
- **Incident response workflow:** Scanner output feeds into hardening decisions documented in README.md

## Key References
- Immutable file attributes: `man chattr`, `man lsattr`
- PHP security functions to monitor: `eval()`, `base64_decode()`, `shell_exec()`, `passthru()`, `system()`
- WordPress hardening: `define('DISALLOW_FILE_EDIT', true)` in wp-config.php
