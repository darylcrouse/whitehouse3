import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";

// GET /api/priorities - List priorities with filtering and sorting
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const sort = searchParams.get("sort") || "top";
  const page = parseInt(searchParams.get("page") || "1");
  const perPage = 25;
  const skip = (page - 1) * perPage;

  let orderBy: Record<string, string> = {};
  let where: Record<string, unknown> = { status: "published" };

  switch (sort) {
    case "top":
      orderBy = { score: "desc" };
      break;
    case "rising":
      where = { ...where, trendingScore: { gt: 0 } };
      orderBy = { trendingScore: "desc" };
      break;
    case "falling":
      where = { ...where, trendingScore: { lt: 0 } };
      orderBy = { trendingScore: "asc" };
      break;
    case "controversial":
      where = { ...where, isControversial: true };
      orderBy = { controversialScore: "desc" };
      break;
    case "newest":
      orderBy = { publishedAt: "desc" };
      break;
    case "alphabetical":
      orderBy = { name: "asc" };
      break;
    default:
      orderBy = { position: "asc" };
  }

  const [priorities, total] = await Promise.all([
    prisma.priority.findMany({
      where,
      orderBy,
      skip,
      take: perPage,
      include: {
        user: { select: { id: true, login: true } },
      },
    }),
    prisma.priority.count({ where }),
  ]);

  return NextResponse.json({
    priorities,
    pagination: {
      page,
      perPage,
      total,
      totalPages: Math.ceil(total / perPage),
    },
  });
}

// POST /api/priorities - Create a new priority
export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { name } = body;

  if (!name || name.length < 3 || name.length > 60) {
    return NextResponse.json(
      { error: "Name must be between 3 and 60 characters" },
      { status: 400 }
    );
  }

  // Check uniqueness
  const existing = await prisma.priority.findUnique({ where: { name } });
  if (existing) {
    return NextResponse.json(
      { error: "A priority with that name already exists" },
      { status: 409 }
    );
  }

  const priority = await prisma.priority.create({
    data: {
      name,
      userId: parseInt(session.user.id),
      status: "published",
      publishedAt: new Date(),
    },
  });

  // Create activity
  await prisma.activity.create({
    data: {
      type: "ActivityPriorityNew",
      userId: parseInt(session.user.id),
      priorityId: priority.id,
    },
  });

  return NextResponse.json(priority, { status: 201 });
}
