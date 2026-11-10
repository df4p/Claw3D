#!/bin/sh
# Travas do padrao de versionamento (rode no PR: falham cedo, antes do deploy).
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "${ROOT}"

falhas=0
ok()   { echo "  ok   $*"; }
fail() { echo "  FALHA $*" >&2; falhas=$((falhas + 1)); }

echo "check-versioning: $(pwd)"

# 1. Fonte unica: VERSION semantico.
VERSION_VALUE=""
if [ -s VERSION ] && grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION; then
  VERSION_VALUE="$(tr -d ' \n' < VERSION)"
  ok "VERSION = ${VERSION_VALUE}"
else
  fail "VERSION ausente ou fora do formato X.Y.Z"
fi

# 2. package.json conta a mesma historia (e metadado npm, nao fonte).
PKG_VERSION="$(node -e 'process.stdout.write(require("./package.json").version)' 2>/dev/null || echo '')"
if [ -n "${VERSION_VALUE}" ] && [ "${PKG_VERSION}" = "${VERSION_VALUE}" ]; then
  ok "package.json version = ${PKG_VERSION}"
else
  fail "package.json version (${PKG_VERSION:-?}) diferente do VERSION (${VERSION_VALUE:-?}) — use scripts/release.sh"
fi

# 3. O rotulo sai no formato combinado, sem numero escrito a mao.
LABEL="$(node src/lib/version-label.mjs "${VERSION_VALUE:-0.0.0}" abc1234 false)"
case "${LABEL}" in
  *'"display":"v'"${VERSION_VALUE}"'+abc1234"'*) ok "rotulo limpo: $(printf '%s' "${LABEL}" | sed 's/.*"display":"//; s/".*//')" ;;
  *) fail "rotulo fora do formato vX.Y.Z+<commit>: ${LABEL}" ;;
esac
SUJO="$(node src/lib/version-label.mjs "${VERSION_VALUE:-0.0.0}" abc1234 true)"
case "${SUJO}" in
  *'*"'*) ok "rotulo sujo ganha asterisco" ;;
  *) fail "arvore suja nao marcou o rotulo: ${SUJO}" ;;
esac
SEM_GIT="$(node src/lib/version-label.mjs "${VERSION_VALUE:-0.0.0}" unknown false)"
case "${SEM_GIT}" in
  *'"display":"v'"${VERSION_VALUE:-0.0.0}"'"'*) ok "sem git: rotulo sem sufixo e commit unknown" ;;
  *) fail "sem git o rotulo deveria perder o sufixo: ${SEM_GIT}" ;;
esac

# 4. Nenhuma versao escrita a mao no codigo da versao.
if grep -RInE '"[0-9]+\.[0-9]+\.[0-9]+"' src/lib/buildinfo.ts src/app/api/version/route.ts >/dev/null 2>&1; then
  fail "versao escrita a mao em src/lib/buildinfo.ts ou src/app/api/version/route.ts"
else
  ok "codigo da versao sem numero escrito a mao"
fi

# 5. Rota de leitura existe.
if [ -f src/app/api/version/route.ts ]; then
  ok "GET /api/version existe"
else
  fail "src/app/api/version/route.ts ausente"
fi

# 6. Build unico: o Dockerfile chama scripts/build.sh, tem git no builder e leva
#    o carimbo para a imagem final.
if grep -q 'scripts/build.sh' Dockerfile; then
  ok "Dockerfile chama scripts/build.sh"
else
  fail "Dockerfile nao chama scripts/build.sh (build fora do padrao)"
fi
if grep -Eq 'apt-get install.*git|apk add.*git' Dockerfile; then
  ok "Dockerfile instala git no builder"
else
  fail "Dockerfile sem git no builder (o commit do carimbo sairia 'unknown')"
fi
if grep -q '.build-info.json' Dockerfile; then
  ok "carimbo entra na imagem final"
else
  fail "Dockerfile nao copia .build-info.json para o runtime (o servidor responderia sem versao)"
fi

# 7. .dockerignore so com o que o git ignora — excluir arquivo RASTREADO faz o
#    git dentro do container ve-lo como apagado e o build se declarar sujo
#    (rotulo com `*` falso). E `.git` precisa entrar no contexto de build.
if [ -f .dockerignore ]; then
  rastreados="$(git ls-files -ci --exclude-from=.dockerignore 2>/dev/null || true)"
  if [ -n "${rastreados}" ]; then
    fail ".dockerignore exclui arquivo rastreado: $(echo "${rastreados}" | head -3 | tr '\n' ' ')"
  else
    ok ".dockerignore nao exclui arquivo rastreado"
  fi
  if grep -Eq '^[[:space:]]*\.git/?[[:space:]]*$' .dockerignore; then
    fail ".dockerignore exclui .git — o commit do carimbo sairia 'unknown'"
  else
    ok ".git entra no contexto de build"
  fi
else
  ok "sem .dockerignore"
fi

if [ "${falhas}" -ne 0 ]; then
  echo "check-versioning: ${falhas} falha(s)" >&2
  exit 1
fi
echo "check-versioning: tudo verde"
