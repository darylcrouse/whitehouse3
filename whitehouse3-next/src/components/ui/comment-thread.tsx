import Link from "next/link";
import { CommentForm } from "./comment-form";

interface Comment {
  id: number;
  content: string | null;
  isEndorser: boolean;
  isOpposer: boolean;
  createdAt: string | Date;
  user: { id: number; login: string };
}

interface CommentThreadProps {
  activityId: number;
  comments: Comment[];
  totalCount: number;
  showForm?: boolean;
}

export function CommentThread({
  activityId,
  comments,
  totalCount,
  showForm = true,
}: CommentThreadProps) {
  return (
    <div className="space-y-2">
      {comments.map((comment) => (
        <div key={comment.id} className="text-sm pl-4 border-l-2 border-gray-100">
          <div className="flex items-center gap-2">
            <Link
              href={`/users/${comment.user.id}`}
              className="font-medium text-gray-900 hover:text-blue-600"
            >
              {comment.user.login}
            </Link>
            {comment.isEndorser && (
              <span className="text-xs px-1.5 py-0.5 bg-green-50 text-green-700 rounded">
                endorser
              </span>
            )}
            {comment.isOpposer && (
              <span className="text-xs px-1.5 py-0.5 bg-red-50 text-red-700 rounded">
                opposer
              </span>
            )}
            <span className="text-xs text-gray-400">
              {new Date(comment.createdAt).toLocaleDateString()}
            </span>
          </div>
          <p className="text-gray-600 mt-0.5">{comment.content}</p>
        </div>
      ))}
      {totalCount > comments.length && (
        <div className="text-xs text-blue-600 pl-4">
          View all {totalCount} comments
        </div>
      )}
      {showForm && <CommentForm activityId={activityId} />}
    </div>
  );
}
