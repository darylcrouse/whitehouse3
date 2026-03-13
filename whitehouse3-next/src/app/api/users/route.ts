import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { createHash } from "crypto";

// POST /api/users - Register a new user
export async function POST(request: NextRequest) {
  const body = await request.json();
  const { login, email, password, passwordConfirmation } = body;

  // Validate login
  if (!login || login.length < 3 || login.length > 40) {
    return NextResponse.json(
      { error: "Login must be between 3 and 40 characters" },
      { status: 400 }
    );
  }

  // Validate email
  if (!email || email.length < 3 || email.length > 100) {
    return NextResponse.json(
      { error: "Valid email is required" },
      { status: 400 }
    );
  }

  // Validate password
  if (!password || password.length < 4 || password.length > 40) {
    return NextResponse.json(
      { error: "Password must be between 4 and 40 characters" },
      { status: 400 }
    );
  }

  if (password !== passwordConfirmation) {
    return NextResponse.json(
      { error: "Password and confirmation do not match" },
      { status: 400 }
    );
  }

  // Check uniqueness
  const existingLogin = await prisma.user.findUnique({ where: { login } });
  if (existingLogin) {
    return NextResponse.json(
      { error: "Login is already taken" },
      { status: 409 }
    );
  }

  const existingEmail = await prisma.user.findUnique({ where: { email } });
  if (existingEmail) {
    return NextResponse.json(
      { error: "Email is already registered" },
      { status: 409 }
    );
  }

  // Create salt and hash password (matching Rails SHA1 format)
  const salt = createHash("sha1")
    .update(`--${Date.now()}--${login}--`)
    .digest("hex");
  const cryptedPassword = createHash("sha1")
    .update(`--${salt}--${password}--`)
    .digest("hex");

  // Generate activation code
  const activationCode = createHash("sha1")
    .update(
      Date.now().toString().split("").sort(() => Math.random() - 0.5).join("")
    )
    .digest("hex");

  // Generate RSS code
  const rssCode = createHash("sha1")
    .update(
      Date.now().toString().split("").sort(() => Math.random() - 0.5).join("")
    )
    .digest("hex");

  const user = await prisma.user.create({
    data: {
      login,
      email,
      cryptedPassword,
      salt,
      activationCode,
      rssCode,
      status: "pending",
      ipAddress:
        request.headers.get("x-forwarded-for")?.split(",")[0] || null,
      userAgent: request.headers.get("user-agent") || null,
      referrer: request.headers.get("referer") || null,
    },
    select: {
      id: true,
      login: true,
      email: true,
      status: true,
      createdAt: true,
    },
  });

  // Create activity
  await prisma.activity.create({
    data: {
      type: "ActivityUserNew",
      userId: user.id,
    },
  });

  return NextResponse.json(user, { status: 201 });
}
