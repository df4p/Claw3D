import { NextResponse } from "next/server";

import { readBuildInfo } from "@/lib/buildinfo";

export const runtime = "nodejs";

export async function GET() {
  // Versao do build em curso: mesmo carimbo que o GET /api/version responde.
  // Aditivo de proposito — quem ja consome `ok`/`service` segue funcionando.
  const build = readBuildInfo();

  return NextResponse.json(
    {
      ok: true,
      service: "claw3d",
      version: build.version,
      display: build.display,
      commit: build.commit,
      modified: build.modified,
      build_time: build.build_time,
    },
    {
      headers: {
        "Cache-Control": "no-store",
      },
    },
  );
}
