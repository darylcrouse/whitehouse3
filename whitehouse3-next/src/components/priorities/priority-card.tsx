"use client";

import Link from "next/link";

interface PriorityCardProps {
  priority: {
    id: number;
    name: string;
    position: number;
    endorsementsCount: number;
    upEndorsementsCount: number;
    downEndorsementsCount: number;
    pointsCount: number;
    status: string | null;
    position24hrChange: number;
    position7daysChange: number;
    isControversial: boolean;
    user: { id: number; login: string };
  };
}

function getMovementIndicator(change: number) {
  if (change > 0) return { text: `+${change}`, color: "text-green-600" };
  if (change < 0) return { text: `${change}`, color: "text-red-600" };
  return { text: "-", color: "text-gray-400" };
}

export function PriorityCard({ priority }: PriorityCardProps) {
  const movement24hr = getMovementIndicator(priority.position24hrChange);
  const movement7days = getMovementIndicator(priority.position7daysChange);

  const slug = `${priority.id}-${priority.name
    .replace(/[^a-z0-9]+/gi, "-")
    .toLowerCase()}`;

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4 hover:border-gray-300 transition-colors">
      <div className="flex items-start gap-4">
        {/* Position */}
        <div className="flex-shrink-0 w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center">
          <span className="text-lg font-bold text-gray-700">
            {priority.position > 0 ? `#${priority.position}` : "-"}
          </span>
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <Link
            href={`/priorities/${slug}`}
            className="text-base font-semibold text-gray-900 hover:text-blue-600 line-clamp-2"
          >
            {priority.name}
          </Link>
          <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
            <span>by {priority.user.login}</span>
            <span>{priority.endorsementsCount} endorsements</span>
            <span>{priority.pointsCount} points</span>
            {priority.isControversial && (
              <span className="text-orange-500 font-medium">Controversial</span>
            )}
          </div>
        </div>

        {/* Movement indicators */}
        <div className="flex-shrink-0 text-right text-sm">
          <div className={movement24hr.color}>
            {movement24hr.text}{" "}
            <span className="text-gray-400 text-xs">24h</span>
          </div>
          <div className={`${movement7days.color} mt-1`}>
            {movement7days.text}{" "}
            <span className="text-gray-400 text-xs">7d</span>
          </div>
        </div>

        {/* Endorse/Oppose buttons */}
        <div className="flex-shrink-0 flex flex-col gap-1">
          <button className="px-3 py-1 text-xs font-medium bg-green-50 text-green-700 border border-green-200 rounded hover:bg-green-100">
            +{priority.upEndorsementsCount}
          </button>
          <button className="px-3 py-1 text-xs font-medium bg-red-50 text-red-700 border border-red-200 rounded hover:bg-red-100">
            -{priority.downEndorsementsCount}
          </button>
        </div>
      </div>
    </div>
  );
}
