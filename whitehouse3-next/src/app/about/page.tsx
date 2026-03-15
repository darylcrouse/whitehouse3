import Link from "next/link";

export default function AboutPage() {
  return (
    <div className="max-w-3xl mx-auto space-y-8">
      <h1 className="text-3xl font-bold text-gray-900">About</h1>

      <div className="prose prose-lg max-w-none">
        <p className="text-gray-600 text-lg">
          This platform is a citizen-powered priority-setting tool that helps
          communities identify, discuss, and rank the issues that matter most.
        </p>

        <h2 className="text-xl font-semibold text-gray-900 mt-8">How It Works</h2>

        <div className="grid gap-6 md:grid-cols-3 not-prose mt-4">
          <div className="bg-white rounded-lg border border-gray-200 p-5">
            <div className="text-2xl font-bold text-blue-600 mb-2">1</div>
            <h3 className="font-semibold text-gray-900 mb-1">Submit Priorities</h3>
            <p className="text-sm text-gray-600">
              Add the issues you think should be top priorities. Be specific and actionable.
            </p>
          </div>
          <div className="bg-white rounded-lg border border-gray-200 p-5">
            <div className="text-2xl font-bold text-blue-600 mb-2">2</div>
            <h3 className="font-semibold text-gray-900 mb-1">Endorse &amp; Discuss</h3>
            <p className="text-sm text-gray-600">
              Endorse or oppose priorities. Add supporting or opposing points to make your case.
            </p>
          </div>
          <div className="bg-white rounded-lg border border-gray-200 p-5">
            <div className="text-2xl font-bold text-blue-600 mb-2">3</div>
            <h3 className="font-semibold text-gray-900 mb-1">See the Rankings</h3>
            <p className="text-sm text-gray-600">
              Priorities are ranked by community support, creating a transparent agenda.
            </p>
          </div>
        </div>

        <h2 className="text-xl font-semibold text-gray-900 mt-8">Features</h2>
        <ul className="text-gray-600 space-y-2 mt-4">
          <li><strong>Priority Ranking</strong> &mdash; Community-driven scoring based on endorsements and activity</li>
          <li><strong>Points System</strong> &mdash; Supporting and opposing arguments for every priority</li>
          <li><strong>User Reputation</strong> &mdash; Capital earned through participation and contributions</li>
          <li><strong>Issue Tags</strong> &mdash; Browse priorities organized by topic area</li>
          <li><strong>Activity Feed</strong> &mdash; Follow what&apos;s happening across the community</li>
          <li><strong>Social Network</strong> &mdash; Follow other users and see their priorities</li>
        </ul>
      </div>

      <div className="flex gap-4 pt-4">
        <Link
          href="/priorities"
          className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
        >
          Browse Priorities
        </Link>
        <Link
          href="/register"
          className="px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 text-gray-700 font-medium"
        >
          Join the Community
        </Link>
      </div>
    </div>
  );
}
