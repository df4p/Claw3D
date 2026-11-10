# Versionamento do Claw3D

Padrao df4p: **uma fonte de versao, um rotulo honesto, uma tag por release** — o
mesmo esquema do Hub df4p (`v1.2.0`) e dos sites.

## Onde a versao vive

| Onde | O que e |
| --- | --- |
| `VERSION` | **Fonte unica.** Semantico, sem `v` (ex.: `0.1.4`). |
| `package.json#version` | Espelho npm, mantido igual pelo `scripts/release.sh` e conferido pela trava. |
| `src/lib/version-label.mjs` | Unica implementacao do rotulo (`vX.Y.Z+<commit>`, `*` se sujo). Usada pelo build e pelo teste unitario. |
| `.build-info.json` | Carimbo escrito pelo build, copiado para a imagem e lido em runtime por `src/lib/buildinfo.ts`. |
| `GET /api/version` | Leitura publica: versao, tag, commit, `modified`, `display`, `tags_url`. Sempre `no-store`. |
| `GET /api/health` | Traz os mesmos campos de versao. |
| tag `vX.Y.Z` | **Registro publico**: alem de marcar o commit, e ela que dispara o `docker-publish.yml` (imagem `X.Y.Z` + `latest` no GHCR). |

## Comandos

```sh
sh scripts/build.sh --show     # rotulo atual, sem buildar
sh scripts/build.sh            # carimbo (.build-info.json) + next build
sh scripts/check-versioning.sh # travas do padrao (rode antes do PR)
sh scripts/release.sh 0.1.5    # grava VERSION + package.json, commita, cria a tag anotada e empurra
sh scripts/release.sh --show   # versao, ultima tag, branch e sujeira
```

## Regra de release

1. Merge do PR em `main` (branch tipada + PR + squash; nunca commit direto no tronco).
2. `sh scripts/release.sh X.Y.Z`, e `git push origin vX.Y.Z` publica a imagem no GHCR.
3. Toda entrega que muda o que roda sobe com versao nova: correcao ⇒ patch,
   funcionalidade ⇒ minor, mudanca incompativel ⇒ major.
4. Depois do deploy: `curl -s <base>/api/version` deve devolver o `display` com o
   commit esperado e `modified: false`.

## Armadilhas

- **`.dockerignore` nao pode excluir `.git`**: e dele que sai o commit do carimbo.
  Sem `.git` no contexto o rotulo cai para `vX.Y.Z` e o commit vira `unknown`.
- **`.dockerignore` nao pode excluir arquivo rastreado**: o git dentro do container
  passa a ve-lo como apagado, o build se declara sujo e o rotulo ganha `*` falso.
- **`VERSION` e `package.json` nao podem divergir**: a trava reprova e quem acerta
  os dois e o `scripts/release.sh`.
- **Dev local sem build nao tem carimbo**: a resposta cai em `vX.Y.Z` (so o
  `VERSION`, commit `unknown`) — melhor do que um numero inventado.
