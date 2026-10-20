# ByteStash

[ByteStash](https://github.com/jordan-dalby/ByteStash) is a self-hosted code snippet manager. It stores your snippets in SQLite or PostgreSQL and offers search, categories, share links, and an MCP endpoint that lets AI assistants such as Claude work with your snippets.

This stack runs ByteStash with a Tailscale sidecar, as described in [the standard setup](../../documentation/standard-setup.md).

## At a glance

| Item          | Value                                        |
| ------------- | -------------------------------------------- |
| Web interface | `https://bytestash.<tailnet>.ts.net`         |
| Service port  | `5000`                                       |
| Image         | `ghcr.io/jordan-dalby/bytestash`             |
| Data          | `./bytestash-data/snippets` (database, keys) |

## Before you start

Nothing beyond the [Quick Start](../../README.md#quick-start).

## Deviations from the standard setup

None. The PostgreSQL database is optional and commented out in `compose.yaml`; the stack runs on SQLite until you enable it.

## First run

Open the web interface and create the first account. Registration stays open for further accounts until you set `ALLOW_NEW_ACCOUNTS` to `false` in `.env` and restart the stack.

## Configuration

- **PostgreSQL instead of SQLite.** Uncomment the `db` service in `compose.yaml`, its `depends_on` entry, and the `POSTGRES_*` lines in `application.environment`, then set `POSTGRES_PASSWORD` (and optionally `POSTGRES_USER` and `POSTGRES_DB`) in `.env`. Set `MIGRATE_SQLITE_TO_POSTGRES=true` to copy existing SQLite data over on first start; it only runs while PostgreSQL is empty, so it is safe to leave enabled. Keep the data volume either way: it also holds the JWT secret and snippet files.
- **JWT secret.** By default the app generates one and stores it in `./bytestash-data/snippets`. Set `JWT_SECRET` in `.env` to pin it. Whichever you choose, keep it stable and back it up with the data, or all sessions and API keys are invalidated.
- **Single-user mode.** `DISABLE_ACCOUNTS=true` bypasses login entirely and acts as one user. Combine it with `ALLOW_NEW_ACCOUNTS=false` on a trusted Tailnet.
- **Single sign-on.** OIDC is supported through the `OIDC_*` variables in `.env` and `compose.yaml`, see the [SSO setup wiki](https://github.com/jordan-dalby/ByteStash/wiki/Single-Sign%E2%80%90on-Setup).

## Links

- [ByteStash documentation and FAQ](https://github.com/jordan-dalby/ByteStash/wiki)
- [ByteStash source code](https://github.com/jordan-dalby/ByteStash)
