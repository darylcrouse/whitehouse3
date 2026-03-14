import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const q = request.nextUrl.searchParams.get("q");
  const type = request.nextUrl.searchParams.get("type") || "priorities";
  const page = parseInt(request.nextUrl.searchParams.get("page") || "1");
  const perPage = 25;

  if (!q || q.trim().length < 2) {
    return NextResponse.json({ results: [], total: 0 });
  }

  const query = `%${q}%`;

  if (type === "priorities") {
    const [results, total] = await Promise.all([
      prisma.priority.findMany({
        where: {
          status: "published",
          name: { contains: q, mode: "insensitive" },
        },
        orderBy: { score: "desc" },
        skip: (page - 1) * perPage,
        take: perPage,
        select: {
          id: true,
          name: true,
          position: true,
          endorsementsCount: true,
          upEndorsementsCount: true,
          downEndorsementsCount: true,
          user: { select: { id: true, login: true } },
        },
      }),
      prisma.priority.count({
        where: {
          status: "published",
          name: { contains: q, mode: "insensitive" },
        },
      }),
    ]);
    return NextResponse.json({ results, total });
  }

  if (type === "users") {
    const [results, total] = await Promise.all([
      prisma.user.findMany({
        where: {
          status: { in: ["active", "pending"] },
          login: { contains: q, mode: "insensitive" },
        },
        orderBy: { score: "desc" },
        skip: (page - 1) * perPage,
        take: perPage,
        select: {
          id: true,
          login: true,
          endorsementsCount: true,
          position: true,
          followersCount: true,
        },
      }),
      prisma.user.count({
        where: {
          status: { in: ["active", "pending"] },
          login: { contains: q, mode: "insensitive" },
        },
      }),
    ]);
    return NextResponse.json({ results, total });
  }

  if (type === "points") {
    const [results, total] = await Promise.all([
      prisma.point.findMany({
        where: {
          status: "published",
          name: { contains: q, mode: "insensitive" },
        },
        orderBy: { score: "desc" },
        skip: (page - 1) * perPage,
        take: perPage,
        select: {
          id: true,
          name: true,
          value: true,
          user: { select: { id: true, login: true } },
          priority: { select: { id: true, name: true } },
        },
      }),
      prisma.point.count({
        where: {
          status: "published",
          name: { contains: q, mode: "insensitive" },
        },
      }),
    ]);
    return NextResponse.json({ results, total });
  }

  return NextResponse.json({ results: [], total: 0 });
}
