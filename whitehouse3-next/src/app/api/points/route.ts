import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";

// GET /api/points - List points for a priority
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const priorityId = searchParams.get("priorityId");
  const sort = searchParams.get("sort") || "helpfulness";
  const page = parseInt(searchParams.get("page") || "1");
  const perPage = 15;
  const skip = (page - 1) * perPage;

  const where: Record<string, unknown> = { status: "published" };
  if (priorityId) where.priorityId = parseInt(priorityId);

  let orderBy: Record<string, string> = {};
  switch (sort) {
    case "helpfulness":
      orderBy = { score: "desc" };
      break;
    case "newest":
      orderBy = { createdAt: "desc" };
      break;
    case "endorser":
      orderBy = { endorserScore: "desc" };
      break;
    case "opposer":
      orderBy = { opposerScore: "desc" };
      break;
    default:
      orderBy = { score: "desc" };
  }

  const [points, total] = await Promise.all([
    prisma.point.findMany({
      where,
      orderBy,
      skip,
      take: perPage,
      include: {
        user: { select: { id: true, login: true } },
        priority: { select: { id: true, name: true } },
      },
    }),
    prisma.point.count({ where }),
  ]);

  return NextResponse.json({
    points,
    pagination: { page, perPage, total, totalPages: Math.ceil(total / perPage) },
  });
}

// POST /api/points - Create a new point (argument for/against a priority)
export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const body = await request.json();
  const { name, content, priorityId, value, website } = body;

  if (!name || name.length < 3 || name.length > 60) {
    return NextResponse.json(
      { error: "Name must be between 3 and 60 characters" },
      { status: 400 }
    );
  }

  if (content && content.length > 516) {
    return NextResponse.json(
      { error: "Content must be 500 characters or less" },
      { status: 400 }
    );
  }

  if (!priorityId || (value !== 1 && value !== -1 && value !== 0)) {
    return NextResponse.json(
      { error: "priorityId and value (1, 0, or -1) are required" },
      { status: 400 }
    );
  }

  const point = await prisma.point.create({
    data: {
      name,
      content: content || null,
      userId,
      priorityId,
      value,
      website: website || null,
      status: "published",
      publishedAt: new Date(),
    },
  });

  // Create initial revision
  await prisma.revision.create({
    data: {
      pointId: point.id,
      userId,
      value,
      name,
      content: content || null,
      website: website || null,
      status: "published",
      publishedAt: new Date(),
    },
  });

  // Update priority point counts
  const countField =
    value === 1
      ? "upPointsCount"
      : value === -1
        ? "downPointsCount"
        : "neutralPointsCount";

  await prisma.priority.update({
    where: { id: priorityId },
    data: {
      pointsCount: { increment: 1 },
      [countField]: { increment: 1 },
    },
  });

  // Create activity
  await prisma.activity.create({
    data: {
      type: "ActivityPointNew",
      userId,
      priorityId,
      pointId: point.id,
    },
  });

  return NextResponse.json(point, { status: 201 });
}
