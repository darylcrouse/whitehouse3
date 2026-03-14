import Link from "next/link";

interface PaginationProps {
  page: number;
  totalPages: number;
  baseUrl: string;
}

export function Pagination({ page, totalPages, baseUrl }: PaginationProps) {
  if (totalPages <= 1) return null;

  const separator = baseUrl.includes("?") ? "&" : "?";

  return (
    <div className="flex justify-center gap-2">
      {page > 1 && (
        <Link
          href={`${baseUrl}${separator}page=${page - 1}`}
          className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50"
        >
          Previous
        </Link>
      )}
      <span className="px-4 py-2 text-sm text-gray-600">
        Page {page} of {totalPages}
      </span>
      {page < totalPages && (
        <Link
          href={`${baseUrl}${separator}page=${page + 1}`}
          className="px-4 py-2 border border-gray-300 rounded-md text-sm hover:bg-gray-50"
        >
          Next
        </Link>
      )}
    </div>
  );
}
