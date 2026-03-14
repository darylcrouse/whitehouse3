import { prisma } from "@/lib/prisma";
import Link from "next/link";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  searchParams: Promise<{ page?: string; sort?: string }>;
}

export default async function NetworkPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1");
  const sort = params.sort || "top";
  const perPage = 50;

  const orderBy: Record<string, unknown> = sort === "newest"
    ? { createdAt: "desc" as const }
    : sort === "active"
      ? { loggedinAt: "desc" as const }
      : { position: "asc" as const };

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where: { status: "active", position: sort === "top" ? { gt: 0 } : undefined },
      orderBy,
      skip: (page - 1) * perPage,
      take: perPage,
      select: {
        id: true,
        login: true,
        endorsementsCount: true,
        pointsCount: true,
        position: true,
        followersCount: true,
        createdAt: true,
        loggedinAt: true,
      },
    }),
    prisma.user.count({
      where: { status: "active", position: sort === "top" ? { gt: 0 } : undefined },
    }),
  ]);

  const totalPages = Math.ceil(total / perPage);
  const sortTabs = [
    { key: "top", label: "Top Ranked" },
    { key: "active", label: "Most Active" },
    { key: "newest", label: "Newest" },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">People</h1>

      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        {sortTabs.map((tab) => (
          <Link
            key={tab.key}
            href={`/network?sort=${tab.key}`}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              sort === tab.key
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            {tab.label}
          </Link>
        ))}
      </div>

      <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
        {users.map((user) => (
          <Link
            key={user.id}
            href={`/users/${user.id}`}
            className="bg-white rounded-lg border border-gray-200 p-4 hover:border-blue-300 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-sm font-bold text-blue-600">
                {user.login.charAt(0).toUpperCase()}
              </div>
              <div className="min-w-0">
                <div className="font-medium text-gray-900 truncate">{user.login}</div>
                <div className="text-xs text-gray-500">
                  {user.position > 0 && `#${user.position} · `}
                  {user.endorsementsCount} endorsements · {user.followersCount} followers
                </div>
              </div>
            </div>
          </Link>
        ))}
      </div>

      {users.length === 0 && (
        <p className="text-center py-8 text-gray-500">No users found.</p>
      )}

      <Pagination page={page} totalPages={totalPages} baseUrl={`/network?sort=${sort}`} />
    </div>
  );
}
