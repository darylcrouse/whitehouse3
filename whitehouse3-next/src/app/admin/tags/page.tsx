import { prisma } from "@/lib/prisma";
import Link from "next/link";

export default async function AdminTagsPage() {
  const tags = await prisma.tag.findMany({
    orderBy: { prioritiesCount: "desc" },
    select: {
      id: true,
      name: true,
      title: true,
      slug: true,
      prioritiesCount: true,
      upEndorsersCount: true,
      downEndorsersCount: true,
      pointsCount: true,
      createdAt: true,
    },
  });

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Manage Tags/Issues</h1>

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Tag</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Slug</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Priorities</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Points</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Created</th>
            </tr>
          </thead>
          <tbody>
            {tags.map((tag) => (
              <tr key={tag.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="px-4 py-2">
                  <Link
                    href={`/issues/${tag.slug || tag.id}`}
                    className="text-blue-600 hover:underline"
                  >
                    {tag.title || tag.name}
                  </Link>
                </td>
                <td className="px-4 py-2 text-gray-600">{tag.slug || "-"}</td>
                <td className="px-4 py-2 text-gray-600">{tag.prioritiesCount}</td>
                <td className="px-4 py-2 text-gray-600">{tag.pointsCount}</td>
                <td className="px-4 py-2 text-gray-600">
                  {new Date(tag.createdAt).toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {tags.length === 0 && (
        <p className="text-center py-8 text-gray-500">No tags found.</p>
      )}
    </div>
  );
}
