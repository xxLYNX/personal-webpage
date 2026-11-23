# Sveltia CMS (Gate 1 — blog only)

## What it owns

| In scope | Out of scope |
|----------|----------------|
| Blog posts under `content/en/blogs/*.md` | Projects, resume, data TOML, about pages |
| Section list `content/en/blogs/_index.md` is **not** in the editor (Hugo default; `_index.md` hidden from folder collections) | JobDesk or private databases |

Content model matches existing YAML front matter:

- `title`, `date`, `lastmod`, `draft`, `tags`, `summary`, `externalUrl`, Markdown body

Reference article: `content/en/blogs/understanding-pe-files.md` (permalink `/en/blogs/understanding-pe-files/`).

## Files

| Path | Purpose |
|------|---------|
| `static/admin/index.html` | Loads **Sveltia CMS** `0.271.2` from unpkg (pinned) |
| `static/admin/config.yml` | GitHub backend → `xxLYNX/personal-webpage`, branch `master`, editorial workflow |

After `hugo` build, the admin UI is at `/admin/` (also `/en/admin/` may redirect depending on routing; primary static path is `public/admin/`).

## Authentication

**Not configured in Gate 1.** The GitHub backend requires OAuth or a GitHub App in a later gate. Visiting `/admin/` may load the shell but login/save will fail until credentials are set up by the user in the browser.

## Recovery without the CMS

The site is still a normal Hugo project:

1. Edit Markdown under `content/en/blogs/` directly.
2. Run `./scripts/build-site.sh` and `./scripts/smoke-test.sh`.
3. Remove or ignore `static/admin/` if needed; the public site does not depend on Sveltia at runtime.

## Verification

```bash
test -f public/admin/index.html
test -f public/admin/config.yml
grep -q 'understanding-pe-files' public/en/blogs/understanding-pe-files/index.html
```

Schema reference in `config.yml` points at the same pinned Sveltia version as `index.html`.