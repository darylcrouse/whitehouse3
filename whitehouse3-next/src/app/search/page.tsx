import { prisma } from "@/lib/prisma";
import Link from "next/link";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  searchParams: Promise<{ q?: string; type?: string; page?: string }>;
}

export default async function SearchPage({ searchParams }: Props) {
  const params = await searchParams;
  const q = params.q || "";
  const type = params.type || "priorities";
  const page = parseInt(params.page || "1");
  const perPage = 25;

  const typeTabs = [
    { key: "priorities", label: "Priorities" },
    { key: "users", label: "People" },
    { key: "points", label: "Points" },
  ];

  let results: Array<Record<string, unknown>> = [];
  let total = 0;

  if (q.trim().length >= 2) {
    if (type === "priorities") {
      [results, total] = await Promise.all([
        prisma.priority.findMany({
          where: { status: "published", name: { contains: q, mode: "insensitive" } },
          orderBy: { score: "desc" },
          skip: (page - 1) * perPage,
          take: perPage,
          select: {
            id: true, name: true, position: true,
            endorsementsCount: true, upEndorsementsCount: true, downEndorsementsCount: true,
            user: { select: { id: true, login: true } },
          },
        }) as Promise<Array<Record<string, unknown>>>,
        prisma.priority.count({
          where: { status: "published", name: { contains: q, mode: "insensitive" } },
        }),
      ]);
    } else if (type === "users") {
      [results, total] = await Promise.all([
        prisma.user.findMany({
          where: { status: { in: ["active", "pending"] }, login: { contains: q, mode: "insensitive" } },
          orderBy: { score: "desc" },
          skip: (page - 1) * perPage,
          take: perPage,
          select: { id: true, login: true, endorsementsCount: true, position: true, followersCount: true },
        }) as Promise<Array<Record<string, unknown>>>,
        prisma.user.count({
          where: { status: { in: ["active", "pending"] }, login: { contains: q, mode: "insensitive" } },
        }),
      ]);
    } else if (type === "points") {
      [results, total] = await Promise.all([
        prisma.point.findMany({
          where: { status: "published", name: { contains: q, mode: "insensitive" } },
          orderBy: { score: "desc" },
          skip: (page - 1) * perPage,
          take: perPage,
          select: {
            id: true, name: true, value: true,
            user: { select: { id: true, login: true } },
            priority: { select: { id: true, name: true } },
          },
        }) as Promise<Array<Record<string, unknown>>>,
        prisma.point.count({
          where: { status: "published", name: { contains: q, mode: "insensitive" } },
        }),
      ]);
    }
  }

  const totalPages = Math.ceil(total / perPage);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Search</h1>

      {/* Search form */}
      <form action="/search" method="GET" className="flex gap-2">
        <input type="hidden" name="type" value={type} />
        <input
          name="q"
          defaultValue={q}
          placeholder="Search..."
          className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
        />
        <button
          type="submit"
          className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
        >
          Search
        </button>
      </form>

      {/* Type tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        {typeTabs.map((tab) => (
          <Link
            key={tab.key}
            href={`/search?q=${encodeURIComponent(q)}&type=${tab.key}`}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              type === tab.key
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            {tab.label}
          </Link>
        ))}
      </div>

      {/* Results */}
      {q.trim().length < 2 ? (
        <p className="text-sm text-gray-500">Enter at least 2 characters to search.</p>
      ) : (
        <>
          <p className="text-sm text-gray-500">{total} results for &quot;{q}&quot;</p>

          <div className="space-y-3">
            {type === "priorities" && results.map((r: Record<string, unknown>) => {
              const priority = r as { id: number; name: string; position: number; endorsementsCount: number; user: { id: number; login: string } };
              return (
                <div key={priority.id} className="bg-white rounded-lg border border-gray-200 p-4">
                  <Link href={`/priorities/${priority.id}`} className="font-medium text-gray-900 hover:text-blue-600">
                    {priority.name}
                  </Link>
                  <div className="text-xs text-gray-500 mt-1">
                    by {priority.user.login} · {priority.endorsementsCount} endorsements
                    {priority.position > 0 && ` · Rank #${priority.position}`}
                  </div>
                </div>
              );
            })}

            {type === "users" && results.map((r: Record<string, unknown>) => {
              const user = r as { id: number; login: string; endorsementsCount: number; position: number; followersCount: number };
              return (
                <Link
                  key={user.id}
                  href={`/users/${user.id}`}
                  className="bg-white rounded-lg border border-gray-200 p-4 flex items-center gap-3 hover:border-blue-300 transition-colors block"
                >
                  <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-sm font-bold text-blue-600">
                    {user.login.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <div className="font-medium text-gray-900">{user.login}</div>
                    <div className="text-xs text-gray-500">
                      {user.endorsementsCount} endorsements · {user.followersCount} followers
                      {user.position > 0 && ` · Rank #${user.position}`}
                    </div>
                  </div>
                </Link>
              );
            })}

            {type === "points" && results.map((r: Record<string, unknown>) => {
              const point = r as { id: number; name: string; value: number; user: { id: number; login: string }; priority: { id: number; name: string } };
              return (
                <div key={point.id} className="bg-white rounded-lg border border-gray-200 p-4">
                  <div className="font-medium text-gray-900">{point.name}</div>
                  <div className="text-xs text-gray-500 mt-1">
                    <span className={point.value > 0 ? "text-green-600" : point.value < 0 ? "text-red-600" : "text-gray-500"}>
                      {point.value > 0 ? "Supporting" : point.value < 0 ? "Opposing" : "Neutral"}
                    </span>
                    {" · "}
                    <Link href={`/priorities/${point.priority.id}`} className="text-blue-600 hover:underline">
                      {point.priority.name}
                    </Link>
                    {" · by "}{point.user.login}
                  </div>
                </div>
              );
            })}
          </div>

          {results.length === 0 && (
            <p className="text-center py-8 text-gray-500">No results found.</p>
          )}

          <Pagination page={page} totalPages={totalPages} baseUrl={`/search?q=${encodeURIComponent(q)}&type=${type}`} />
        </>
      )}
    </div>
  );
}
