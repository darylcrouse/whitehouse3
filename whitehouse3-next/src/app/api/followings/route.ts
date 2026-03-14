import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { otherUserId } = await request.json();

  if (!otherUserId || otherUserId === userId) {
    return NextResponse.json({ error: "Invalid user" }, { status: 400 });
  }

  // Check if already following
  const existing = await prisma.following.findFirst({
    where: { userId, otherUserId, value: 1 },
  });

  if (existing) {
    return NextResponse.json({ message: "Already following" });
  }

  await prisma.$transaction(async (tx) => {
    await tx.following.create({
      data: { userId, otherUserId, value: 1 },
    });

    await tx.user.update({
      where: { id: userId },
      data: { followingsCount: { increment: 1 } },
    });

    await tx.user.update({
      where: { id: otherUserId },
      data: { followersCount: { increment: 1 } },
    });

    // Create activity
    await tx.activity.create({
      data: {
        userId,
        type: "ActivityFollowingNew",
        status: "active",
        otherUserId,
        isUserOnly: false,
        commentsCount: 0,
        changedAt: new Date(),
      },
    });
  });

  return NextResponse.json({ success: true });
}

export async function DELETE(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { otherUserId } = await request.json();

  const existing = await prisma.following.findFirst({
    where: { userId, otherUserId, value: 1 },
  });

  if (!existing) {
    return NextResponse.json({ error: "Not following" }, { status: 400 });
  }

  await prisma.$transaction(async (tx) => {
    await tx.following.delete({ where: { id: existing.id } });

    await tx.user.update({
      where: { id: userId },
      data: { followingsCount: { decrement: 1 } },
    });

    await tx.user.update({
      where: { id: otherUserId },
      data: { followersCount: { decrement: 1 } },
    });

    await tx.activity.create({
      data: {
        userId,
        type: "ActivityFollowingDelete",
        status: "active",
        otherUserId,
        isUserOnly: false,
        commentsCount: 0,
        changedAt: new Date(),
      },
    });
  });

  return NextResponse.json({ success: true });
}
