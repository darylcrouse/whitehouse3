import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { notFound } from "next/navigation";
import Link from "next/link";
import { EndorsementButton } from "@/components/endorsements/endorsement-button";
import { CommentThread } from "@/components/ui/comment-thread";
import { PointForm } from "@/components/points/point-form";
import { QualityButtons } from "@/components/points/quality-buttons";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function PriorityDetailPage({ params }: Props) {
  const { id: idParam } = await params;
  const id = parseInt(idParam);
  if (isNaN(id)) notFound();

  const session = await auth();
  const userId = session?.user?.id ? parseInt(session.user.id) : null;

  const priority = await prisma.priority.findUnique({
    where: { id },
    include: {
      user: { select: { id: true, login: true } },
      points: {
        where: { status: "published" },
        orderBy: { score: "desc" },
        take: 20,
        include: {
          user: { select: { id: true, login: true } },
        },
      },
      activities: {
        where: { status: "active", isUserOnly: false },
        orderBy: { changedAt: "desc" },
        take: 10,
        include: {
          user: { select: { id: true, login: true } },
          comments: {
            where: { status: "published" },
            take: 3,
            orderBy: { createdAt: "asc" },
            select: {
              id: true,
              content: true,
              isEndorser: true,
              isOpposer: true,
              createdAt: true,
              user: { select: { id: true, login: true } },
            },
          },
        },
      },
    },
  });

  if (!priority) notFound();

  // Fetch current user's endorsement value for this priority
  let currentEndorsementValue: number | null = null;
  if (userId) {
    const endorsement = await prisma.endorsement.findFirst({
      where: { priorityId: id, userId, status: "active" },
      select: { value: true },
    });
    currentEndorsementValue = endorsement?.value ?? null;
  }

  // Fetch current user's point quality votes
  let pointQualityMap: Record<number, number> = {};
  if (userId && priority.points.length > 0) {
    const qualities = await prisma.pointQuality.findMany({
      where: { userId, pointId: { in: priority.points.map((p) => p.id) } },
      select: { pointId: true, value: true },
    });
    pointQualityMap = Object.fromEntries(qualities.map((q) => [q.pointId, q.value]));
  }

  const supportingPoints = priority.points.filter((p) => p.value > 0);
  const opposingPoints = priority.points.filter((p) => p.value < 0);
  const neutralPoints = priority.points.filter((p) => p.value === 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <div className="flex items-start justify-between">
          <div>
            <div className="text-sm text-gray-500 mb-1">
              {priority.position > 0 ? `#${priority.position} Priority` : "Unranked"}
            </div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2">
              {priority.name}
            </h1>
            <div className="flex items-center gap-4 text-sm text-gray-500">
              <span>
                by{" "}
                <Link
                  href={`/users/${priority.user.id}`}
                  className="text-blue-600 hover:underline"
                >
                  {priority.user.login}
                </Link>
              </span>
              <span>{priority.endorsementsCount} endorsements</span>
              <span>{priority.pointsCount} points</span>
              {priority.isControversial && (
                <span className="text-orange-500 font-medium">
                  Controversial
                </span>
              )}
            </div>
          </div>
          <EndorsementButton
            priorityId={priority.id}
            upCount={priority.upEndorsementsCount}
            downCount={priority.downEndorsementsCount}
            currentValue={currentEndorsementValue}
          />
        </div>

        {/* Movement stats */}
        <div className="mt-4 flex gap-6 text-sm">
          <div>
            <span className="text-gray-500">24h: </span>
            <span
              className={
                priority.position24hrChange > 0
                  ? "text-green-600"
                  : priority.position24hrChange < 0
                    ? "text-red-600"
                    : "text-gray-400"
              }
            >
              {priority.position24hrChange > 0 ? "+" : ""}
              {priority.position24hrChange || "-"}
            </span>
          </div>
          <div>
            <span className="text-gray-500">7d: </span>
            <span
              className={
                priority.position7daysChange > 0
                  ? "text-green-600"
                  : priority.position7daysChange < 0
                    ? "text-red-600"
                    : "text-gray-400"
              }
            >
              {priority.position7daysChange > 0 ? "+" : ""}
              {priority.position7daysChange || "-"}
            </span>
          </div>
          <div>
            <span className="text-gray-500">30d: </span>
            <span
              className={
                priority.position30daysChange > 0
                  ? "text-green-600"
                  : priority.position30daysChange < 0
                    ? "text-red-600"
                    : "text-gray-400"
              }
            >
              {priority.position30daysChange > 0 ? "+" : ""}
              {priority.position30daysChange || "-"}
            </span>
          </div>
        </div>
      </div>

      {/* Points (arguments) */}
      <div className="grid md:grid-cols-2 gap-6">
        {/* Supporting */}
        <div className="space-y-3">
          <h2 className="text-lg font-semibold text-green-700">
            Supporting Points ({supportingPoints.length})
          </h2>
          {supportingPoints.map((point) => (
            <div
              key={point.id}
              className="bg-white rounded-lg border border-green-200 p-4"
            >
              <h3 className="font-medium text-gray-900">{point.name}</h3>
              {point.content && (
                <p className="text-sm text-gray-600 mt-1">{point.content}</p>
              )}
              <div className="flex items-center justify-between mt-2">
                <span className="text-xs text-gray-500">by {point.user.login}</span>
                <QualityButtons
                  pointId={point.id}
                  helpfulCount={point.helpfulCount}
                  unhelpfulCount={point.unhelpfulCount}
                  currentVote={pointQualityMap[point.id] ?? null}
                />
              </div>
            </div>
          ))}
          {supportingPoints.length === 0 && (
            <p className="text-sm text-gray-500">No supporting points yet.</p>
          )}
          <PointForm priorityId={priority.id} defaultValue={1} />
        </div>

        {/* Opposing */}
        <div className="space-y-3">
          <h2 className="text-lg font-semibold text-red-700">
            Opposing Points ({opposingPoints.length})
          </h2>
          {opposingPoints.map((point) => (
            <div
              key={point.id}
              className="bg-white rounded-lg border border-red-200 p-4"
            >
              <h3 className="font-medium text-gray-900">{point.name}</h3>
              {point.content && (
                <p className="text-sm text-gray-600 mt-1">{point.content}</p>
              )}
              <div className="flex items-center justify-between mt-2">
                <span className="text-xs text-gray-500">by {point.user.login}</span>
                <QualityButtons
                  pointId={point.id}
                  helpfulCount={point.helpfulCount}
                  unhelpfulCount={point.unhelpfulCount}
                  currentVote={pointQualityMap[point.id] ?? null}
                />
              </div>
            </div>
          ))}
          {opposingPoints.length === 0 && (
            <p className="text-sm text-gray-500">No opposing points yet.</p>
          )}
          <PointForm priorityId={priority.id} defaultValue={-1} />
        </div>
      </div>

      {/* Neutral points */}
      {neutralPoints.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-lg font-semibold text-gray-700">
            Neutral Points ({neutralPoints.length})
          </h2>
          {neutralPoints.map((point) => (
            <div
              key={point.id}
              className="bg-white rounded-lg border border-gray-200 p-4"
            >
              <h3 className="font-medium text-gray-900">{point.name}</h3>
              {point.content && (
                <p className="text-sm text-gray-600 mt-1">{point.content}</p>
              )}
              <div className="flex items-center justify-between mt-2">
                <span className="text-xs text-gray-500">by {point.user.login}</span>
                <QualityButtons
                  pointId={point.id}
                  helpfulCount={point.helpfulCount}
                  unhelpfulCount={point.unhelpfulCount}
                  currentVote={pointQualityMap[point.id] ?? null}
                />
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Discussion / Activity */}
      <div className="space-y-3">
        <h2 className="text-lg font-semibold text-gray-900">Discussion</h2>
        {priority.activities.map((activity) => (
          <div
            key={activity.id}
            className="bg-white rounded-lg border border-gray-200 p-4"
          >
            <div className="text-sm text-gray-600">
              <span className="font-medium text-gray-900">
                {activity.user?.login}
              </span>{" "}
              <span className="text-gray-400">
                {activity.type?.replace(/^Activity/, "").replace(/([A-Z])/g, " $1").trim()}
              </span>
              <span className="ml-2 text-xs text-gray-400">
                {new Date(activity.createdAt).toLocaleDateString()}
              </span>
            </div>
            <CommentThread
              activityId={activity.id}
              comments={activity.comments.map((c) => ({
                ...c,
                createdAt: c.createdAt.toISOString(),
              }))}
              totalCount={activity.commentsCount}
            />
          </div>
        ))}
        {priority.activities.length === 0 && (
          <p className="text-sm text-gray-500">No activity yet.</p>
        )}
      </div>
    </div>
  );
}
