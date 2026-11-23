# Local build and verification

Deterministic build for the Hugo site with the **hugo-void** theme (Git submodule at `themes/hugo-void`).

## Prerequisites

| Tool | Version tested on pluto | Notes |
|------|-------------------------|--------|
| Git | any recent | Submodule must be initialized |
| Hugo Extended | **v0.170.0** | `nix shell nixpkgs#hugo` on NixOS |
| Node.js | **v24.22.2** | `nix shell nixpkgs#nodejs` |
| npm | **11.19.1** | Bundled with nixpkgs Node |

On NixOS, Node and Hugo are often **not** on the default `PATH`. Use a single shell:

```bash
cd /home/voyager/Projects/personal-webpage
nix shell nixpkgs#hugo nixpkgs#nodejs --command ./scripts/build-site.sh
```

## One-command build

From any directory:

```bash
/path/to/personal-webpage/scripts/build-site.sh
```

The script:

1. Resolves the repository root from its own location (caller cwd does not matter).
2. Runs `git submodule update --init --recursive` for `themes/hugo-void`.
3. Runs `npm ci` and `npm run build:css` inside the theme (uses `package-lock.json`).
4. Runs `hugo --minify` with output in `public/`.

**Failure on missing layouts:** If Hugo prints `found no layout file`, the build script exits non-zero even when Hugo’s exit code is 0. Deprecation warnings alone do not fail the build.

## Smoke test

After a successful build:

```bash
nix shell nixpkgs#hugo nixpkgs#nodejs --command ./scripts/smoke-test.sh
```

Checks non-empty HTML for:

- `/en/` → `public/en/index.html`
- `/en/blogs/understanding-pe-files/`
- `/en/projects/pe-trainer/`
- `/en/resume/`

Also verifies `public/css/style.css` exists and that the home page links to it.

## Preview locally

```bash
nix shell nixpkgs#hugo nixpkgs#nodejs --command sh -c './scripts/build-site.sh && hugo server --source .'
```

Open the URL Hugo prints (typically `http://localhost:1313/`). With `defaultContentLanguageInSubdir = true`, content lives under `/en/`.

## Submodule troubleshooting

Empty `themes/hugo-void/` causes Hugo layout warnings and almost no HTML output:

```bash
git submodule update --init --recursive
ls themes/hugo-void/layouts
```

Fresh clone:

```bash
git clone --recurse-submodules <repository-url>
```

## URL / baseURL notes (preview vs production)

`hugo.toml` currently sets `baseURL = "https://example.com"` with `relativeURLs = true` and `canonifyURLs = true`. **Do not change baseURL** until a production custom domain is approved (see execution plan).

- **Local `hugo server`:** Pages work with relative asset URLs.
- **Future Cloudflare Pages preview (`*.pages.dev`):** Set or override `baseURL` per environment in a later gate; avoid baking preview URLs into production canonicals.

## Generated artifacts (do not commit)

| Path | Gitignored |
|------|------------|
| `public/` | yes (root `.gitignore`) |
| `resources/` | yes |
| `themes/hugo-void/node_modules/` | yes (theme `.gitignore`) |
| `themes/hugo-void/static/css/style.css` | tracked in theme repo after `build:css` |

Run `git status` after building; only intentional source edits should appear staged.

## Legacy script

`deploy.sh` at the repo root is an older interactive workflow (commits/pushes theme and main repo). **Gate 0 uses `scripts/build-site.sh`** instead. `deploy.sh` is unchanged.