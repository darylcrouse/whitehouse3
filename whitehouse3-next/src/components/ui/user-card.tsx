import Link from "next/link";

interface UserCardProps {
  user: {
    id: number;
    login: string;
    endorsementsCount: number;
    pointsCount: number;
    capitalsCount: number;
    position: number;
    followersCount: number;
  };
  rank?: number;
}

export function UserCard({ user, rank }: UserCardProps) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4 hover:border-gray-300 transition-colors">
      <div className="flex items-center gap-4">
        {rank !== undefined && (
          <div className="flex-shrink-0 w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
            <span className="text-sm font-bold text-gray-600">
              {rank}
            </span>
          </div>
        )}
        <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
          <span className="text-blue-600 font-medium">
            {user.login.charAt(0).toUpperCase()}
          </span>
        </div>
        <div className="flex-1 min-w-0">
          <Link
            href={`/users/${user.id}`}
            className="font-medium text-gray-900 hover:text-blue-600"
          >
            {user.login}
          </Link>
          <div className="flex items-center gap-3 text-xs text-gray-500 mt-1">
            <span>{user.endorsementsCount} endorsements</span>
            <span>{user.pointsCount} points</span>
            <span>{user.followersCount} followers</span>
          </div>
        </div>
        <div className="text-right text-sm text-gray-500">
          {user.capitalsCount > 0 && (
            <div>{user.capitalsCount} pc</div>
          )}
        </div>
      </div>
    </div>
  );
}
