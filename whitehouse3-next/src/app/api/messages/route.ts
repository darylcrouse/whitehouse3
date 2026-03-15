import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const folder = request.nextUrl.searchParams.get("folder") || "inbox";
  const page = parseInt(request.nextUrl.searchParams.get("page") || "1");
  const perPage = 25;

  const where = folder === "sent"
    ? { senderId: userId, deletedAt: null }
    : { recipientId: userId, deletedAt: null };

  const [messages, total, unreadCount] = await Promise.all([
    prisma.message.findMany({
      where,
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        sender: { select: { id: true, login: true } },
        recipient: { select: { id: true, login: true } },
      },
    }),
    prisma.message.count({ where }),
    prisma.message.count({
      where: { recipientId: userId, deletedAt: null, readAt: null },
    }),
  ]);

  return NextResponse.json({ messages, total, unreadCount });
}

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const senderId = parseInt(session.user.id);
  const { recipientId, title, content } = await request.json();

  if (!recipientId || !title?.trim()) {
    return NextResponse.json({ error: "Recipient and title required" }, { status: 400 });
  }

  const recipient = await prisma.user.findFirst({
    where: { id: recipientId, status: { in: ["active", "pending"] } },
  });
  if (!recipient) {
    return NextResponse.json({ error: "Recipient not found" }, { status: 404 });
  }

  const message = await prisma.message.create({
    data: {
      senderId,
      recipientId,
      title: title.trim(),
      content: content || "",
      status: "sent",
      sentAt: new Date(),
    },
  });

  return NextResponse.json(message, { status: 201 });
}
