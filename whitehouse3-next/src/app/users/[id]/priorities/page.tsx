import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { notFound } from "next/navigation";
import Link from "next/link";
import { EndorsementButton } from "@/components/endorsements/endorsement-button";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ page?: string; filter?: string }>;
}

export default async function UserPrioritiesPage({ params, searchParams }: Props) {
  const { id: idParam } = await params;
  const sp = await searchParams;
  const id = parseInt(idParam);
  if (isNaN(id)) notFound();

  const page = parseInt(sp.page || "1");
  const filter = sp.filter || "endorsed";
  const perPage = 25;

  const session = await auth();
  const currentUserId = session?.user?.id ? parseInt(session.user.id) : null;

  const user = await prisma.user.findUnique({
    where: { id, status: { in: ["active", "pending"] } },
    select: { id: true, login: true, followersCount: true, followingsCount: true },
  });
  if (!user) notFound();

  const endorsementWhere = {
    userId: id,
    status: "active" as const,
    ...(filter === "endorsed" ? { value: 1 } : filter === "opposed" ? { value: -1 } : {}),
  };

  const [endorsements, total] = await Promise.all([
    prisma.endorsement.findMany({
      where: endorsementWhere,
      orderBy: { position: "asc" },
      skip: (page - 1) * perPage,
      take: perPage,
      include: {
        priority: {
          select: {
            id: true,
            name: true,
            position: true,
            endorsementsCount: true,
            upEndorsementsCount: true,
            downEndorsementsCount: true,
          },
        },
      },
    }),
    prisma.endorsement.count({ where: endorsementWhere }),
  ]);

  // Fetch current user's endorsements
  let userEndorsementMap: Record<number, number> = {};
  if (currentUserId && endorsements.length > 0) {
    const myEndorsements = await prisma.endorsement.findMany({
      where: {
        userId: currentUserId,
        priorityId: { in: endorsements.map((e) => e.priority.id) },
        status: "active",
      },
      select: { priorityId: true, value: true },
    });
    userEndorsementMap = Object.fromEntries(myEndorsements.map((e) => [e.priorityId, e.value]));
  }

  const totalPages = Math.ceil(total / perPage);

  const navTabs = [
    { label: "Priorities", href: `/users/${id}` },
    { label: "Activities", href: `/users/${id}/activities` },
    { label: `Followers (${user.followersCount})`, href: `/users/${id}/followers` },
    { label: `Following (${user.followingsCount})`, href: `/users/${id}/following` },
  ];

  const filterTabs = [
    { key: "endorsed", label: "Endorsed" },
    { key: "opposed", label: "Opposed" },
    { key: "all", label: "All" },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">{user.login}&apos;s Priorities</h1>

      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        {navTabs.map((tab) => (
          <Link
            key={tab.href}
            href={tab.href}
            className="px-4 py-2 rounded-md text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
          >
            {tab.label}
          </Link>
        ))}
      </div>

      <div className="flex gap-2">
        {filterTabs.map((tab) => (
          <Link
            key={tab.key}
            href={`/users/${id}/priorities?filter=${tab.key}`}
            className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
              filter === tab.key
                ? "bg-blue-600 text-white"
                : "bg-gray-100 text-gray-600 hover:bg-gray-200"
            }`}
          >
            {tab.label}
          </Link>
        ))}
      </div>

      <div className="space-y-3">
        {endorsements.map((endorsement) => (
          <div
            key={endorsement.id}
            className="bg-white rounded-lg border border-gray-200 p-4 flex items-center justify-between"
          >
            <div>
              <div className="flex items-center gap-2">
                {endorsement.position > 0 && (
                  <span className="text-xs text-gray-400">#{endorsement.position}</span>
                )}
                <Link
                  href={`/priorities/${endorsement.priority.id}`}
                  className="font-medium text-gray-900 hover:text-blue-600"
                >
                  {endorsement.priority.name}
                </Link>
                <span className={`text-xs px-1.5 py-0.5 rounded ${
                  endorsement.value === 1
                    ? "bg-green-50 text-green-700"
                    : "bg-red-50 text-red-700"
                }`}>
                  {endorsement.value === 1 ? "endorsed" : "opposed"}
                </span>
              </div>
              {endorsement.priority.position > 0 && (
                <span className="text-xs text-gray-500">
                  Overall rank: #{endorsement.priority.position} · {endorsement.priority.endorsementsCount} endorsements
                </span>
              )}
            </div>
            <EndorsementButton
              priorityId={endorsement.priority.id}
              upCount={endorsement.priority.upEndorsementsCount}
              downCount={endorsement.priority.downEndorsementsCount}
              currentValue={userEndorsementMap[endorsement.priority.id] ?? null}
            />
          </div>
        ))}
      </div>

      {endorsements.length === 0 && (
        <p className="text-sm text-gray-500">No priorities found.</p>
      )}

      <Pagination page={page} totalPages={totalPages} baseUrl={`/users/${id}/priorities?filter=${filter}`} />
    </div>
  );
}
