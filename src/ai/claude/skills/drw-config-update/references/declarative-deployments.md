# Declarative k8s Deployments

Reference for the desk-tools declarative deployment system in `~/drw/k8s`. Read this before making changes to anything under `desk_tools/applications/` or `overlays/desk-tools-managed/`.

## What it is

Historically, provisioning new k8s instances (or new applications) in this repo meant wrestling with overlay/inheritance chains and copying jsonnets. Errors were common, the structure was opaque, and patches piled up.

Desk-tools adopted a Python-native approach: declare the application in Python, regenerate the YAML/jsonnets from a single source. This means:

- **Source of truth** lives in `desk_tools/applications/<app>.py` (or `desk_tools/applications/<app>/__init__.py` for multi-file modules).
- **Generated artifacts** live under `overlays/desk-tools-managed/<app>/...`. These are rewritten on every `make` and **must not be edited directly**.

## The shape of a declared application

Each module exposes a top-level variable `APPLICATION = ArgoCDApplication(...)`:

```python
from . import ArgoCDApplication, AutosyncPolicy, Instance, replace

qa_instances = [
    Instance(
        env="qa",
        name="<instance-name>",
        config={...},
        memory=1.0,
        cpu=0.01,
        image="desk-tools:cpp-373",
        replicas=1,
        run_args=[...],
        env_vars={...},
    )
]

prod_instances = [
    replace(instance, env="prod", env_vars=instance.env_vars | {...})
    for instance in qa_instances
]

APPLICATION = ArgoCDApplication(
    name="<app-name>",
    qa_target_revision="desk-tools-<app>-qa",
    instances=qa_instances + prod_instances,
)
```

Key fields:
- `name` — the application name in ArgoCD.
- `qa_target_revision` — the **branch name** to use for QA routine bumps. The convention is `desk-tools-<app>-qa`.
- `instances` — list of `Instance` records. Each one becomes one overlay under `overlays/desk-tools-managed/<app>/{env}/{instance-name}/`.

To bump an image: change `image=` on each `Instance(...)` (or, when factored out, the shared `IMAGE = ...` constant near the top of the module).

To bump memory/cpu: change `memory=` / `cpu=` on the relevant `Instance(...)`.

## Compile

After editing, regenerate from the `desk_tools` directory:

```
cd ~/drw/k8s/desk_tools && make
```

The default `make` target runs:
1. `uv sync` (install deps if needed)
2. `uv run ruff format .`
3. `uv run ruff check --fix .`
4. `uv run ty check .`
5. `uv run python __main__.py` — scans `applications/`, calls each module's `APPLICATION.manifest()`, writes the generated jsonnets/YAMLs to `overlays/`.

If `make` fails on lint/format/typecheck, fix the underlying issue. Don't bypass.

## Sanity check

After compile, `git diff` should show only the fields you intended to change (e.g. just the image string lines). If it shows wide-ranging churn, something is off — usually a stale checkout or a Python edit that touched more than intended.

## Branches

- **Routine version bumps for app `<app>`** → use the branch named in `qa_target_revision` (typically `desk-tools-<app>-qa`). These branches accumulate the routine bump cadence and are the same ones ArgoCD QA points at via `qa_target_revision`.
- **Ad-hoc resource bumps or one-off changes** → cut a fresh `ozhang/<descriptive>` branch from master. These shouldn't pollute the QA bump branch's history.
- **First-time provisioning of a new application** → create the branch named in the new application's `qa_target_revision`, PR from there. Provision QA instances only on the first PR; promote to prod once stable.

## When this pattern doesn't apply

Not every app under `~/drw/k8s` is declarative. Legacy apps still edit overlays directly. The clearest tell:

- If `desk_tools/applications/<app>.py` (or `<app>/__init__.py`) exists **and** defines `APPLICATION = ArgoCDApplication(...)` → declarative.
- Otherwise → direct overlay edit. Known case: `app-launcher` (the deployment under `overlays/app-launcher/web/`, not the alp-config widget configs).

When in doubt, grep:

```
grep -rl "APPLICATION = ArgoCDApplication" desk_tools/applications/ | grep -i <app>
```

Empty result → not declarative.

## Common mistakes

- Editing `overlays/desk-tools-managed/<app>/.../kustomization.yaml` directly. Next `make` rewrites it.
- Forgetting to run `make` after editing the Python file. The Python change won't reach k8s until the overlays are regenerated and committed.
- Cutting a fresh `ozhang/*` branch for a routine version bump instead of using `desk-tools-<app>-qa`. The QA branch is what ArgoCD watches.
- Bypassing pre-commit with `--no-verify`. The lint/typecheck inside `make` exists for a reason; if it fails, the regeneration is broken.
