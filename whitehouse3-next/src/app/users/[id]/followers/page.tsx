import { prisma } from "@/lib/prisma";
import { notFound } from "next/navigation";
import Link from "next/link";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ page?: string }>;
}

export default async function UserFollowersPage({ params, searchParams }: Props) {
  const { id: idParam } = await params;
  const sp = await searchParams;
  const id = parseInt(idParam);
  if (isNaN(id)) notFound();

  const page = parseInt(sp.page || "1");
  const perPage = 50;

  const user = await prisma.user.findUnique({
    where: { id, status: { in: ["active", "pending"] } },
    select: { id: true, login: true, followersCount: true, followingsCount: true },
  });
  if (!user) notFound();

  const [followings, total] = await Promise.all([
    prisma.following.findMany({
      where: { otherUserId: id, value: 1 },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        user: {
          select: {
            id: true,
            login: true,
            endorsementsCount: true,
            position: true,
            createdAt: true,
          },
        },
      },
    }),
    prisma.following.count({ where: { otherUserId: id, value: 1 } }),
  ]);

  const totalPages = Math.ceil(total / perPage);

  const navTabs = [
    { label: "Priorities", href: `/users/${id}` },
    { label: "Activities", href: `/users/${id}/activities` },
    { label: `Followers (${user.followersCount})`, href: `/users/${id}/followers`, active: true },
    { label: `Following (${user.followingsCount})`, href: `/users/${id}/following` },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">{user.login}&apos;s Followers</h1>

      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        {navTabs.map((tab) => (
          <Link
            key={tab.href}
            href={tab.href}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              tab.active
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            {tab.label}
          </Link>
        ))}
      </div>

      <div className="grid gap-3 md:grid-cols-2">
        {followings.map((f) => (
          <Link
            key={f.id}
            href={`/users/${f.user.id}`}
            className="bg-white rounded-lg border border-gray-200 p-4 flex items-center gap-3 hover:border-blue-300 transition-colors"
          >
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-sm font-bold text-blue-600">
              {f.user.login.charAt(0).toUpperCase()}
            </div>
            <div>
              <div className="font-medium text-gray-900">{f.user.login}</div>
              <div className="text-xs text-gray-500">
                {f.user.endorsementsCount} endorsements
                {f.user.position > 0 && ` · Rank #${f.user.position}`}
              </div>
            </div>
          </Link>
        ))}
      </div>

      {followings.length === 0 && (
        <p className="text-sm text-gray-500">No followers yet.</p>
      )}

      <Pagination page={page} totalPages={totalPages} baseUrl={`/users/${id}/followers`} />
    </div>
  );
}
