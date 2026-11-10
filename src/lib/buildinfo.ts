// Le o retrato do build que esta rodando.
//
// O carimbo (`.build-info.json`) e escrito por `scripts/build.sh` a partir do
// arquivo VERSION e entra na imagem com o contexto de build; quando ele nao
// existe — dev local sem build — sobra o `VERSION` e o commit fica `unknown`,
// honesto. Nao existe numero de versao escrito a mao aqui: se nao der para
// saber, a resposta diz `0.0.0-dev`, nao um palpite.
import { readFileSync } from "node:fs";
import path from "node:path";

import { computeLabel } from "./version-label.mjs";

export type BuildInfo = {
  service: string;
  version: string;
  tag: string;
  commit: string;
  build_time: string;
  modified: boolean;
  display: string;
  tags_url: string;
};

export const TAGS_URL = "https://github.com/df4p/Claw3D/tags";
const DEV_VERSION = "0.0.0-dev";
const COMMIT_UNKNOWN = "unknown";

function readText(file: string): string | null {
  try {
    return readFileSync(file, "utf8");
  } catch {
    return null;
  }
}

function base(info: Partial<BuildInfo>): BuildInfo {
  return {
    service: "claw3d",
    version: DEV_VERSION,
    tag: "",
    commit: COMMIT_UNKNOWN,
    build_time: "",
    modified: false,
    display: `v${DEV_VERSION}`,
    tags_url: TAGS_URL,
    ...info,
  };
}

export function readBuildInfo(cwd: string = process.cwd()): BuildInfo {
  const raw = readText(path.join(cwd, ".build-info.json"));
  if (raw) {
    try {
      const parsed = JSON.parse(raw) as Partial<BuildInfo>;
      if (parsed.version && parsed.display) {
        return base(parsed);
      }
    } catch {
      // carimbo ilegivel: cai para o VERSION abaixo, sem inventar valor
    }
  }

  const version = (readText(path.join(cwd, "VERSION")) ?? "").trim();
  if (!/^\d+\.\d+\.\d+$/.test(version)) {
    return base({});
  }
  const label = computeLabel({ version, commit: COMMIT_UNKNOWN });
  return base({ version: label.version, tag: `v${label.version}`, display: label.display });
}
