#!/bin/sh
# Publica uma versao do Claw3D: grava o VERSION, commita, marca a TAG e empurra.
#
# O numero da versao vive em VERSION (e o que o build carimba) e a TAG do repo e
# o registro publico da mesma coisa — e e a tag `v*` que o workflow
# `docker-publish.yml` usa para publicar a imagem `X.Y.Z` + `latest` no GHCR.
# Versao sem tag nao existe para quem olha o repositorio nem para o registro.
#
#   sh scripts/release.sh 0.1.5     # grava a versao, commita, marca e empurra
#   sh scripts/release.sh --show    # mostra versao, ultima tag e o que falta
set -eu

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

show() {
  echo "VERSION (arquivo): $(cat VERSION 2>/dev/null || echo '—')"
  echo "package.json:      $(node -e 'process.stdout.write(require("./package.json").version)' 2>/dev/null || echo '—')"
  echo "Ultima tag:        $(git describe --tags --abbrev=0 2>/dev/null || echo 'nenhuma')"
  echo "Ultimo commit:     $(git log -1 --format='%h %s' 2>/dev/null || echo '—')"
  echo "Branch:            $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '—')"
  echo "Arvore suja:       $(test -n "$(git -c core.fileMode=false status --porcelain)" && echo 'SIM (o artefato nao vai representar o commit)' || echo 'nao')"
}

if [ "${1:-}" = "--show" ] || [ "$#" -eq 0 ]; then
  show
  exit 0
fi

NEW_VERSION="${1#v}"

case "${NEW_VERSION}" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "release: versao invalida '${1}' — use X.Y.Z (ex.: 0.1.5)" >&2; exit 1 ;;
esac

CURRENT="$(cat VERSION 2>/dev/null || echo '')"
if [ "${NEW_VERSION}" = "${CURRENT}" ]; then
  echo "release: ${NEW_VERSION} ja e a versao do arquivo — nada a gravar" >&2
  exit 1
fi

if [ -n "$(git -c core.fileMode=false status --porcelain)" ]; then
  echo "release: arvore suja. Commite (ou descarte) antes de marcar uma versao." >&2
  git status --short
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "release: ${CURRENT:-?} -> ${NEW_VERSION} em ${BRANCH}"

node scripts/set-version.mjs "${NEW_VERSION}"
git add VERSION package.json
git commit -m "chore(versao): ${NEW_VERSION}"
git tag -a "v${NEW_VERSION}" -m "Claw3D v${NEW_VERSION}"

echo "release: tag v${NEW_VERSION} criada. Empurrando commit e tag..."
git push origin "${BRANCH}"
git push origin "v${NEW_VERSION}"

show
echo "release: feito. A tag publica a imagem X.Y.Z no GHCR e o servidor passa a responder /api/version com v${NEW_VERSION}+<commit>."
