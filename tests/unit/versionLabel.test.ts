// @vitest-environment node

import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";

import { describe, expect, it } from "vitest";

import { computeLabel } from "../../src/lib/version-label.mjs";
import { readBuildInfo } from "../../src/lib/buildinfo";

function dirWith(files: Record<string, string>): string {
  const dir = mkdtempSync(path.join(tmpdir(), "claw3d-buildinfo-"));
  for (const [name, content] of Object.entries(files)) {
    writeFileSync(path.join(dir, name), content);
  }
  return dir;
}

describe("computeLabel", () => {
  it("junta versao e commit", () => {
    expect(computeLabel({ version: "0.1.4", commit: "142db95" }).display).toBe("v0.1.4+142db95");
  });

  it("marca arvore suja com asterisco", () => {
    expect(computeLabel({ version: "0.1.4", commit: "142db95", modified: true }).display).toBe(
      "v0.1.4+142db95*",
    );
  });

  it("sem git perde o sufixo e admite unknown", () => {
    const label = computeLabel({ version: "0.1.4", commit: "unknown" });
    expect(label.display).toBe("v0.1.4");
    expect(label.commit).toBe("unknown");
    expect(label.modified).toBe(false);
  });

  it("recusa versao vazia em vez de inventar", () => {
    expect(() => computeLabel({ version: "" })).toThrow();
  });
});

describe("readBuildInfo", () => {
  it("le o carimbo do build", () => {
    const dir = dirWith({
      ".build-info.json": JSON.stringify({
        service: "claw3d",
        version: "0.1.4",
        tag: "v0.1.4",
        commit: "142db95",
        build_time: "2026-11-10T00:00:00Z",
        modified: false,
        display: "v0.1.4+142db95",
        tags_url: "https://example.invalid/tags",
      }),
    });
    const info = readBuildInfo(dir);
    expect(info.display).toBe("v0.1.4+142db95");
    expect(info.modified).toBe(false);
  });

  it("sem carimbo, cai no VERSION com commit unknown", () => {
    const info = readBuildInfo(dirWith({ VERSION: "0.1.4\n" }));
    expect(info.display).toBe("v0.1.4");
    expect(info.commit).toBe("unknown");
  });

  it("carimbo ilegivel nao vira palpite", () => {
    const info = readBuildInfo(dirWith({ ".build-info.json": "{ nao e json", VERSION: "0.1.4" }));
    expect(info.display).toBe("v0.1.4");
  });

  it("sem nada, diz que nao sabe", () => {
    const info = readBuildInfo(dirWith({}));
    expect(info.display).toBe("v0.0.0-dev");
    expect(info.commit).toBe("unknown");
  });
});
