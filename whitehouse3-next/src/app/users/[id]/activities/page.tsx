import { prisma } from "@/lib/prisma";
import { notFound } from "next/navigation";
import Link from "next/link";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ page?: string }>;
}

export default async function UserActivitiesPage({ params, searchParams }: Props) {
  const { id: idParam } = await params;
  const sp = await searchParams;
  const id = parseInt(idParam);
  if (isNaN(id)) notFound();

  const page = parseInt(sp.page || "1");
  const perPage = 25;

  const user = await prisma.user.findUnique({
    where: { id, status: { in: ["active", "pending"] } },
    select: { id: true, login: true, followersCount: true, followingsCount: true },
  });
  if (!user) notFound();

  const [activities, total] = await Promise.all([
    prisma.activity.findMany({
      where: { userId: id, status: "active", isUserOnly: false },
      orderBy: { changedAt: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        priority: { select: { id: true, name: true } },
      },
    }),
    prisma.activity.count({
      where: { userId: id, status: "active", isUserOnly: false },
    }),
  ]);

  const totalPages = Math.ceil(total / perPage);

  const navTabs = [
    { label: "Priorities", href: `/users/${id}` },
    { label: "Activities", href: `/users/${id}/activities`, active: true },
    { label: `Followers (${user.followersCount})`, href: `/users/${id}/followers` },
    { label: `Following (${user.followingsCount})`, href: `/users/${id}/following` },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">{user.login}&apos;s Activity</h1>

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

      <div className="space-y-3">
        {activities.map((activity) => (
          <div
            key={activity.id}
            className="bg-white rounded-lg border border-gray-200 p-4 text-sm"
          >
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
            <span className="ml-2 text-xs text-gray-400">
              {new Date(activity.createdAt).toLocaleDateString()}
            </span>
          </div>
        ))}
        {activities.length === 0 && (
          <p className="text-sm text-gray-500">No activity yet.</p>
        )}
      </div>

      <Pagination page={page} totalPages={totalPages} baseUrl={`/users/${id}/activities`} />
    </div>
  );
}
