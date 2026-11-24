# Remote reproducibility (after feature branches are pushed)

Use this **after** review approves pushing; do not merge until separately authorized.

## 1. Publish theme (`hugo-void`)

```bash
cd /path/to/hugo-void   # or: cd themes/hugo-void
git checkout chore/pnpm-package-management
git push -u origin chore/pnpm-package-management
```

Optional: open a PR to `master` on `xxLYNX/hugo-void` and merge when approved so the pinned SHA exists on `master`.

Record the pushed theme commit (must match parent gitlink), e.g. `6d7c9f8d4fe37c8aca70a1b40a6ae86b985823a1`.

## 2. Publish website (`personal-webpage`)

```bash
cd /path/to/personal-webpage
git checkout chore/website-publishing-foundation
git push -u origin chore/website-publishing-foundation
```

Ensure `themes/hugo-void` in the index points to the **published** theme commit before pushing.

## 3. Clean clone verification (GitHub)

```bash
rm -rf /tmp/personal-webpage-verify
git clone --recurse-submodules git@github.com:xxLYNX/personal-webpage.git /tmp/personal-webpage-verify
cd /tmp/personal-webpage-verify
git checkout chore/website-publishing-foundation
git submodule update --init --recursive
# Confirm submodule SHA:
git submodule status themes/hugo-void
nix shell nixpkgs#hugo nixpkgs#nodejs nixpkgs#pnpm --command ./scripts/build-site.sh
nix shell nixpkgs#hugo nixpkgs#nodejs nixpkgs#pnpm --command ./scripts/smoke-test.sh
./scripts/check-package-manager-policy.sh
./scripts/test-submodule-pin-negative.sh
```

**Prerequisite:** step 1 must have pushed the theme commit that the parent gitlink references. Otherwise `git clone --recurse-submodules` fails with `not our ref`.

## 4. What not to do in this gate

- Do not merge to `master` on either repository without explicit approval.
- Do not configure OAuth, PATs, or Cloudflare until later gates.