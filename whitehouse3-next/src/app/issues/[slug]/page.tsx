import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { notFound } from "next/navigation";
import Link from "next/link";
import { EndorsementButton } from "@/components/endorsements/endorsement-button";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ page?: string; sort?: string }>;
}

export default async function IssueDetailPage({ params, searchParams }: Props) {
  const { slug } = await params;
  const sp = await searchParams;
  const page = parseInt(sp.page || "1");
  const sort = sp.sort || "top";
  const perPage = 25;

  // Try to find by slug first, then by id
  const tag = await prisma.tag.findFirst({
    where: isNaN(parseInt(slug)) ? { slug } : { id: parseInt(slug) },
  });

  if (!tag) notFound();

  const session = await auth();
  const userId = session?.user?.id ? parseInt(session.user.id) : null;

  const orderBy: Record<string, unknown> = sort === "newest"
    ? { createdAt: "desc" as const }
    : sort === "controversial"
      ? { isControversial: "desc" as const }
      : { score: "desc" as const };

  // Get priorities tagged with this issue
  const [taggings, total] = await Promise.all([
    prisma.tagging.findMany({
      where: { tagId: tag.id },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        taggable: false,
      },
    }),
    prisma.tagging.count({ where: { tagId: tag.id } }),
  ]);

  // Fetch priorities by tagging IDs
  const taggableIds = taggings.map((t) => t.taggableId);
  const priorities = await prisma.priority.findMany({
    where: { id: { in: taggableIds }, status: "published" },
    orderBy,
    select: {
      id: true,
      name: true,
      position: true,
      endorsementsCount: true,
      upEndorsementsCount: true,
      downEndorsementsCount: true,
      user: { select: { id: true, login: true } },
    },
  });

  // Fetch current user's endorsements
  let userEndorsementMap: Record<number, number> = {};
  if (userId && priorities.length > 0) {
    const endorsements = await prisma.endorsement.findMany({
      where: { userId, priorityId: { in: priorities.map((p) => p.id) }, status: "active" },
      select: { priorityId: true, value: true },
    });
    userEndorsementMap = Object.fromEntries(endorsements.map((e) => [e.priorityId, e.value]));
  }

  const totalPages = Math.ceil(total / perPage);
  const sortTabs = [
    { key: "top", label: "Top" },
    { key: "newest", label: "Newest" },
    { key: "controversial", label: "Controversial" },
  ];

  return (
    <div className="space-y-6">
      <div>
        <Link href="/issues" className="text-sm text-blue-600 hover:underline">
          &larr; All Issues
        </Link>
        <h1 className="text-2xl font-bold text-gray-900 mt-2">
          {tag.title || tag.name}
        </h1>
        {tag.description && (
          <p className="text-gray-600 mt-1">{tag.description}</p>
        )}
      </div>

      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        {sortTabs.map((tab) => (
          <Link
            key={tab.key}
            href={`/issues/${slug}?sort=${tab.key}`}
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

      <div className="space-y-3">
        {priorities.map((priority) => (
          <div
            key={priority.id}
            className="bg-white rounded-lg border border-gray-200 p-4 flex items-center justify-between"
          >
            <div>
              <div className="flex items-center gap-2">
                {priority.position > 0 && (
                  <span className="text-sm font-medium text-gray-400">#{priority.position}</span>
                )}
                <Link
                  href={`/priorities/${priority.id}`}
                  className="font-medium text-gray-900 hover:text-blue-600"
                >
                  {priority.name}
                </Link>
              </div>
              <div className="text-xs text-gray-500 mt-1">
                by{" "}
                <Link href={`/users/${priority.user.id}`} className="hover:underline">
                  {priority.user.login}
                </Link>
                {" · "}{priority.endorsementsCount} endorsements
              </div>
            </div>
            <EndorsementButton
              priorityId={priority.id}
              upCount={priority.upEndorsementsCount}
              downCount={priority.downEndorsementsCount}
              currentValue={userEndorsementMap[priority.id] ?? null}
            />
          </div>
        ))}
      </div>

      {priorities.length === 0 && (
        <p className="text-center py-8 text-gray-500">No priorities for this issue yet.</p>
      )}

      <Pagination
        page={page}
        totalPages={totalPages}
        baseUrl={`/issues/${slug}?sort=${sort}`}
      />
    </div>
  );
}
