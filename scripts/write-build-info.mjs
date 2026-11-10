// Escreve `.build-info.json` — o retrato do build que o servidor le em runtime
// (`src/lib/buildinfo.ts`). O arquivo e gerado, nao versionado: quem escreve e o
// build, sempre a partir do arquivo VERSION.
import { writeFileSync } from "node:fs";
import { computeLabel } from "../src/lib/version-label.mjs";

const label = computeLabel({
  version: process.env.APP_VERSION ?? "",
  commit: process.env.APP_COMMIT ?? "",
  modified: process.env.APP_MODIFIED === "true",
});

const info = {
  service: "claw3d",
  version: label.version,
  tag: `v${label.version}`,
  commit: label.commit,
  build_time: process.env.APP_BUILD_TIME ?? "",
  modified: label.modified,
  display: label.display,
  tags_url: "https://github.com/df4p/Claw3D/tags",
};

writeFileSync(".build-info.json", `${JSON.stringify(info, null, 2)}\n`);
console.log(`write-build-info: ${label.display} -> .build-info.json`);
