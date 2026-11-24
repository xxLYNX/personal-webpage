# Sveltia CMS — authentication and editorial workflow (Gate 2)

This site uses the **GitHub backend** with **`publish_mode: editorial_workflow`** targeting `xxLYNX/personal-webpage` and branch **`master`**. Content changes go through **feature branches and pull requests**, not direct pushes to `master`.

**Credential rule:** tokens live only in your browser (Sveltia local storage). Never commit tokens, put them in `config.yml`, or share them in chat or logs.

## Local preview server

```bash
cd /home/voyager/Projects/personal-webpage
nix shell nixpkgs#hugo nixpkgs#nodejs nixpkgs#pnpm --command sh -c \
  './scripts/build-site.sh && hugo server --source . --bind 127.0.0.1 --port 1313'
```

Open **http://127.0.0.1:1313/admin/** (or the port Hugo prints).

Use **127.0.0.1**, not `localhost`, if you use a fine-grained PAT (GitHub may restrict PATs by IP).

## Signing in (user only — no OAuth app in Gate 2)

1. On the Sveltia login screen, choose **Sign in with token** (Personal Access Token).
2. On GitHub, create a **fine-grained PAT** (recommended) for repository **`xxLYNX/personal-webpage`** only.
3. **Minimum repository permissions:**

   | Permission | Access | Why |
   |------------|--------|-----|
   | Contents | Read and write | Read/edit blog Markdown and assets |
   | Pull requests | Read and write | Editorial workflow opens and updates PRs |

   Metadata (read) is included automatically. A **classic** PAT alternative: scope **`repo`** (broader).

4. Paste the token **only** into the Sveltia browser prompt. The agent must not see or log it.
5. Confirm the CMS loads the **Blog** collection and lists existing posts (e.g. *Understanding Windows PE Files*).

**Editorial workflow:** saves create/update a branch (not `master`) and open or update a **draft pull request**.

## Signing out

Use Sveltia’s **Sign out** control in the UI (account menu). This removes the session; clear site data for `127.0.0.1` in the browser if you need a full reset.

## Creating an article

1. Open **Blog** → **New Blog Post**.
2. Set **title**, **date**, **draft** (keep `true` for editorial drafts), **tags**, **summary**, **externalUrl** as needed.
3. Use a unique slug/filename (Gate 2 test example: `gate2-editorial-test-YYYYMMDD`).
4. Write the **body** in Markdown.

## Saving an editorial draft

1. Click **Save** (not Publish).
2. Sveltia commits to a workflow branch and opens or updates a **draft PR** against `master`.
3. Wait for the save to finish; note the PR link in the CMS UI.

## Inspecting a pull request

1. Open the PR from Sveltia or from GitHub: `https://github.com/xxLYNX/personal-webpage/pulls`.
2. Verify **files changed**: expect `content/en/blogs/<slug>.md` only (no unrelated paths).
3. Confirm YAML front matter matches the existing blog format (`title`, `date`, `lastmod`, `draft`, `tags`, `summary`, `externalUrl`, body).

## Publishing an approved article

1. Review the PR on GitHub (human reviewer).
2. Merge the PR to **`master`** when approved (not performed by automation in Gate 2).
3. After merge, production/site build picks up the new post on the next deploy.

## Discarding an article

- **Before merge:** close the draft PR and delete the workflow branch on GitHub, or delete the entry in Sveltia if still on the branch.
- **After merge:** revert or follow-up PR on `master` (separate operational step).

## Revoking authentication

1. Sign out in Sveltia (above).
2. On GitHub: **Settings → Developer settings → Personal access tokens** — revoke or delete the PAT used for testing.
3. Optional: remove CMS data from browser local storage for `127.0.0.1`.

## Recovering when the CMS is unavailable

1. Edit `content/en/blogs/*.md` directly in Git.
2. Build: `nix shell nixpkgs#hugo nixpkgs#nodejs nixpkgs#pnpm --command ./scripts/build-site.sh`
3. Verify: `./scripts/smoke-test.sh`
4. Push via normal Git/PR workflow without `/admin/`.

## Verifying `master` was not changed by a draft

```bash
gh api repos/xxLYNX/personal-webpage/git/refs/heads/master --jq .object.sha
```

Editorial saves must **not** move this SHA until a PR is **merged**. Compare before and after CMS saves.