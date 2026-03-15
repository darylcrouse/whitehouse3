"use client";

import { useSession } from "next-auth/react";
import { useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";

export default function NewMessagePage() {
  const { status } = useSession();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [recipientLogin, setRecipientLogin] = useState(searchParams.get("to") || "");
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (status === "unauthenticated") {
    router.push("/login");
    return null;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!recipientLogin.trim() || !title.trim()) {
      setError("Recipient and title are required.");
      return;
    }

    setSubmitting(true);
    setError("");

    // Look up recipient by login
    const searchRes = await fetch(`/api/search?type=users&q=${encodeURIComponent(recipientLogin)}`);
    const searchData = await searchRes.json();
    const recipient = searchData.results?.find(
      (u: { login: string }) => u.login.toLowerCase() === recipientLogin.toLowerCase()
    );

    if (!recipient) {
      setError("User not found.");
      setSubmitting(false);
      return;
    }

    const res = await fetch("/api/messages", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ recipientId: recipient.id, title, content }),
    });

    if (res.ok) {
      router.push("/messages?folder=sent");
    } else {
      const data = await res.json();
      setError(data.error || "Failed to send message.");
    }
    setSubmitting(false);
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">New Message</h1>

      <form onSubmit={handleSubmit} className="bg-white rounded-lg border border-gray-200 p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">To</label>
          <input
            value={recipientLogin}
            onChange={(e) => setRecipientLogin(e.target.value)}
            placeholder="Username"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Subject</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Message</label>
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            rows={6}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none resize-y"
          />
        </div>
        {error && <p className="text-sm text-red-600">{error}</p>}
        <div className="flex gap-2">
          <button
            type="submit"
            disabled={submitting}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium disabled:opacity-50"
          >
            {submitting ? "Sending..." : "Send"}
          </button>
          <button
            type="button"
            onClick={() => router.back()}
            className="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
