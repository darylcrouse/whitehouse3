import { auth } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await auth();
  if (!session?.user?.id) redirect("/login");

  const userId = parseInt(session.user.id);
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { isAdmin: true },
  });

  if (!user?.isAdmin) redirect("/");

  const navItems = [
    { label: "Dashboard", href: "/admin" },
    { label: "Users", href: "/admin/users" },
    { label: "Tags", href: "/admin/tags" },
  ];

  return (
    <div>
      <div className="bg-gray-800 text-white px-4 py-2 flex items-center gap-6 text-sm">
        <span className="font-bold">Admin</span>
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="hover:text-blue-300 transition-colors"
          >
            {item.label}
          </Link>
        ))}
        <Link href="/" className="ml-auto hover:text-blue-300">
          Back to Site
        </Link>
      </div>
      <div className="p-6">{children}</div>
    </div>
  );
}
