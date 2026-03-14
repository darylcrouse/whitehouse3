import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { pointId, value } = await request.json();

  if (!pointId || ![1, -1].includes(value)) {
    return NextResponse.json({ error: "pointId and value (1 or -1) required" }, { status: 400 });
  }

  // Check for existing vote
  const existing = await prisma.pointQuality.findFirst({
    where: { pointId, userId },
  });

  if (existing) {
    if (existing.value === value) {
      return NextResponse.json({ message: "Already voted" });
    }

    // Flip the vote
    await prisma.$transaction(async (tx) => {
      await tx.pointQuality.update({
        where: { id: existing.id },
        data: { value },
      });

      const increment = value === 1
        ? { helpfulCount: { increment: 1 }, unhelpfulCount: { decrement: 1 } }
        : { helpfulCount: { decrement: 1 }, unhelpfulCount: { increment: 1 } };

      await tx.point.update({
        where: { id: pointId },
        data: increment,
      });
    });

    return NextResponse.json({ success: true, flipped: true });
  }

  // New vote
  await prisma.$transaction(async (tx) => {
    await tx.pointQuality.create({
      data: { pointId, userId, value },
    });

    const increment = value === 1
      ? { helpfulCount: { increment: 1 } }
      : { unhelpfulCount: { increment: 1 } };

    await tx.point.update({
      where: { id: pointId },
      data: increment,
    });
  });

  return NextResponse.json({ success: true });
}
