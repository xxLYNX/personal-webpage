# Local build and verification

Deterministic build for the Hugo site with the **hugo-void** theme (Git submodule at `themes/hugo-void`).

**Package manager policy:** only **pnpm** is used for Node dependencies (`pnpm install --frozen-lockfile`, `pnpm run`). Do not use npm, npx, or yarn when running builds for this site.

## Prerequisites

| Tool | Version tested on pluto | Notes |
|------|-------------------------|--------|
| Git | any recent | Submodule must be initialized |
| Hugo Extended | **v0.170.0** | `nix shell nixpkgs#hugo` on NixOS |
| Node.js | **v24.22.2** | `nix shell nixpkgs#nodejs` |
| pnpm | **12.9.0** | `nix shell nixpkgs#pnpm` (matches theme `packageManager`) |

On NixOS, tools are often **not** on the default `PATH`. Use one shell:

```bash
cd /home/voyager/Projects/personal-webpage
nix shell nixpkgs#hugo nixpkgs#nodejs nixpkgs#pnpm --command ./scripts/build-site.sh
```

## One-command build

From any directory:

```bash
/path/to/personal-webpage/scripts/build-site.sh
```

The script:

1. Resolves the repository root from its own location (caller cwd does not matter).
2. Initializes `themes/hugo-void` if missing, then **requires** the theme checkout to match the exact commit recorded in the parent gitlink (`HEAD:themes/hugo-void`).
3. On mismatch, **exits with an error** (no reset/checkout of the submodule). Local uncommitted theme changes on the **correct** commit are not discarded.
4. Optional override for active theme work only: `ALLOW_THEME_SUBMODULE_DRIFT=1` (off by default; not for CI).
5. Runs `pnpm install --frozen-lockfile`, `pnpm run build:css`, and `hugo --minify` into `public/`.

**Failure on missing layouts:** If Hugo prints `found no layout file`, the build script exits non-zero. Deprecation warnings alone do not fail the build.

## Smoke test

```bash
nix shell nixpkgs#hugo nixpkgs#nodejs nixpkgs#pnpm --command ./scripts/smoke-test.sh
```

Checks non-empty HTML with basic structure for key routes, `public/css/style.css`, CMS static assets (`public/admin/*`), and a minimum HTML file count.

## Policy check (no npm in workflows)

```bash
./scripts/check-package-manager-policy.sh
```

## Dependency audit (theme)

Recorded findings only — do not auto-upgrade to silence audit output.

```bash
cd themes/hugo-void
pnpm audit
```

Exit code may be non-zero when vulnerabilities are reported; document and address in a planned upgrade, not ad hoc bumps.

## Preview locally

```bash
nix shell nixpkgs#hugo nixpkgs#nodejs nixpkgs#pnpm --command sh -c './scripts/build-site.sh && hugo server --source .'
```

Content is under `/en/`. CMS admin static files load at `/admin/` (see [cms.md](./cms.md)).

## Submodule troubleshooting

Empty `themes/hugo-void/` causes Hugo layout warnings and almost no HTML output:

```bash
git submodule update --init --recursive
ls themes/hugo-void/layouts
ls themes/hugo-void/pnpm-lock.yaml
```

Fresh clone (requires **both** repos to have the submodule commit on the remote — see Gate 1 report if the theme pointer is not yet pushed):

```bash
git clone --recurse-submodules <repository-url>
```

## URL / baseURL notes (preview vs production)

`hugo.toml` sets `baseURL = "https://example.com"` with `relativeURLs = true` and `canonifyURLs = true`. **Do not change baseURL** until a production custom domain is approved.

## Generated artifacts (do not commit)

| Path | Gitignored |
|------|------------|
| `public/` | yes (root `.gitignore`) |
| `resources/` | yes |
| `themes/hugo-void/node_modules/` | yes (theme `.gitignore`) |

## Submodule pin negative test

```bash
./scripts/test-submodule-pin-negative.sh
```

Uses a **disposable git worktree**; the main `themes/hugo-void` checkout is not modified.

- Exit **0** — mismatch rejected and submodule state preserved.
- Exit **1** — test failure.
- Exit **77** — skip (insufficient history for a wrong commit); **not** a pass in strict CI.

## deploy.sh (build only)

`deploy.sh` runs `scripts/build-site.sh` and `scripts/smoke-test.sh` only. It does **not** `git add`, `commit`, or `push`.