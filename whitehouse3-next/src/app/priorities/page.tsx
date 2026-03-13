import { prisma } from "@/lib/prisma";
import { PriorityCard } from "@/components/priorities/priority-card";
import Link from "next/link";

interface Props {
  searchParams: Promise<{ sort?: string; page?: string }>;
}

export default async function PrioritiesPage({ searchParams }: Props) {
  const params = await searchParams;
  const sort = params.sort || "top";
  const page = parseInt(params.page || "1");
  const perPage = 25;
  const skip = (page - 1) * perPage;

  let orderBy: Record<string, string> = {};
  let where: Record<string, unknown> = { status: "published" };

  switch (sort) {
    case "top":
      orderBy = { score: "desc" };
      break;
    case "rising":
      where = { ...where, trendingScore: { gt: 0 } };
      orderBy = { trendingScore: "desc" };
      break;
    case "falling":
      where = { ...where, trendingScore: { lt: 0 } };
      orderBy = { trendingScore: "asc" };
      break;
    case "controversial":
      where = { ...where, isControversial: true };
      orderBy = { controversialScore: "desc" };
      break;
    case "newest":
      orderBy = { publishedAt: "desc" };
      break;
    default:
      orderBy = { position: "asc" };
  }

  const [priorities, total] = await Promise.all([
    prisma.priority.findMany({
      where,
      orderBy,
      skip,
      take: perPage,
      include: {
        user: { select: { id: true, login: true } },
      },
    }),
    prisma.priority.count({ where }),
  ]);

  const totalPages = Math.ceil(total / perPage);
  const sortTabs = [
    { key: "top", label: "Top Ranked" },
    { key: "rising", label: "Rising" },
    { key: "controversial", label: "Controversial" },
    { key: "newest", label: "Newest" },
    { key: "falling", label: "Falling" },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Priorities</h1>
        <Link
          href="/priorities/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-blue-700"
        >
          Add Priority
        </Link>
      </div>

      {/* Sort tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
        {sortTabs.map((tab) => (
          <Link
            key={tab.key}
            href={`/priorities?sort=${tab.key}`}
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

      {/* Priority list */}
      <div className="space-y-3">
        {priorities.map((priority) => (
          <PriorityCard key={priority.id} priority={priority} />
        ))}
      </div>

      {priorities.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          No priorities found for this filter.
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex justify-center gap-2">
          {page > 1 && (
            <Link
              href={`/priorities?sort=${sort}&page=${page - 1}`}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50"
            >
              Previous
            </Link>
          )}
          <span className="px-4 py-2 text-sm text-gray-600">
            Page {page} of {totalPages}
          </span>
          {page < totalPages && (
            <Link
              href={`/priorities?sort=${sort}&page=${page + 1}`}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50"
            >
              Next
            </Link>
          )}
        </div>
      )}
    </div>
  );
}
