// GET /api/version — QUAL versao esta rodando, de qual commit e se o build saiu
// de arvore suja. Mesmo padrao do Hub df4p (`GET /api/v1/version`): o numero vem
// do build, nunca de um literal escrito aqui.
import { NextResponse } from "next/server";

import { readBuildInfo } from "@/lib/buildinfo";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json(readBuildInfo(), {
    headers: {
      "Cache-Control": "no-store",
    },
  });
}
