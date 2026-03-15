"use client";

import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";
import { useState } from "react";

interface QualityButtonsProps {
  pointId: number;
  helpfulCount: number;
  unhelpfulCount: number;
  currentVote?: number | null;
}

export function QualityButtons({
  pointId,
  helpfulCount,
  unhelpfulCount,
  currentVote,
}: QualityButtonsProps) {
  const { data: session } = useSession();
  const router = useRouter();
  const [vote, setVote] = useState(currentVote ?? null);
  const [helpful, setHelpful] = useState(helpfulCount);
  const [unhelpful, setUnhelpful] = useState(unhelpfulCount);
  const [loading, setLoading] = useState(false);

  async function handleVote(value: 1 | -1) {
    if (!session) {
      router.push("/login");
      return;
    }
    if (loading) return;
    setLoading(true);

    // Optimistic update
    const prevVote = vote;
    const prevHelpful = helpful;
    const prevUnhelpful = unhelpful;

    if (vote === value) {
      // Already voted this way, no-op
      setLoading(false);
      return;
    }

    if (vote !== null) {
      // Flipping vote
      if (value === 1) {
        setHelpful(helpful + 1);
        setUnhelpful(unhelpful - 1);
      } else {
        setHelpful(helpful - 1);
        setUnhelpful(unhelpful + 1);
      }
    } else {
      if (value === 1) setHelpful(helpful + 1);
      else setUnhelpful(unhelpful + 1);
    }
    setVote(value);

    try {
      const res = await fetch("/api/point-qualities", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pointId, value }),
      });
      if (!res.ok) {
        setVote(prevVote);
        setHelpful(prevHelpful);
        setUnhelpful(prevUnhelpful);
      }
    } catch {
      setVote(prevVote);
      setHelpful(prevHelpful);
      setUnhelpful(prevUnhelpful);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex items-center gap-2 text-xs">
      <button
        onClick={() => handleVote(1)}
        className={`flex items-center gap-1 px-2 py-0.5 rounded transition-colors ${
          vote === 1
            ? "bg-green-100 text-green-700"
            : "text-gray-500 hover:text-green-600 hover:bg-green-50"
        }`}
      >
        <span>&#9650;</span> {helpful}
      </button>
      <button
        onClick={() => handleVote(-1)}
        className={`flex items-center gap-1 px-2 py-0.5 rounded transition-colors ${
          vote === -1
            ? "bg-red-100 text-red-700"
            : "text-gray-500 hover:text-red-600 hover:bg-red-50"
        }`}
      >
        <span>&#9660;</span> {unhelpful}
      </button>
    </div>
  );
}
