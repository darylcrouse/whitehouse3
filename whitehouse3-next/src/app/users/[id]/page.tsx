import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { notFound } from "next/navigation";
import Link from "next/link";
import { FollowButton } from "@/components/users/follow-button";
import { EndorsementButton } from "@/components/endorsements/endorsement-button";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function UserProfilePage({ params }: Props) {
  const { id: idParam } = await params;
  const id = parseInt(idParam);
  if (isNaN(id)) notFound();

  const session = await auth();
  const currentUserId = session?.user?.id ? parseInt(session.user.id) : null;

  const user = await prisma.user.findUnique({
    where: { id, status: { in: ["active", "pending"] } },
    select: {
      id: true,
      login: true,
      firstName: true,
      lastName: true,
      endorsementsCount: true,
      commentsCount: true,
      capitalsCount: true,
      pointsCount: true,
      position: true,
      score: true,
      followersCount: true,
      followingsCount: true,
      createdAt: true,
      loggedinAt: true,
      website: true,
      twitterLogin: true,
    },
  });

  if (!user) notFound();

  const [profile, topEndorsements, recentActivities, isFollowing] = await Promise.all([
    prisma.profile.findFirst({
      where: { userId: id },
      select: { bio: true, bioHtml: true },
    }),
    prisma.endorsement.findMany({
      where: { userId: id, status: "active", value: 1 },
      orderBy: { position: "asc" },
      take: 5,
      include: {
        priority: {
          select: {
            id: true,
            name: true,
            position: true,
            upEndorsementsCount: true,
            downEndorsementsCount: true,
            endorsementsCount: true,
          },
        },
      },
    }),
    prisma.activity.findMany({
      where: { userId: id, status: "active", isUserOnly: false },
      orderBy: { changedAt: "desc" },
      take: 10,
      include: {
        priority: { select: { id: true, name: true } },
      },
    }),
    currentUserId
      ? prisma.following.findFirst({
          where: { userId: currentUserId, otherUserId: id, value: 1 },
        }).then((f) => !!f)
      : Promise.resolve(false),
  ]);

  // Fetch current user's endorsement values for the displayed priorities
  let userEndorsementMap: Record<number, number> = {};
  if (currentUserId && topEndorsements.length > 0) {
    const priorityIds = topEndorsements.map((e) => e.priority.id);
    const endorsements = await prisma.endorsement.findMany({
      where: { userId: currentUserId, priorityId: { in: priorityIds }, status: "active" },
      select: { priorityId: true, value: true },
    });
    userEndorsementMap = Object.fromEntries(endorsements.map((e) => [e.priorityId, e.value]));
  }

  const displayName = user.firstName && user.lastName
    ? `${user.firstName} ${user.lastName}`
    : user.login;

  const navTabs = [
    { label: "Priorities", href: `/users/${id}`, active: true },
    { label: "Activities", href: `/users/${id}/activities` },
    { label: `Followers (${user.followersCount})`, href: `/users/${id}/followers` },
    { label: `Following (${user.followingsCount})`, href: `/users/${id}/following` },
  ];

  return (
    <div className="space-y-6">
      {/* Profile header */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center text-2xl font-bold text-blue-600">
              {user.login.charAt(0).toUpperCase()}
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{displayName}</h1>
              {displayName !== user.login && (
                <p className="text-gray-500">@{user.login}</p>
              )}
              <div className="flex items-center gap-4 mt-1 text-sm text-gray-500">
                {user.position > 0 && <span>Rank #{user.position}</span>}
                <span>Joined {new Date(user.createdAt).toLocaleDateString()}</span>
                {user.loggedinAt && (
                  <span>Last visit {new Date(user.loggedinAt).toLocaleDateString()}</span>
                )}
              </div>
            </div>
          </div>
          <FollowButton userId={user.id} isFollowing={isFollowing} />
        </div>

        {/* Stats */}
        <div className="flex gap-6 mt-4 text-sm">
          <div className="text-center">
            <div className="font-bold text-gray-900">{user.endorsementsCount}</div>
            <div className="text-gray-500">Endorsements</div>
          </div>
          <div className="text-center">
            <div className="font-bold text-gray-900">{user.pointsCount}</div>
            <div className="text-gray-500">Points</div>
          </div>
          <div className="text-center">
            <div className="font-bold text-gray-900">{user.capitalsCount}</div>
            <div className="text-gray-500">Capital</div>
          </div>
          <div className="text-center">
            <div className="font-bold text-gray-900">{user.followersCount}</div>
            <div className="text-gray-500">Followers</div>
          </div>
        </div>

        {/* Links */}
        {(user.website || user.twitterLogin) && (
          <div className="flex gap-4 mt-3 text-sm">
            {user.website && (
              <a href={user.website} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                Website
              </a>
            )}
            {user.twitterLogin && (
              <span className="text-gray-500">@{user.twitterLogin}</span>
            )}
          </div>
        )}

        {/* Bio */}
        {profile?.bioHtml && (
          <div
            className="mt-4 text-sm text-gray-700 prose prose-sm max-w-none"
            dangerouslySetInnerHTML={{ __html: profile.bioHtml }}
          />
        )}
        {profile?.bio && !profile.bioHtml && (
          <p className="mt-4 text-sm text-gray-700">{profile.bio}</p>
        )}
      </div>

      {/* Navigation tabs */}
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

      {/* Top priorities */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Top Priorities</h2>
          <Link
            href={`/users/${id}/priorities`}
            className="text-sm text-blue-600 hover:underline"
          >
            View all
          </Link>
        </div>
        {topEndorsements.map((endorsement) => (
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
              </div>
              {endorsement.priority.position > 0 && (
                <span className="text-xs text-gray-500">
                  Overall rank: #{endorsement.priority.position}
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
        {topEndorsements.length === 0 && (
          <p className="text-sm text-gray-500">No priorities yet.</p>
        )}
      </div>

      {/* Recent activity */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Recent Activity</h2>
          <Link
            href={`/users/${id}/activities`}
            className="text-sm text-blue-600 hover:underline"
          >
            View all
          </Link>
        </div>
        {recentActivities.map((activity) => (
          <div
            key={activity.id}
            className="bg-white rounded-lg border border-gray-200 p-3 text-sm"
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
        {recentActivities.length === 0 && (
          <p className="text-sm text-gray-500">No activity yet.</p>
        )}
      </div>
    </div>
  );
}
