# Theme dependency audit (recorded Gate 1)

Command (theme submodule):

```bash
cd themes/hugo-void
pnpm audit
```

**Recorded:** 2026-11-23 on pluto
**pnpm:** 12.9.0
**Direct devDependency:** `tailwindcss@3.4.17` (pinned in `package.json`)

**Result:** `pnpm audit` exit code **1** — **25 vulnerabilities** reported (1 low, 9 moderate, 15 high).

**Representative transitive paths (not upgraded in this gate):**

| Package | Via | Severity (sample) |
|---------|-----|-------------------|
| `minimatch` | `tailwindcss` → `sucrase` → `glob` | high (multiple GHSA) |
| `glob` | `tailwindcss` → `sucrase` | moderate |
| `picomatch` | `tailwindcss` → `micromatch` / `anymatch` / `readdirp` | high |
| `postcss-selector-parser` | `tailwindcss` → `postcss-nested` / direct | high / low |

**Policy:** findings are documented only. Do not run `pnpm audit fix` or bump versions solely to clear audit output in this gate.

**Note:** Tailwind’s CLI may print a Browserslist message that mentions `npx`. That text comes from a dependency; **this project does not invoke npx** in `scripts/build-site.sh` or `deploy.sh`.