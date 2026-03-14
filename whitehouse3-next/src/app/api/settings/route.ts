import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

export async function GET() {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      login: true,
      email: true,
      firstName: true,
      lastName: true,
      website: true,
      twitterLogin: true,
      isNewsSubscriber: true,
    },
  });

  const profile = await prisma.profile.findFirst({
    where: { userId },
    select: { bio: true },
  });

  return NextResponse.json({ user, profile });
}

export async function PUT(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const body = await request.json();
  const { firstName, lastName, email, website, twitterLogin, bio, isNewsSubscriber } = body;

  // Update user
  await prisma.user.update({
    where: { id: userId },
    data: {
      ...(firstName !== undefined && { firstName }),
      ...(lastName !== undefined && { lastName }),
      ...(email !== undefined && { email }),
      ...(website !== undefined && { website }),
      ...(twitterLogin !== undefined && { twitterLogin }),
      ...(isNewsSubscriber !== undefined && { isNewsSubscriber }),
    },
  });

  // Update or create profile
  if (bio !== undefined) {
    const existing = await prisma.profile.findFirst({ where: { userId } });
    if (existing) {
      await prisma.profile.update({
        where: { id: existing.id },
        data: { bio },
      });
    } else {
      await prisma.profile.create({
        data: { userId, bio },
      });
    }
  }

  return NextResponse.json({ success: true });
}
