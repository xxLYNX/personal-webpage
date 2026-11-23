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
2. Runs `git submodule update --init --recursive` for `themes/hugo-void`.
3. Runs `pnpm install --frozen-lockfile` in the theme (requires `pnpm-lock.yaml`).
4. Runs `pnpm run build:css`.
5. Runs `hugo --minify` with output in `public/`.

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

## Legacy script

`deploy.sh` at the repo root still supports an interactive git-push workflow; its CSS step uses **pnpm**. Prefer `scripts/build-site.sh` for reproducible builds.