---
name: baremodal-workstation
description: Run and troubleshoot small research experiments on the persistent BareModal service hosted by the remote workstation. Use for cheap, short, trusted single-machine jobs that fit one RTX 3080; use hosted Modal instead when work needs larger or multiple GPUs, isolation, autoscaling, durable jobs, or full Modal functionality.
---

# BareModal Workstation

Use the workstation for small, inexpensive experiments. Use hosted Modal for
larger or more powerful compute and whenever the job depends on the complete
Modal platform.

## Choose the execution backend

- Prefer the workstation for short inference, debugging, prototypes, and
  single-GPU experiments that fit comfortably in 10 GiB of VRAM.
- Prefer hosted Modal for larger or multiple GPUs, more CPU or memory, parallel
  scaling, containers/images, Secrets, Volumes, Sandboxes, web endpoints,
  scheduled or durable jobs, or any other full Modal feature.
- Treat BareModal as a trusted-user compatibility subset, not as a production
  Modal replacement. Functions run directly under the remote Unix account with
  no container or resource isolation.

## Current workstation

Use the SSH alias `workstation` for host `sonnet-wkst`.

As of 2026-07-23, the workstation has:

- AMD Ryzen 9 5900X: 12 cores and 24 logical CPUs
- 62 GiB RAM
- NVIDIA GeForce RTX 3080 with 10 GiB VRAM
- 1.8 TiB home filesystem with about 1.7 TiB available

Recheck hardware with `lscpu`, `free -h`, `nvidia-smi`, and `df -h` when exact
capacity matters.

The installed BareModal resources are:

- Backend source: `/home/dylan/code/baremodal`
- Shared uv project and worker environment: `/home/dylan/baremodal-runtime`
- Persistent systemd user unit:
  `/home/dylan/.config/systemd/user/baremodal.service`
- Authentication environment:
  `/home/dylan/.config/baremodal/env`
- Runtime state: `/home/dylan/.local/share/baremodal`
- Loopback gRPC endpoint: `127.0.0.1:50051`
- Loopback blob/status endpoint: `127.0.0.1:50052`
- Exact supported client: `modal==1.5.2`

The service is enabled at boot, user lingering is enabled, and systemd restarts
it three seconds after a failure.

## Run an experiment

1. Check the backend with:

   ```bash
   ssh workstation 'systemctl --user is-active baremodal &&
     curl -fsS http://127.0.0.1:50052/healthz'
   ```

2. Forward both endpoints from the client machine:

   ```bash
   ssh -N \
     -L 50051:127.0.0.1:50051 \
     -L 50052:127.0.0.1:50052 \
     workstation
   ```

3. Read the two `BAREMODAL_*` values from the remote authentication environment
   without printing or persisting them. Export them locally as
   `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET`, and set:

   ```bash
   export MODAL_SERVER_URL=http://127.0.0.1:50051
   ```

4. Invoke the Modal client using the locally available environment or package
   manager. Ensure the client is exactly version `1.5.2`, then run the
   application.

5. Close the SSH tunnel when the experiment is complete. Leave the remote
   systemd service running.

Install every executable, model, and driver needed by remote functions on the
workstation first; image declarations are accepted but ignored. Validate a
change with a real client call through the tunnel.

## Manage remote Python dependencies

Use uv as the only Python dependency manager for the shared remote runtime.
There is already a central project, separate from the backend source, to pin
against:

- `/home/dylan/baremodal-runtime/pyproject.toml` declares dependency constraints
  and references the BareModal source as an editable path dependency.
- `/home/dylan/baremodal-runtime/uv.lock` records exact resolved versions.
- `/home/dylan/baremodal-runtime/.venv` is the shared environment used by the
  backend and every fresh worker subprocess.

Add packages needed by remote jobs as regular project dependencies:

```bash
ssh workstation \
  '~/.local/bin/uv --project /home/dylan/baremodal-runtime add "PACKAGE_CONSTRAINT"'
```

Use `uv remove PACKAGE` to remove one, `uv tree` to inspect the resolved
environment, and `uv sync --frozen --no-dev` to reproduce the locked service
environment. Target `/home/dylan/baremodal-runtime` with `--project` or run the
commands from that directory.

Do not use `pip install`, `uv pip install`, or other untracked installation
methods. A later exact uv sync may remove packages absent from the lockfile.
Do not place worker runtime packages in the dev group, an optional extra, or a
non-default group: the service starts with `--no-dev` and does not select extras
or additional groups.

`uv add` updates `pyproject.toml`, `uv.lock`, and `.venv`. New worker
subprocesses then see the dependency; do not restart the service merely for a
job dependency unless a verification call shows it is necessary. All jobs
share this one environment; use hosted Modal when experiments require
incompatible dependency sets or image-level isolation.

## Operate the service

Use:

```bash
ssh workstation 'systemctl --user status baremodal'
ssh workstation 'journalctl --user -u baremodal -n 100 --no-pager'
ssh workstation 'systemctl --user restart baremodal'
```

Do not expose either backend port publicly. Keep them bound to loopback and
access them through SSH.
