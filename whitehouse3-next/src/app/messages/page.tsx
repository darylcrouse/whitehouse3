import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { redirect } from "next/navigation";
import Link from "next/link";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  searchParams: Promise<{ page?: string; folder?: string }>;
}

export default async function MessagesPage({ searchParams }: Props) {
  const session = await auth();
  if (!session?.user?.id) redirect("/login");

  const params = await searchParams;
  const userId = parseInt(session.user.id);
  const folder = params.folder || "inbox";
  const page = parseInt(params.page || "1");
  const perPage = 25;

  const where = folder === "sent"
    ? { senderId: userId, deletedAt: null }
    : { recipientId: userId, deletedAt: null };

  const [messages, total, unreadCount] = await Promise.all([
    prisma.message.findMany({
      where,
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        sender: { select: { id: true, login: true } },
        recipient: { select: { id: true, login: true } },
      },
    }),
    prisma.message.count({ where }),
    prisma.message.count({
      where: { recipientId: userId, deletedAt: null, readAt: null },
    }),
  ]);

  const totalPages = Math.ceil(total / perPage);
  const folderTabs = [
    { key: "inbox", label: `Inbox${unreadCount > 0 ? ` (${unreadCount})` : ""}` },
    { key: "sent", label: "Sent" },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Messages</h1>
        <Link
          href="/messages/new"
          className="px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700"
        >
          New Message
        </Link>
      </div>

      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        {folderTabs.map((tab) => (
          <Link
            key={tab.key}
            href={`/messages?folder=${tab.key}`}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              folder === tab.key
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            {tab.label}
          </Link>
        ))}
      </div>

      <div className="space-y-2">
        {messages.map((msg) => (
          <Link
            key={msg.id}
            href={`/messages/${msg.id}`}
            className={`block bg-white rounded-lg border p-4 hover:border-blue-300 transition-colors ${
              !msg.readAt && folder === "inbox" ? "border-blue-200 bg-blue-50/30" : "border-gray-200"
            }`}
          >
            <div className="flex items-center justify-between">
              <div>
                <span className="text-sm font-medium text-gray-900">
                  {folder === "inbox" ? `From: ${msg.sender.login}` : `To: ${msg.recipient.login}`}
                </span>
                <span className="mx-2 text-gray-300">|</span>
                <span className="text-sm text-gray-700">{msg.title}</span>
              </div>
              <span className="text-xs text-gray-400">
                {new Date(msg.createdAt).toLocaleDateString()}
              </span>
            </div>
          </Link>
        ))}
      </div>

      {messages.length === 0 && (
        <p className="text-center py-12 text-gray-500">
          {folder === "inbox" ? "No messages in your inbox." : "No sent messages."}
        </p>
      )}

      <Pagination page={page} totalPages={totalPages} baseUrl={`/messages?folder=${folder}`} />
    </div>
  );
}
