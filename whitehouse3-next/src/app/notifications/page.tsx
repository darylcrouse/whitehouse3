import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { Pagination } from "@/components/ui/pagination";
import { MarkReadButton } from "@/components/notifications/mark-read-button";

interface Props {
  searchParams: Promise<{ page?: string }>;
}

export default async function NotificationsPage({ searchParams }: Props) {
  const session = await auth();
  if (!session?.user?.id) redirect("/login");

  const params = await searchParams;
  const userId = parseInt(session.user.id);
  const page = parseInt(params.page || "1");
  const perPage = 25;

  const [notifications, total, unreadCount] = await Promise.all([
    prisma.notification.findMany({
      where: { recipientId: userId, deletedAt: null },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        sender: { select: { id: true, login: true } },
        priority: { select: { id: true, name: true } },
      },
    }),
    prisma.notification.count({
      where: { recipientId: userId, deletedAt: null },
    }),
    prisma.notification.count({
      where: { recipientId: userId, deletedAt: null, readAt: null },
    }),
  ]);

  const totalPages = Math.ceil(total / perPage);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">
          Notifications
          {unreadCount > 0 && (
            <span className="ml-2 text-sm font-normal text-blue-600">
              ({unreadCount} unread)
            </span>
          )}
        </h1>
        {unreadCount > 0 && <MarkReadButton />}
      </div>

      <div className="space-y-2">
        {notifications.map((n) => (
          <div
            key={n.id}
            className={`bg-white rounded-lg border p-4 ${
              n.readAt ? "border-gray-200" : "border-blue-200 bg-blue-50/30"
            }`}
          >
            <div className="flex items-start justify-between">
              <div className="text-sm">
                {n.sender && (
                  <Link
                    href={`/users/${n.sender.id}`}
                    className="font-medium text-gray-900 hover:text-blue-600"
                  >
                    {n.sender.login}
                  </Link>
                )}
                <span className="text-gray-500 ml-1">
                  {n.type?.replace(/^Notification/, "").replace(/([A-Z])/g, " $1").trim().toLowerCase()}
                </span>
                {n.priority && (
                  <>
                    {" "}
                    <Link
                      href={`/priorities/${n.priority.id}`}
                      className="text-blue-600 hover:underline"
                    >
                      {n.priority.name}
                    </Link>
                  </>
                )}
              </div>
              <span className="text-xs text-gray-400 flex-shrink-0 ml-4">
                {new Date(n.createdAt).toLocaleDateString()}
              </span>
            </div>
          </div>
        ))}
      </div>

      {notifications.length === 0 && (
        <p className="text-center py-12 text-gray-500">No notifications.</p>
      )}

      <Pagination page={page} totalPages={totalPages} baseUrl="/notifications" />
    </div>
  );
}
