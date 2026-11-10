# Claw3D - 3D agent visualization for OpenClaw.
# Multi-stage build: install prod deps -> build Next.js -> run with custom server.

FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts --omit=dev

FROM node:22-slim AS builder
WORKDIR /app
# git: o carimbo de versao (scripts/build.sh) le o commit do repositorio. Sem ele
# o rotulo perderia o sufixo e o commit sairia "unknown".
RUN apt-get update \
  && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
# Build-time gateway URL (overridden at runtime by CLAW3D_GATEWAY_URL).
ENV NEXT_PUBLIC_GATEWAY_URL=ws://127.0.0.1:18789
# Build unico do projeto: carimba `.build-info.json` a partir do VERSION e so
# depois roda o `next build` (nada de versao escrita a mao no Dockerfile).
RUN sh scripts/build.sh

FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy built app + custom server + production node_modules only.
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/server ./server
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/next.config.mjs ./next.config.mjs
# Carimbo de versao lido em runtime por GET /api/version e GET /api/health.
COPY --from=builder /app/.build-info.json ./.build-info.json
COPY --from=builder /app/VERSION ./VERSION

EXPOSE 3000

CMD ["node", "server/entrypoint.js"]
