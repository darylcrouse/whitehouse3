import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// GET /api/activities - Activity feed / news
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const page = parseInt(searchParams.get("page") || "1");
  const filter = searchParams.get("filter") || "all";
  const userId = searchParams.get("userId");
  const priorityId = searchParams.get("priorityId");
  const perPage = 25;
  const skip = (page - 1) * perPage;

  const where: Record<string, unknown> = {
    status: "active",
    isUserOnly: false,
  };

  if (userId) where.userId = parseInt(userId);
  if (priorityId) where.priorityId = parseInt(priorityId);

  switch (filter) {
    case "discussions":
      where.commentsCount = { gt: 0 };
      break;
    case "points":
      where.type = { startsWith: "ActivityPoint" };
      break;
    case "changes":
      where.changeId = { not: null };
      break;
  }

  const [activities, total] = await Promise.all([
    prisma.activity.findMany({
      where,
      orderBy: { changedAt: "desc" },
      skip,
      take: perPage,
      include: {
        user: { select: { id: true, login: true } },
        priority: { select: { id: true, name: true } },
        point: { select: { id: true, name: true } },
        document: { select: { id: true, name: true } },
        comments: {
          where: { status: "published" },
          take: 3,
          orderBy: { createdAt: "asc" },
          include: { user: { select: { id: true, login: true } } },
        },
      },
    }),
    prisma.activity.count({ where }),
  ]);

  return NextResponse.json({
    activities,
    pagination: { page, perPage, total, totalPages: Math.ceil(total / perPage) },
  });
}
