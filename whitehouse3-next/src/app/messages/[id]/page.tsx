import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { redirect, notFound } from "next/navigation";
import Link from "next/link";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function MessageDetailPage({ params }: Props) {
  const session = await auth();
  if (!session?.user?.id) redirect("/login");

  const { id: idParam } = await params;
  const id = parseInt(idParam);
  const userId = parseInt(session.user.id);
  if (isNaN(id)) notFound();

  const message = await prisma.message.findUnique({
    where: { id },
    include: {
      sender: { select: { id: true, login: true } },
      recipient: { select: { id: true, login: true } },
    },
  });

  if (!message || (message.senderId !== userId && message.recipientId !== userId)) {
    notFound();
  }

  // Mark as read if recipient is viewing
  if (message.recipientId === userId && !message.readAt) {
    await prisma.message.update({
      where: { id },
      data: { readAt: new Date() },
    });
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <Link href="/messages" className="text-sm text-blue-600 hover:underline">
        &larr; Back to messages
      </Link>

      <div className="bg-white rounded-lg border border-gray-200 p-6 space-y-4">
        <h1 className="text-xl font-bold text-gray-900">{message.title}</h1>

        <div className="flex items-center gap-4 text-sm text-gray-500">
          <span>
            From:{" "}
            <Link href={`/users/${message.sender.id}`} className="text-blue-600 hover:underline">
              {message.sender.login}
            </Link>
          </span>
          <span>
            To:{" "}
            <Link href={`/users/${message.recipient.id}`} className="text-blue-600 hover:underline">
              {message.recipient.login}
            </Link>
          </span>
          <span>{new Date(message.createdAt).toLocaleString()}</span>
        </div>

        <div className="border-t border-gray-100 pt-4">
          {message.contentHtml ? (
            <div
              className="prose prose-sm max-w-none"
              dangerouslySetInnerHTML={{ __html: message.contentHtml }}
            />
          ) : (
            <p className="text-gray-700 whitespace-pre-wrap">{message.content}</p>
          )}
        </div>
      </div>
    </div>
  );
}
