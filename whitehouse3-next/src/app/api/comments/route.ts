import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";

// GET /api/comments?activityId=123
export async function GET(request: NextRequest) {
  const activityId = request.nextUrl.searchParams.get("activityId");
  if (!activityId) {
    return NextResponse.json(
      { error: "activityId is required" },
      { status: 400 }
    );
  }

  const comments = await prisma.comment.findMany({
    where: {
      activityId: parseInt(activityId),
      status: "published",
    },
    orderBy: { createdAt: "asc" },
    include: {
      user: { select: { id: true, login: true } },
    },
  });

  return NextResponse.json({ comments });
}

// POST /api/comments - Create a comment on an activity
export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const body = await request.json();
  const { activityId, content } = body;

  if (!activityId || !content || content.trim().length === 0) {
    return NextResponse.json(
      { error: "activityId and content are required" },
      { status: 400 }
    );
  }

  // Verify activity exists
  const activity = await prisma.activity.findUnique({
    where: { id: activityId },
    include: { priority: { select: { id: true } } },
  });
  if (!activity) {
    return NextResponse.json(
      { error: "Activity not found" },
      { status: 404 }
    );
  }

  // Determine if user is endorser/opposer of the priority
  let isEndorser = false;
  let isOpposer = false;
  if (activity.priorityId) {
    const endorsement = await prisma.endorsement.findFirst({
      where: {
        userId,
        priorityId: activity.priorityId,
        status: "active",
      },
    });
    if (endorsement) {
      isEndorser = endorsement.value > 0;
      isOpposer = endorsement.value < 0;
    }
  }

  const comment = await prisma.comment.create({
    data: {
      activityId,
      userId,
      content: content.trim(),
      status: "published",
      isEndorser,
      isOpposer,
      ipAddress:
        request.headers.get("x-forwarded-for")?.split(",")[0] || null,
      userAgent: request.headers.get("user-agent") || null,
    },
    include: {
      user: { select: { id: true, login: true } },
    },
  });

  // Update activity comments count
  await prisma.activity.update({
    where: { id: activityId },
    data: {
      commentsCount: { increment: 1 },
      changedAt: new Date(),
    },
  });

  return NextResponse.json(comment, { status: 201 });
}
