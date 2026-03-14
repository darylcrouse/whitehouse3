import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: idParam } = await params;
  const id = parseInt(idParam);
  if (isNaN(id)) {
    return NextResponse.json({ error: "Invalid user ID" }, { status: 400 });
  }

  const user = await prisma.user.findUnique({
    where: { id, status: { in: ["active", "pending"] } },
    select: {
      id: true,
      login: true,
      firstName: true,
      lastName: true,
      endorsementsCount: true,
      commentsCount: true,
      capitalsCount: true,
      pointsCount: true,
      position: true,
      score: true,
      followersCount: true,
      followingsCount: true,
      createdAt: true,
      loggedinAt: true,
      website: true,
      twitterLogin: true,
    },
  });

  if (!user) {
    return NextResponse.json({ error: "User not found" }, { status: 404 });
  }

  // Fetch profile bio
  const profile = await prisma.profile.findFirst({
    where: { userId: id },
    select: { bio: true, bioHtml: true },
  });

  return NextResponse.json({ ...user, profile });
}
