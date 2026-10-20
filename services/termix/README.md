# Termix

[Termix](https://github.com/Termix-SSH/Termix) is a self-hosted server management platform and Termius alternative. It puts SSH terminals, remote desktops, file transfers, tunnels, Docker management, metrics, and automations in one web interface.

This stack runs Termix with a Tailscale sidecar, as described in [the standard setup](../../documentation/standard-setup.md).

## At a glance

| Item          | Value                                     |
| ------------- | ----------------------------------------- |
| Web interface | `https://termix.<tailnet>.ts.net`         |
| Service port  | `8080`                                    |
| Image         | `ghcr.io/lukegus/termix`                  |
| Data          | `./termix-data/data` (database, keys)     |

## Before you start

Nothing beyond the [Quick Start](../../README.md#quick-start).

## Deviations from the standard setup

None. The Guacamole daemon for remote desktop is optional and commented out in `compose.yaml`.

## First run

Open the web interface and create the admin account. Registration stays open for further accounts until you lock it down in Admin Settings or set `ALLOW_REGISTRATION` to `false`, see the [environment variables](https://docs.termix.site/setup/environment-variables).

## Configuration

- **Remote desktop (RDP, VNC, Telnet).** Uncomment the `guacd` service in `compose.yaml` and its `depends_on` entry, set `ENABLE_GUACAMOLE` to `true` in `.env`, then turn on the RDP/VNC/Telnet toggle in Admin Settings with guacd URL `localhost:4822`. The daemon shares the Tailscale network namespace, so only this stack's containers can reach it. Disabled by default; SSH and terminal features work without it.
- **External database.** SQLite is the default and needs no setup. For PostgreSQL or MySQL, uncomment the `DATABASE_DIALECT` and `DATABASE_URL` lines in `compose.yaml` and set them in `.env`, see [database setup](https://docs.termix.site/setup/database). Keep the data folder either way: Termix uses it for keys, certificates, and recordings.
- **Generated secrets.** Security keys are auto-generated on first startup into `/app/data/.env`. Do not set them manually unless restoring from backup.
- **User and group.** The container starts as root, moves its files to `PUID`/`PGID` (default `1000`), and drops to that user.

## Links

- [Termix Docker install](https://docs.termix.site/install/server/docker)
- [Termix environment variables](https://docs.termix.site/setup/environment-variables)
- [Termix source code](https://github.com/Termix-SSH/Termix)
