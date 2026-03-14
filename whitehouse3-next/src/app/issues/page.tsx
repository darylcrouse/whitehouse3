import { prisma } from "@/lib/prisma";
import Link from "next/link";

export default async function IssuesPage() {
  const tags = await prisma.tag.findMany({
    orderBy: { prioritiesCount: "desc" },
    select: {
      id: true,
      name: true,
      title: true,
      description: true,
      slug: true,
      prioritiesCount: true,
      upEndorsersCount: true,
      downEndorsersCount: true,
      pointsCount: true,
      discussionsCount: true,
    },
  });

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Issues</h1>
      <p className="text-gray-600">Browse priorities by topic area.</p>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {tags.map((tag) => (
          <Link
            key={tag.id}
            href={`/issues/${tag.slug || tag.id}`}
            className="bg-white rounded-lg border border-gray-200 p-5 hover:border-blue-300 hover:shadow-sm transition-all"
          >
            <h2 className="font-semibold text-gray-900 text-lg">
              {tag.title || tag.name}
            </h2>
            {tag.description && (
              <p className="text-sm text-gray-500 mt-1">{tag.description}</p>
            )}
            <div className="flex gap-4 mt-3 text-xs text-gray-400">
              <span>{tag.prioritiesCount} priorities</span>
              <span>{tag.pointsCount} points</span>
              <span>{tag.discussionsCount} discussions</span>
            </div>
          </Link>
        ))}
      </div>

      {tags.length === 0 && (
        <p className="text-center py-8 text-gray-500">No issues found.</p>
      )}
    </div>
  );
}
