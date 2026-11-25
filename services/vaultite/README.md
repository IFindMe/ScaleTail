# Vaultite

[Vaultite](https://github.com/Vaultite/vaultite) is a local knowledge base you and your AI write together in plain Markdown files, with pages, links, and a knowledge graph.

This stack runs Vaultite with a Tailscale sidecar, as described in [the standard setup](../../documentation/standard-setup.md).

## At a glance

| Item          | Value                               |
| ------------- | ----------------------------------- |
| Web interface | `https://vaultite.<tailnet>.ts.net` |
| Service port  | `8793`                              |
| Image         | `vaultite` (built locally)          |
| Data          | `./vaultite-data/vault/`            |

## Before you start

Clone the Vaultite source into `services/vaultite/source/`. This repository does not include the application source, and the local build needs `package.json`, `package-lock.json`, and the sources in that folder:

```sh
git clone https://github.com/Vaultite/vaultite.git source
```

## Deviations from the standard setup

- Vaultite has no published image in this stack, so Compose builds `IMAGE_URL` from `docker/Dockerfile` on `node:24-bookworm` (Node 23.6 or later). Run `docker compose build` again after changing the Dockerfile or the source.
- The vault is a bind mount at `./vaultite-data/vault` instead of a Docker named volume, so it stays beside `compose.yaml`.
- Tailnet access uses Serve on port `8793`. To also open `http://localhost:8793` as in the upstream instructions, uncomment the `ports` block of the `tailscale` service.

## First run

Open the web interface. Vaultite has no accounts, so keep access on your Tailnet; create a vault or open an existing folder of Markdown files in the vault directory.

## Links

- [Vaultite documentation](https://github.com/Vaultite/vaultite#readme)
- [Vaultite source code](https://github.com/Vaultite/vaultite)
