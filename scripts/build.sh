#!/bin/sh
# Build unico do Claw3D: TODO build passa por aqui (o Dockerfile chama este script).
#
# A versao vem do arquivo VERSION (fonte unica, versionada). O carimbo sai como
# `vX.Y.Z+<commit>`, com `*` no fim quando a arvore esta suja; sem git o commit e
# `unknown` e o rotulo perde o sufixo. Nao ha versao escrita a mao em fonte,
# Dockerfile ou variavel de ambiente: quem escreve e este script.
#
#   sh scripts/build.sh          # carimba .build-info.json + `next build`
#   sh scripts/build.sh --show   # so mostra o rotulo atual, sem buildar
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "${ROOT}"

VERSION_FILE="VERSION"
if [ ! -s "${VERSION_FILE}" ]; then
  echo "build: ${VERSION_FILE} ausente ou vazio" >&2
  exit 1
fi

VERSION_VALUE="$(tr -d ' \t\r\n' < "${VERSION_FILE}")"
COMMIT_VALUE="$(git rev-parse --short=7 HEAD 2>/dev/null || echo unknown)"
BUILD_TIME_VALUE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Sujeira de conteudo. Mudanca apenas de permissao — comum depois de sincronizar
# com Mac/Drive — nao conta: nao muda uma linha do que foi publicado e so
# serviria para poluir o rotulo com um `*` falso.
MODIFIED_VALUE=false
if [ "${COMMIT_VALUE}" != "unknown" ]; then
  if [ -n "$(git -c core.fileMode=false status --porcelain 2>/dev/null)" ]; then
    MODIFIED_VALUE=true
  fi
fi

LABEL="$(node src/lib/version-label.mjs "${VERSION_VALUE}" "${COMMIT_VALUE}" "${MODIFIED_VALUE}")"

if [ "${1:-}" = "--show" ]; then
  echo "version:  ${VERSION_VALUE}"
  echo "commit:   ${COMMIT_VALUE}"
  echo "modified: ${MODIFIED_VALUE}"
  echo "label:    ${LABEL}"
  exit 0
fi

case "${LABEL}" in
  *'"display":"v'*'"'*) ;;
  *) echo "build: rotulo inesperado: ${LABEL}" >&2; exit 1 ;;
esac

APP_VERSION="${VERSION_VALUE}" \
APP_COMMIT="${COMMIT_VALUE}" \
APP_BUILD_TIME="${BUILD_TIME_VALUE}" \
APP_MODIFIED="${MODIFIED_VALUE}" \
node scripts/write-build-info.mjs

echo "build: version=${VERSION_VALUE} commit=${COMMIT_VALUE} modified=${MODIFIED_VALUE}"

# Dependencias: no Docker elas vem da camada de cache; localmente, se faltarem,
# instalamos aqui para este script ser o unico caminho de build.
if [ ! -d node_modules ]; then
  npm ci
fi

npm run build

echo "build: artefato pronto (.build-info.json + .next) — $(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(".build-info.json","utf8")).display)')"
