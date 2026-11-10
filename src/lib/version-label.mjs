// Rotulo de versao do Claw3D: `vX.Y.Z+<commit>`, com `*` no fim quando a arvore
// esta suja. Sem git, o commit e `unknown` e o rotulo perde o sufixo — nunca um
// sha chutado: um rotulo que mente e pior do que um rotulo que admite nao saber.
//
// Modulo PURO (sem IO) de proposito: e ele que o teste unitario exercita e o
// `scripts/build.sh` consome o mesmo arquivo pela linha de comando, entao nao
// existe uma segunda implementacao do rotulo para divergir.
//
//   node src/lib/version-label.mjs 0.1.4 142db95 false
//   -> {"version":"0.1.4","commit":"142db95","modified":false,"display":"v0.1.4+142db95"}

/**
 * @param {{ version: string, commit?: string, modified?: boolean }} input
 * @returns {{ version: string, commit: string, modified: boolean, display: string }}
 */
export function computeLabel({ version, commit = "", modified = false }) {
  const v = String(version ?? "").trim();
  const c = String(commit ?? "").trim();
  if (!v) {
    throw new Error("computeLabel: version vazia");
  }
  if (!c || c === "unknown") {
    return { version: v, commit: "unknown", modified: false, display: `v${v}` };
  }
  const dirty = Boolean(modified);
  return { version: v, commit: c, modified: dirty, display: `v${v}+${c}${dirty ? "*" : ""}` };
}

// Executado direto pela linha de comando (o build consome o JSON).
if (process.argv[1] && process.argv[1].endsWith("version-label.mjs")) {
  const [, , version, commit, modified] = process.argv;
  process.stdout.write(JSON.stringify(computeLabel({ version, commit, modified: modified === "true" })));
}
