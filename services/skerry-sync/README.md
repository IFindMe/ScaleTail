# Skerry Sync

[Skerry Sync](https://github.com/SeCherkasov/SkerrySSH) is the self-hosted sync server for the Skerry SSH client. It stores only ciphertext and sync metadata, verifies passwords with SRP-6a without ever receiving them, and pushes live updates over WebSocket.

This stack runs Skerry Sync with a Tailscale sidecar, as described in [the standard setup](../../documentation/standard-setup.md).

## At a glance

| Item          | Value                                        |
| ------------- | -------------------------------------------- |
| Web interface | `https://skerry-sync.<tailnet>.ts.net`       |
| Service port  | `8080`                                       |
| Image         | `secherkasov/skerry-sync`                    |
| Data          | `./skerry-sync-data/data` (database, keys)   |

## Before you start

- **`SKERRY_JWT_SECRET`.** The JWT signing secret. Compose stops with an error until you set it. Generate one with `openssl rand -base64 48` and keep it stable across restarts, or all issued tokens are invalidated. The server refuses to start with the upstream default unless `SKERRY_DEV=1`.
- **Data folder ownership.** The image runs as user and group `999`. Create the data folder and give it to that user before the first start, or the server cannot create its SQLite database:

  ```sh
  mkdir -p skerry-sync-data/data
  sudo chown -R 999:999 skerry-sync-data
  ```

## Deviations from the standard setup

None. The PostgreSQL database is optional and commented out in `compose.yaml`; the stack runs on SQLite until you enable it.

## First run

Open the web interface and create the first account.

## Configuration

- **PostgreSQL instead of SQLite.** Uncomment the `db` service in `compose.yaml` and its `depends_on` entry, set `SKERRY_DB_URL` to `jdbc:postgresql://localhost:5432/skerry`, and set `SKERRY_DB_USER` and `SKERRY_DB_PASSWORD` in `.env`. The database shares the Tailscale network namespace, so the server reaches it at `localhost`, and it listens only on loopback, so other Tailnet devices cannot reach it.
- **Admin endpoints.** `SKERRY_ADMIN_TOKEN` guards the operator console at `/console` and the `/admin/*` data endpoints. Leave it empty to keep them closed.
- **Admin CLI.** The `skerry-admin` tool runs inside the app container: `docker exec app-skerry-sync skerry-admin --help`.

## Troubleshooting

- **`SQLiteException: [SQLITE_CANTOPEN] Unable to open the database file` at startup.** The bind-mounted `skerry-sync-data/data` folder is not writable by the container's user `999`, usually because Docker created it as root. Stop the stack, then fix the ownership and start again:

  ```sh
  docker compose down
  sudo rm -rf skerry-sync-data/data
  mkdir -p skerry-sync-data/data
  sudo chown -R 999:999 skerry-sync-data
  docker compose up -d
  ```

## Links

- [Skerry Sync source code](https://github.com/SeCherkasov/SkerrySSH)
