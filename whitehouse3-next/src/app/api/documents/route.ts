import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const priorityId = parseInt(request.nextUrl.searchParams.get("priorityId") || "0");
  const page = parseInt(request.nextUrl.searchParams.get("page") || "1");
  const perPage = 25;

  if (!priorityId) {
    return NextResponse.json({ error: "priorityId required" }, { status: 400 });
  }

  const [documents, total] = await Promise.all([
    prisma.document.findMany({
      where: { priorityId, status: "published" },
      orderBy: { score: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        user: { select: { id: true, login: true } },
      },
    }),
    prisma.document.count({ where: { priorityId, status: "published" } }),
  ]);

  return NextResponse.json({ documents, total });
}

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const userId = parseInt(session.user.id);
  const { priorityId, name, content } = await request.json();

  if (!priorityId || !name?.trim()) {
    return NextResponse.json({ error: "priorityId and name required" }, { status: 400 });
  }

  const document = await prisma.$transaction(async (tx) => {
    const doc = await tx.document.create({
      data: {
        userId,
        priorityId,
        name: name.trim(),
        content: content || "",
        status: "published",
        score: 0,
        helpfulCount: 0,
        unhelpfulCount: 0,
        neutralCount: 0,
        revisionsCount: 1,
        commentsCount: 0,
      },
    });

    await tx.documentRevision.create({
      data: {
        documentId: doc.id,
        userId,
        content: content || "",
        value: 0,
        status: "published",
        ipAddress: "",
      },
    });

    // Create activity
    await tx.activity.create({
      data: {
        userId,
        type: "ActivityDocumentNew",
        status: "active",
        priorityId,
        documentId: doc.id,
        isUserOnly: false,
        commentsCount: 0,
        changedAt: new Date(),
      },
    });

    return doc;
  });

  return NextResponse.json(document, { status: 201 });
}
