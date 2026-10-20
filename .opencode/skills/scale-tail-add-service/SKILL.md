---
name: ScaleTail Add Service
description: Add a new service stack to the ScaleTail repo - research the upstream image, scaffold from the service template, write .env/compose.yaml/README, register it in the catalog, and run the full verification suite. Use when the user asks to add, create, or port a self-hosted app to ScaleTail.
---

# ScaleTail: add a service

End-to-end playbook for adding one service under `services/<name>/`. The repo's
`CONTRIBUTING.md`, `AGENTS.md`, and `templates/service-template/` are the rules;
this skill is the experience - the order to do things, the traps, and the
exact verification commands. When this skill and the repo docs disagree, the
repo docs win; re-read them first.

## Step 0 - research the upstream image

Never guess these facts. Check the upstream repo README/compose file, the
`Dockerfile`, and the entrypoint/docs. Collect:

1. **Image + tag** upstream recommends (use it explicitly; pin databases to a
   major or major.minor tag).
2. **Internal port** the app listens on (Serve proxies to it, hard-coded).
3. **Data path inside the container** and what lives there (database, generated
   secrets, uploads).
4. **Container user.** Read the Dockerfile (`USER`, which base image) and the
   entrypoint. This decides bind-mount ownership:
   - Runs as a fixed unprivileged UID (e.g. `999`): the user must
     `chown` the data folder before first start, or document it in
     "Before you start" and add a Troubleshooting entry with the exact error
     string (real case: Skerry Sync `SQLITE_CANTOPEN` with UID 999).
   - Entrypoint starts as root and drops via `gosu`/`usermod` (real case:
     Termix): passing `PUID`/`PGID` is allowed, the entrypoint fixes ownership
     itself, no user action needed.
   - Runs as root and writes freely (real case: ByteStash): nothing to do.
5. **HEALTHCHECK in the image?** `docker inspect` or the Dockerfile. If the
   image has one that works in this stack, do NOT override it - replace the
   template healthcheck block with the one-line comment naming what it checks.
   If not, add one (option 2-5 order from CONTRIBUTING; `wget --spider` against
   the app port is the usual choice and the base image must ship `wget`).
6. **Required vs optional secrets**, and whether the app refuses to start
   without them (real case: Skerry Sync rejects the default JWT secret).
7. **Optional extra services** upstream supports (PostgreSQL, a daemon, SSO).
   Include them commented-out, default-off, only when they are commonly wanted.

## Step 1 - scaffold

```sh
cp -R templates/service-template services/<name>
```

Lowercase directory name. This includes the hidden `.env`.

## Step 2 - write `.env`

- Keep the new-style header comments; set `SERVICE=<name>`, `IMAGE_URL`,
  `SERVICEPORT`.
- **Comments go on their own line, above the variable.** `VAR= # note` sets
  `VAR` to the literal string `# note` - never use trailing comments.
- Define every variable `compose.yaml` uses.
- Secrets: leave the value **empty**. When the stack cannot start without it,
  read it in compose as `${VAR:?Set VAR in .env}` and put a `# Required:`
  comment above it in `.env` saying what to set and how to generate it
  (e.g. `openssl rand -hex 32`). Keep `TS_AUTHKEY` and optional secrets
  without `:?`. **Never commit a working credential** - placeholders only.
- Commented-out blocks in `.env` explain how to enable optional features
  (external DB, OIDC, guacd) and mirror the commented blocks in compose.

## Step 3 - adapt `compose.yaml`

- Keep service keys `tailscale`/`application`, containers
  `tailscale-${SERVICE}`/`app-${SERVICE}`, `network_mode: service:tailscale`,
  and the health-based `depends_on` on `tailscale`.
- Hard-code the internal port in the Serve JSON (`http://127.0.0.1:<port>`).
  Never `${SERVICEPORT}` there.
- Pass `PUID`/`PGID` only when the image actually reads them (Step 0.4). Keep
  `TZ`.
- Data volume: `./${SERVICE}-data/<subpath>:<container path>` so `.gitignore`
  covers it.
- **Optional services**: include them fully written but commented out, plus a
  matching commented `depends_on` entry. Comment format is load-bearing - the
  user enables a feature by deleting the leading `#` only:

  ```yaml
        # Uncomment together with the `db` service below when using PostgreSQL.
        #db:
        #  condition: service_healthy
    ...
    #db:
    #  image: postgres:17-alpine
    #  network_mode: service:tailscale
    #  command: ["postgres", "-c", "listen_addresses=localhost"] # Tailnet cannot reach the db
    #  healthcheck:
  #    test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $${POSTGRES_USER} -d skerry"]
  ```

  Rules: `#key:` (no space) at the parent indent, `#` plus two spaces for child
  lines, double `# #` for pure instruction lines so they stay comments, and
  `$${VAR}` for variables the inner container must see, not Compose.
- A database sharing the sidecar namespace gets
  `command: ["postgres", "-c", "listen_addresses=localhost"]` so only the
  stack can reach it.

## Step 4 - write the service README

Use the template's headings in this exact order, no renames, no extra
headings; keep the template sentence when a section is empty:

`## At a glance` (table: Web interface, Service port, Image, Data) →
`## Before you start` (only what Quick Start lacks: required secrets -
state that Compose stops with an error until set - folders to create,
host groups) → `## Deviations from the standard setup` (`None.` when it
follows the template; list extra containers, ports, changed Serve) →
`## First run` → optional `## Configuration`, `## Troubleshooting`,
`## Upgrading` (in that order) → `## Links`.

Troubleshooting entries quote the real error string so they are findable.

## Step 5 - register in the root `README.md`

Insert one row, alphabetical by the bold name (case-insensitive), into the
fitting category table, matching that table's column widths and format
(no emoji in the current tables). Use the helper:

```sh
python3 .opencode/skills/scale-tail-add-service/scripts/insert-readme-row.py \
  "Category heading fragment" "Bold Name" "Description" "directory-name"
```

## Step 6 - verify (run all, from the repo)

```sh
# 1. Compose validation in each changed service dir. Gives required vars a
#    dummy value instead of editing .env. Must exit 0 with no warnings.
cd services/<name>
env $(grep -ohE '\$\{[A-Za-z0-9_]+:\?' compose.yaml .env | sed -E 's/^\$\{//; s/:\?$/=dummy/' | sort -u) \
  docker compose config --quiet

# 2. Uncommented optional variants, from a copy outside the repo:
#    .opencode/skills/scale-tail-add-service/scripts/validate-optional-variant.sh services/<name> <key> [<key>...]
#    (keys are the service names in the commented block, e.g. db guacd)

# 3. Markdown lint with the CI-pinned rumdl, whole tree, from the repo root:
version=$(sed -nE 's/.*version: "([0-9.]+)".*/\1/p' .github/workflows/linting.yml)
uvx "rumdl@$version" check --config .markdownlint.yml .

# 4. Whitespace check (fork: compare with upstream/main).
git diff --check upstream/main
```

`rumdl` needs `uv`; if unavailable, download the pinned version from the
rumdl releases. Step 2 is not in CONTRIBUTING but catches exactly the class of
bug that shipped once: an optional block whose uncommented YAML does not parse
or whose variables are undefined.

## Step 7 - commit and push

- Title: `Service: new service` (upstream convention). Stage only the intended
  files; `git status` first.
- A live Tailnet test (start the copied stack with a real `TS_AUTHKEY`) is the
  final proof when the user provides a key. Report it as not run otherwise.
- **Fork hygiene**: `upstream` is `https://github.com/tailscale-dev/ScaleTail`.
  Maintainers force-push and rewrite the catalog, template, and conventions.
  If `git push` is rejected, `git fetch upstream && git rebase upstream/main`,
  resolve conflicts (usually: take upstream's README structure, re-insert your
  row in the *new* format), and re-check Step 6 before pushing again. When
  conventions changed under you, rebuild the files to the new template instead
  of restoring old bytes.

## Trap sheet (all hit in real sessions)

| Symptom | Cause | Fix |
| --- | --- | --- |
| `SQLITE_CANTOPEN` / "unable to open database file" at startup | Bind mount auto-created as root; image runs as unprivileged UID | `chown -R <uid>:<gid>` the data folder; document it |
| App starts but Tailnet device shows unhealthy app | Optional block uncommented into invalid YAML, or variable used but undefined | Run Step 6.2; define every used variable in `.env` |
| `VAR= # note` "set" a weird value | Trailing comment in `.env` | Comments on their own line, above the variable |
| Push rejected / files resurrected in old format | Upstream force-push changed conventions | Step 7 fork hygiene; rebuild to the new template |
| Healthcheck always unhealthy | Image has its own HEALTHCHECK that this stack's port mapping breaks | Prefer the image's check; override only with a comment saying why |
| Database reachable from the Tailnet | Postgres listens on all interfaces of the shared namespace | `listen_addresses=localhost` |
