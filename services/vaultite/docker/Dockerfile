# Vaultite as a server container:
#   docker build -f docker/Dockerfile -t vaultite .
#   docker compose -f docker/compose.yaml up -d
# and open http://localhost:8793
#
# The app needs Node >= 23.6, so the base image is node:24-bookworm.

FROM node:24-bookworm

# node-pty (a dependency, built when packages install) needs a toolchain.
RUN apt-get update && apt-get install -y --no-install-recommends build-essential python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Tailscale CLI only: app reads sidecar tailscaled socket via TS_SOCKET.
COPY --from=tailscale/tailscale:latest /usr/local/bin/tailscale /usr/local/bin/tailscale

WORKDIR /app

# Install dependencies first so the layer is cached before sources change.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

ENV HOST=0.0.0.0 PORT=8793 VAULTITE_VAULT=/app/vault
VOLUME ["/app/vault"]
EXPOSE 8793
COPY docker/entrypoint.sh /app/entrypoint.sh
# Upstream tracks the entrypoint as 644; make it executable for ENTRYPOINT.
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["node", "server.ts"]
