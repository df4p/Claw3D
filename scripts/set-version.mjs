// Grava a versao nova no VERSION e espelha em package.json.
//
// O VERSION e a fonte unica; o campo `version` do package.json e metadado npm e
// precisa contar a mesma historia (o `scripts/check-versioning.sh` reprova se
// divergirem). A troca e por regex de proposito: `JSON.parse`+`stringify`
// reformataria o arquivo inteiro e o diff viraria ruido.
import { readFileSync, writeFileSync } from "node:fs";

const version = (process.argv[2] ?? "").trim();
if (!/^\d+\.\d+\.\d+$/.test(version)) {
  console.error(`set-version: versao invalida '${version}' — use X.Y.Z`);
  process.exit(1);
}

writeFileSync("VERSION", `${version}\n`);

const raw = readFileSync("package.json", "utf8");
const pattern = /("version"\s*:\s*")[^"]*(")/;
if (!pattern.test(raw)) {
  console.error("set-version: campo version nao encontrado em package.json");
  process.exit(1);
}
writeFileSync("package.json", raw.replace(pattern, `$1${version}$2`));
console.log(`set-version: VERSION e package.json em ${version}`);
