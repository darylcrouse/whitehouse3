"use client";

import { useState } from "react";
import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";

interface EndorsementButtonProps {
  priorityId: number;
  upCount: number;
  downCount: number;
  /** Current user's endorsement: 1 = endorsed, -1 = opposed, null = none */
  currentValue?: number | null;
}

export function EndorsementButton({
  priorityId,
  upCount: initialUpCount,
  downCount: initialDownCount,
  currentValue: initialValue = null,
}: EndorsementButtonProps) {
  const { data: session } = useSession();
  const router = useRouter();
  const [currentValue, setCurrentValue] = useState(initialValue);
  const [upCount, setUpCount] = useState(initialUpCount);
  const [downCount, setDownCount] = useState(initialDownCount);
  const [loading, setLoading] = useState(false);

  async function handleEndorse(value: 1 | -1) {
    if (!session) {
      router.push("/login");
      return;
    }
    if (loading) return;
    setLoading(true);

    try {
      if (currentValue === value) {
        // Remove endorsement
        await fetch("/api/endorsements", {
          method: "DELETE",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ priorityId }),
        });
        if (value === 1) setUpCount((c) => c - 1);
        else setDownCount((c) => c - 1);
        setCurrentValue(null);
      } else {
        // Create or flip endorsement
        await fetch("/api/endorsements", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ priorityId, value }),
        });
        if (currentValue === 1) setUpCount((c) => c - 1);
        if (currentValue === -1) setDownCount((c) => c - 1);
        if (value === 1) setUpCount((c) => c + 1);
        else setDownCount((c) => c + 1);
        setCurrentValue(value);
      }
    } catch {
      // Revert on error
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col gap-1">
      <button
        onClick={() => handleEndorse(1)}
        disabled={loading}
        className={`px-3 py-1 text-xs font-medium border rounded transition-colors ${
          currentValue === 1
            ? "bg-green-600 text-white border-green-600"
            : "bg-green-50 text-green-700 border-green-200 hover:bg-green-100"
        } ${loading ? "opacity-50 cursor-not-allowed" : ""}`}
      >
        +{upCount}
      </button>
      <button
        onClick={() => handleEndorse(-1)}
        disabled={loading}
        className={`px-3 py-1 text-xs font-medium border rounded transition-colors ${
          currentValue === -1
            ? "bg-red-600 text-white border-red-600"
            : "bg-red-50 text-red-700 border-red-200 hover:bg-red-100"
        } ${loading ? "opacity-50 cursor-not-allowed" : ""}`}
      >
        -{downCount}
      </button>
    </div>
  );
}
