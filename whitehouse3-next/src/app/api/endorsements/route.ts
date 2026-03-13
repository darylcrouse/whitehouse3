import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";

// POST /api/endorsements - Endorse or oppose a priority
export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const body = await request.json();
  const { priorityId, value } = body;

  if (!priorityId || (value !== 1 && value !== -1)) {
    return NextResponse.json(
      { error: "priorityId and value (1 or -1) are required" },
      { status: 400 }
    );
  }

  // Check priority exists and is published
  const priority = await prisma.priority.findFirst({
    where: { id: priorityId, status: "published" },
  });
  if (!priority) {
    return NextResponse.json(
      { error: "Priority not found" },
      { status: 404 }
    );
  }

  // Check for existing endorsement
  const existing = await prisma.endorsement.findFirst({
    where: { userId, priorityId, status: { in: ["active", "inactive"] } },
  });

  if (existing) {
    if (existing.value === value) {
      return NextResponse.json(existing);
    }
    // Flip the endorsement
    const updated = await prisma.endorsement.update({
      where: { id: existing.id },
      data: { value },
    });
    return NextResponse.json(updated);
  }

  // Get user's current active endorsement count for position
  const activeCount = await prisma.endorsement.count({
    where: { userId, status: "active" },
  });

  const endorsement = await prisma.endorsement.create({
    data: {
      userId,
      priorityId,
      value,
      status: "active",
      position: activeCount + 1,
      ipAddress: request.headers.get("x-forwarded-for")?.split(",")[0] || null,
    },
  });

  // Update priority counts
  const updateData =
    value === 1
      ? {
          endorsementsCount: { increment: 1 },
          upEndorsementsCount: { increment: 1 },
        }
      : {
          endorsementsCount: { increment: 1 },
          downEndorsementsCount: { increment: 1 },
        };

  await prisma.priority.update({
    where: { id: priorityId },
    data: updateData,
  });

  // Update user counts
  const userUpdate =
    value === 1
      ? {
          endorsementsCount: { increment: 1 },
          upEndorsementsCount: { increment: 1 },
        }
      : {
          endorsementsCount: { increment: 1 },
          downEndorsementsCount: { increment: 1 },
        };

  await prisma.user.update({
    where: { id: userId },
    data: userUpdate,
  });

  // Create activity
  await prisma.activity.create({
    data: {
      type: value === 1 ? "ActivityEndorsementNew" : "ActivityOppositionNew",
      userId,
      priorityId,
      position: endorsement.position,
    },
  });

  return NextResponse.json(endorsement, { status: 201 });
}

// DELETE /api/endorsements - Remove an endorsement
export async function DELETE(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const body = await request.json();
  const { priorityId } = body;

  const endorsement = await prisma.endorsement.findFirst({
    where: { userId, priorityId, status: "active" },
  });

  if (!endorsement) {
    return NextResponse.json(
      { error: "Endorsement not found" },
      { status: 404 }
    );
  }

  // Delete the endorsement
  await prisma.endorsement.delete({ where: { id: endorsement.id } });

  // Update counts
  const priorityUpdate =
    endorsement.value === 1
      ? {
          endorsementsCount: { decrement: 1 },
          upEndorsementsCount: { decrement: 1 },
        }
      : {
          endorsementsCount: { decrement: 1 },
          downEndorsementsCount: { decrement: 1 },
        };

  await prisma.priority.update({
    where: { id: priorityId },
    data: priorityUpdate,
  });

  // Create activity
  await prisma.activity.create({
    data: {
      type:
        endorsement.value === 1
          ? "ActivityEndorsementDelete"
          : "ActivityOppositionDelete",
      userId,
      priorityId,
    },
  });

  return NextResponse.json({ success: true });
}
