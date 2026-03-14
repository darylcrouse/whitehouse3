import { prisma } from "@/lib/prisma";
import Link from "next/link";
import { Pagination } from "@/components/ui/pagination";

interface Props {
  searchParams: Promise<{ page?: string; status?: string; q?: string }>;
}

export default async function AdminUsersPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1");
  const status = params.status || "active";
  const q = params.q || "";
  const perPage = 50;

  const where: Record<string, unknown> = { status };
  if (q) {
    where.login = { contains: q, mode: "insensitive" };
  }

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * perPage,
      take: perPage,
      select: {
        id: true,
        login: true,
        email: true,
        status: true,
        endorsementsCount: true,
        position: true,
        createdAt: true,
        loggedinAt: true,
        isAdmin: true,
      },
    }),
    prisma.user.count({ where }),
  ]);

  const totalPages = Math.ceil(total / perPage);
  const statusTabs = ["active", "pending", "suspended", "deleted"];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Manage Users</h1>

      <div className="flex items-center gap-4">
        <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
          {statusTabs.map((s) => (
            <Link
              key={s}
              href={`/admin/users?status=${s}&q=${q}`}
              className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                status === s
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              {s}
            </Link>
          ))}
        </div>
        <form action="/admin/users" className="flex gap-2">
          <input type="hidden" name="status" value={status} />
          <input
            name="q"
            defaultValue={q}
            placeholder="Search users..."
            className="px-3 py-1.5 border border-gray-300 rounded-md text-sm"
          />
          <button type="submit" className="px-3 py-1.5 bg-blue-600 text-white rounded-md text-sm">
            Search
          </button>
        </form>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-2 font-medium text-gray-500">User</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Email</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Status</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Rank</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Joined</th>
              <th className="text-left px-4 py-2 font-medium text-gray-500">Last Login</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="px-4 py-2">
                  <Link href={`/users/${user.id}`} className="text-blue-600 hover:underline">
                    {user.login}
                  </Link>
                  {user.isAdmin && (
                    <span className="ml-1 text-xs px-1.5 py-0.5 bg-purple-100 text-purple-700 rounded">
                      admin
                    </span>
                  )}
                </td>
                <td className="px-4 py-2 text-gray-600">{user.email}</td>
                <td className="px-4 py-2">
                  <span className={`text-xs px-1.5 py-0.5 rounded ${
                    user.status === "active" ? "bg-green-50 text-green-700" :
                    user.status === "suspended" ? "bg-red-50 text-red-700" :
                    "bg-gray-50 text-gray-700"
                  }`}>
                    {user.status}
                  </span>
                </td>
                <td className="px-4 py-2 text-gray-600">
                  {user.position > 0 ? `#${user.position}` : "-"}
                </td>
                <td className="px-4 py-2 text-gray-600">
                  {new Date(user.createdAt).toLocaleDateString()}
                </td>
                <td className="px-4 py-2 text-gray-600">
                  {user.loggedinAt ? new Date(user.loggedinAt).toLocaleDateString() : "-"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {users.length === 0 && (
        <p className="text-center py-8 text-gray-500">No users found.</p>
      )}

      <Pagination page={page} totalPages={totalPages} baseUrl={`/admin/users?status=${status}&q=${q}`} />
    </div>
  );
}
