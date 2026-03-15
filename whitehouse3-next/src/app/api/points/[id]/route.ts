import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: idParam } = await params;
  const id = parseInt(idParam);
  if (isNaN(id)) {
    return NextResponse.json({ error: "Invalid ID" }, { status: 400 });
  }

  const point = await prisma.point.findUnique({
    where: { id },
    include: {
      user: { select: { id: true, login: true } },
      priority: { select: { id: true, name: true } },
      revisions: {
        orderBy: { createdAt: "desc" },
        take: 10,
        include: { user: { select: { id: true, login: true } } },
      },
    },
  });

  if (!point || point.status !== "published") {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  return NextResponse.json(point);
}
