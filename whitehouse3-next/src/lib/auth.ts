import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";
import { prisma } from "./prisma";
import { createHash } from "crypto";

function encrypt(password: string, salt: string): string {
  return createHash("sha1").update(`--${salt}--${password}--`).digest("hex");
}

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Credentials({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null;

        const user = await prisma.user.findFirst({
          where: {
            email: credentials.email as string,
            status: { in: ["active", "pending"] },
          },
        });

        if (!user || !user.salt || !user.cryptedPassword) return null;

        const hashedPassword = encrypt(
          credentials.password as string,
          user.salt
        );
        if (hashedPassword !== user.cryptedPassword) return null;

        return {
          id: String(user.id),
          email: user.email,
          name: user.login,
        };
      },
    }),
  ],
  callbacks: {
    async session({ session, token }) {
      if (token?.sub) {
        session.user.id = token.sub;
      }
      return session;
    },
    async jwt({ token, user }) {
      if (user) {
        token.sub = user.id;
      }
      return token;
    },
  },
  pages: {
    signIn: "/login",
  },
});
