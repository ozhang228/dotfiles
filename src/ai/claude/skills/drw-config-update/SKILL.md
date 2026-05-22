---
name: drw-config-update
description: Make targeted config changes in DRW infra repos — k8s deployments (version/memory/cpu bumps) and alp-config (app-launcher widget edits). TRIGGER on prompts like "bump <app> to v<N>", "bump <app> memory", "applauncher v<N>", "add <variant> to app launcher", "remove <X> from alp-config", "decommission <X>".
---

# DRW Config Update

Apply small, formulaic config changes to one of two DRW infra repos.

You should:
1. Identify the repo and intent from the prompt.
2. Check out the conventional branch (fetch + pull master first).
3. Apply the change using the right mechanism for that app/repo.
4. Commit. If pre-commit hooks pass, the commit is good.
5. **Stop.** Confirm with the user before pushing or opening a PR.

Never use `--no-verify`. If a hook fails, fix the underlying issue and re-commit.

## Repo routing

- **app-launcher widget edits** (add/remove desk variants, decommission, trim apiSources) → `~/drw/alp-config`
- **everything else** (k8s version bumps, memory/cpu bumps, new instances) → `~/drw/k8s`

If the prompt is ambiguous, ask once. Most "bump" or "decommission" intents are k8s; most "add to app launcher" / "remove from app launcher" intents are alp-config.

## References

| Topic                             | Reference                              | When                                                                                                |
| --------------------------------- | -------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Declarative k8s deployments       | `references/declarative-deployments.md`| Any k8s change. Read before touching `desk_tools/applications/` or `overlays/desk-tools-managed/`.  |

## k8s changes (`~/drw/k8s`)

### Step 1: declarative or not?

Most desk-tools apps are declarative — Python is the source of truth, kustomization YAMLs are generated. A few legacy apps (notably `app-launcher` itself) edit overlays directly.

Detect:
- Look for `desk_tools/applications/<app>.py` or `desk_tools/applications/<app>/__init__.py`.
- Grep for `APPLICATION = ArgoCDApplication` in that file.
- If present → declarative. If absent → direct overlay edit.

See `references/declarative-deployments.md` for the full pattern and rationale.

### Step 2a: declarative app workflow

Branch name comes from the Python source: `qa_target_revision="desk-tools-<app>-qa"` on the `ArgoCDApplication`. Use that branch (never master, never a fresh `ozhang/*` branch) for routine version bumps. For ad-hoc resource bumps on a single app, a `ozhang/<descriptive>` branch off master is fine.

```
cd ~/drw/k8s
git fetch
git checkout <qa_target_revision>   # or git checkout -b ozhang/<descriptive> origin/master
git pull
```

Edit the Python file:
- **Version bump**: change the image string (e.g. `IMAGE = "desk-tools:uv-2505"` → `"desk-tools:uv-2525"`, or `image="..."` on each `Instance(...)`).
- **Memory bump**: change `memory=` (and `memory_limit_gb=` if present) on the relevant `Instance(...)` or `UnitRiskPublisher(...)` etc.
- **CPU bump**: change `cpu=`.

Regenerate overlays:

```
cd desk_tools && make
```

This runs format/lint/typecheck and rewrites the kustomizations. Verify with `git diff` that only the expected fields changed.

**Never edit `overlays/desk-tools-managed/.../kustomization.yaml` directly** — the next `make` will clobber the change.

### Step 2b: non-declarative app workflow

For apps without a `desk_tools/applications/<app>.py` declaration, edit overlays directly.

Known case: `app-launcher` (the deployment, not the alp-config widgets):
- Branch: `desk-tools-applauncher`
- Files: `overlays/app-launcher/web/{prod,qa,test}-no-envoy/kustomization.yaml`
- Change: the `value: "artifacts.drwholdings.com/ficc-docker-prod/ficc/app-launcher:<N>"` line in each (3 files).

For any other non-declarative app, ask the user to confirm the file paths before editing — these are rare and not standardized.

### Step 3: commit

Title format:
- Routine version bump: `<App> v<N>` (e.g. `Surface Viz v2525`, `App Launcher v1828`).
- Resource bump: descriptive (e.g. `Empirical Risk Unit Risk Publisher \`eurodollars\` bump mem by 5gb`).
- Kept under 70 chars.

Stop after commit. Confirm before push.

## alp-config changes (`~/drw/alp-config`)

App-launcher widget configs live in `scopes/app-launcher/{dev,prod,test}/widgets/*.json`. Branch: `ozhang/<descriptive>` off master.

```
cd ~/drw/alp-config
git fetch
git checkout -b ozhang/<descriptive> origin/master
```

Three case shapes — pick one based on intent:

### Add (e.g. "add treasuries-eris to edge server settings")

For a new desk variant `<variant>`:
1. Add entries to `apiSourceDiscovery.json` for both `dev/` and `prod/` (and `test/` if it has one). Mirror an existing similar variant's structure — find `settings-collections-<existing>` and `settings-edge-server-<existing>` and copy that block, swapping in the new variant.
2. Add the new key to widget files that list registered settings — typically `settingsCollections.json` and `settingsEdgeServerV2.json`. Keep alphabetical placement consistent with the file you copied from.
3. Apply across all envs (`dev/`, `prod/`, plus `test/` if entries exist there).

### Trim (e.g. "remove crypto coral from surfaceGridByMoneynessAndExpiration")

Remove only the entry from the widget's `apiSources` array. Don't touch the file's other contents.

### Hybrid: trim everywhere, delete files that go empty (e.g. "decommission rvuvs energy")

This is the dangerous case — delete-too-eagerly destroys widgets that share the apiSource with other desks. Be deliberate:

1. Find every widget JSON that references the apiSource(s) being killed.
2. For each, check the `apiSources` array:
   - If the array contains **only** the apiSource(s) being killed → delete the entire widget file.
   - If it contains other entries → trim only the targeted entries; leave the file in place.
3. Remove the apiSource entries from `apiSourceDiscovery.json`.
4. Remove from settings registries (`settingsCollections.json`, `settingsEdgeServerV2.json`, etc.) if listed.
5. Apply across `dev/`, `prod/`, `test/` consistently.

Verify with `git status` that the deleted/modified file set matches the analysis before committing.

### Step 3: commit

Descriptive title: `add treasuries-eris to edge server settings and collections`, `Decommission Energy RVUVS apps`, `Remove Crypto Coral as a choice from Applauncher SurfaceGridByMoneynessAndExpiration`.

Stop after commit. Confirm before push.

## Push + PR

When the user confirms:

```
git push -u origin <branch>
gh pr create --title "<commit title>" --body "<one-line description>"
```

For PRs against master in either repo, no special body template is enforced — keep the body short.
