import { prisma } from "@/lib/prisma";

export default async function AdminDashboardPage() {
  const [usersCount, prioritiesCount, endorsementsCount, activitiesCount, tagsCount] =
    await Promise.all([
      prisma.user.count({ where: { status: "active" } }),
      prisma.priority.count({ where: { status: "published" } }),
      prisma.endorsement.count({ where: { status: "active" } }),
      prisma.activity.count({ where: { status: "active" } }),
      prisma.tag.count(),
    ]);

  const stats = [
    { label: "Active Users", value: usersCount },
    { label: "Published Priorities", value: prioritiesCount },
    { label: "Active Endorsements", value: endorsementsCount },
    { label: "Activities", value: activitiesCount },
    { label: "Tags/Issues", value: tagsCount },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>

      <div className="grid gap-4 md:grid-cols-3 lg:grid-cols-5">
        {stats.map((stat) => (
          <div
            key={stat.label}
            className="bg-white rounded-lg border border-gray-200 p-4 text-center"
          >
            <div className="text-2xl font-bold text-gray-900">
              {stat.value.toLocaleString()}
            </div>
            <div className="text-sm text-gray-500">{stat.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
