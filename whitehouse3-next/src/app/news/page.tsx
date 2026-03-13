import { prisma } from "@/lib/prisma";
import Link from "next/link";

interface Props {
  searchParams: Promise<{ page?: string; filter?: string }>;
}

export default async function NewsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1");
  const filter = params.filter || "all";
  const perPage = 25;
  const skip = (page - 1) * perPage;

  const where: Record<string, unknown> = {
    status: "active",
    isUserOnly: false,
  };

  switch (filter) {
    case "discussions":
      where.commentsCount = { gt: 0 };
      break;
    case "points":
      where.type = { startsWith: "ActivityPoint" };
      break;
  }

  const [activities, total] = await Promise.all([
    prisma.activity.findMany({
      where,
      orderBy: { changedAt: "desc" },
      skip,
      take: perPage,
      include: {
        user: { select: { id: true, login: true } },
        priority: { select: { id: true, name: true } },
        point: { select: { id: true, name: true } },
        document: { select: { id: true, name: true } },
        comments: {
          where: { status: "published" },
          take: 3,
          orderBy: { createdAt: "asc" },
          include: { user: { select: { id: true, login: true } } },
        },
      },
    }),
    prisma.activity.count({ where }),
  ]);

  const totalPages = Math.ceil(total / perPage);
  const filterTabs = [
    { key: "all", label: "All Activity" },
    { key: "discussions", label: "Discussions" },
    { key: "points", label: "Points" },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">News Feed</h1>

      {/* Filter tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        {filterTabs.map((tab) => (
          <Link
            key={tab.key}
            href={`/news?filter=${tab.key}`}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              filter === tab.key
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            {tab.label}
          </Link>
        ))}
      </div>

      {/* Activity list */}
      <div className="space-y-3">
        {activities.map((activity) => (
          <div
            key={activity.id}
            className="bg-white rounded-lg border border-gray-200 p-4"
          >
            <div className="flex items-start justify-between">
              <div className="text-sm">
                {activity.user && (
                  <Link
                    href={`/users/${activity.user.id}`}
                    className="font-medium text-gray-900 hover:text-blue-600"
                  >
                    {activity.user.login}
                  </Link>
                )}{" "}
                <span className="text-gray-500">
                  {activity.type?.replace(/^Activity/, "").replace(/([A-Z])/g, " $1").trim()}
                </span>
                {activity.priority && (
                  <>
                    {" "}
                    <Link
                      href={`/priorities/${activity.priority.id}`}
                      className="text-blue-600 hover:underline"
                    >
                      {activity.priority.name}
                    </Link>
                  </>
                )}
              </div>
              <span className="text-xs text-gray-400 flex-shrink-0 ml-4">
                {new Date(activity.createdAt).toLocaleDateString()}
              </span>
            </div>
            {activity.commentsCount > 0 && (
              <div className="mt-2 space-y-2 pl-4 border-l-2 border-gray-100">
                {activity.comments.map((comment) => (
                  <div key={comment.id} className="text-sm">
                    <span className="font-medium text-gray-900">
                      {comment.user.login}:{" "}
                    </span>
                    <span className="text-gray-600">{comment.content}</span>
                  </div>
                ))}
                {activity.commentsCount > 3 && (
                  <div className="text-xs text-blue-600">
                    View all {activity.commentsCount} comments
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>

      {activities.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          No activity found.
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex justify-center gap-2">
          {page > 1 && (
            <Link
              href={`/news?filter=${filter}&page=${page - 1}`}
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
              href={`/news?filter=${filter}&page=${page + 1}`}
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
