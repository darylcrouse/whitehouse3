"use client";

import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";
import { useState } from "react";

interface PointFormProps {
  priorityId: number;
  defaultValue?: 1 | -1 | 0;
}

export function PointForm({ priorityId, defaultValue = 1 }: PointFormProps) {
  const { data: session } = useSession();
  const router = useRouter();
  const [name, setName] = useState("");
  const [content, setContent] = useState("");
  const [value, setValue] = useState<1 | -1 | 0>(defaultValue);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [open, setOpen] = useState(false);

  if (!session) return null;

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className="text-sm text-blue-600 hover:underline"
      >
        + Add a point
      </button>
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) {
      setError("Point title is required.");
      return;
    }
    setSubmitting(true);
    setError("");
    try {
      const res = await fetch("/api/points", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ priorityId, name: name.trim(), content, value }),
      });
      if (res.ok) {
        setName("");
        setContent("");
        setOpen(false);
        router.refresh();
      } else {
        const data = await res.json();
        setError(data.error || "Failed to create point.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="bg-gray-50 rounded-lg p-4 space-y-3">
      <div className="flex gap-2">
        {([1, -1, 0] as const).map((v) => (
          <button
            key={v}
            type="button"
            onClick={() => setValue(v)}
            className={`px-3 py-1 rounded text-xs font-medium transition-colors ${
              value === v
                ? v === 1
                  ? "bg-green-600 text-white"
                  : v === -1
                    ? "bg-red-600 text-white"
                    : "bg-gray-600 text-white"
                : "bg-white border border-gray-300 text-gray-600 hover:bg-gray-100"
            }`}
          >
            {v === 1 ? "Supporting" : v === -1 ? "Opposing" : "Neutral"}
          </button>
        ))}
      </div>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Point title"
        className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
      />
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="Details (optional)"
        rows={3}
        className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none resize-y"
      />
      {error && <p className="text-xs text-red-600">{error}</p>}
      <div className="flex gap-2">
        <button
          type="submit"
          disabled={submitting}
          className="px-4 py-1.5 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 disabled:opacity-50"
        >
          {submitting ? "Adding..." : "Add Point"}
        </button>
        <button
          type="button"
          onClick={() => setOpen(false)}
          className="px-4 py-1.5 border border-gray-300 rounded-md text-sm hover:bg-gray-50"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
