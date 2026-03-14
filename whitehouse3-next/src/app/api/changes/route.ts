import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const priorityId = parseInt(request.nextUrl.searchParams.get("priorityId") || "0");
  const page = parseInt(request.nextUrl.searchParams.get("page") || "1");
  const perPage = 25;

  if (!priorityId) {
    return NextResponse.json({ error: "priorityId required" }, { status: 400 });
  }

  const [changes, total] = await Promise.all([
    prisma.change.findMany({
      where: { priorityId, status: { in: ["active", "approved", "declined"] } },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        user: { select: { id: true, login: true } },
        newPriority: { select: { id: true, name: true } },
      },
    }),
    prisma.change.count({
      where: { priorityId, status: { in: ["active", "approved", "declined"] } },
    }),
  ]);

  return NextResponse.json({ changes, total });
}

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { priorityId, newPriorityId, content } = await request.json();

  if (!priorityId || !newPriorityId) {
    return NextResponse.json({ error: "priorityId and newPriorityId required" }, { status: 400 });
  }

  const change = await prisma.$transaction(async (tx) => {
    const c = await tx.change.create({
      data: {
        userId,
        priorityId,
        newPriorityId,
        content: content || "",
        status: "active",
        votesCount: 0,
      },
    });

    await tx.activity.create({
      data: {
        userId,
        type: "ActivityChangeNew",
        status: "active",
        priorityId,
        changeId: c.id,
        isUserOnly: false,
        commentsCount: 0,
        changedAt: new Date(),
      },
    });

    return c;
  });

  return NextResponse.json(change, { status: 201 });
}
