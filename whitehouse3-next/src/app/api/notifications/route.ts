import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const page = parseInt(request.nextUrl.searchParams.get("page") || "1");
  const perPage = 25;

  const [notifications, total, unreadCount] = await Promise.all([
    prisma.notification.findMany({
      where: { recipientId: userId, deletedAt: null },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        sender: { select: { id: true, login: true } },
        priority: { select: { id: true, name: true } },
      },
    }),
    prisma.notification.count({
      where: { recipientId: userId, deletedAt: null },
    }),
    prisma.notification.count({
      where: { recipientId: userId, deletedAt: null, readAt: null },
    }),
  ]);

  return NextResponse.json({ notifications, total, unreadCount });
}

export async function PUT(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { action, notificationId } = await request.json();

  if (action === "read_all") {
    await prisma.notification.updateMany({
      where: { recipientId: userId, readAt: null, deletedAt: null },
      data: { readAt: new Date() },
    });
    return NextResponse.json({ success: true });
  }

  if (action === "read" && notificationId) {
    await prisma.notification.updateMany({
      where: { id: notificationId, recipientId: userId },
      data: { readAt: new Date() },
    });
    return NextResponse.json({ success: true });
  }

  return NextResponse.json({ error: "Invalid action" }, { status: 400 });
}
