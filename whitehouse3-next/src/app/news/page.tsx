import { prisma } from "@/lib/prisma";
import Link from "next/link";
import { CommentThread } from "@/components/ui/comment-thread";
import { Pagination } from "@/components/ui/pagination";

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
          select: {
            id: true,
            content: true,
            isEndorser: true,
            isOpposer: true,
            createdAt: true,
            user: { select: { id: true, login: true } },
          },
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
            <div className="mt-2">
              <CommentThread
                activityId={activity.id}
                comments={activity.comments.map((c) => ({
                  ...c,
                  createdAt: c.createdAt.toISOString(),
                }))}
                totalCount={activity.commentsCount}
              />
            </div>
          </div>
        ))}
      </div>

      {activities.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          No activity found.
        </div>
      )}

      <Pagination page={page} totalPages={totalPages} baseUrl={`/news?filter=${filter}`} />
    </div>
  );
}
