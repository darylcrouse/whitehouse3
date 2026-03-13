import Link from "next/link";

export default function Home() {
  return (
    <div className="space-y-8">
      {/* Hero */}
      <section className="text-center py-12">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          White House 3
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto mb-8">
          A democratic platform where citizens submit, discuss, and vote on
          policy priorities. Make your voice heard.
        </p>
        <div className="flex gap-4 justify-center">
          <Link
            href="/priorities"
            className="bg-blue-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-blue-700"
          >
            Browse Priorities
          </Link>
          <Link
            href="/register"
            className="border border-gray-300 text-gray-700 px-6 py-3 rounded-lg font-medium hover:bg-gray-50"
          >
            Get Started
          </Link>
        </div>
      </section>

      {/* How it works */}
      <section className="grid md:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center mb-4">
            <span className="text-blue-600 font-bold text-lg">1</span>
          </div>
          <h3 className="font-semibold text-gray-900 mb-2">
            Submit Priorities
          </h3>
          <p className="text-sm text-gray-600">
            Propose policy priorities that matter to you. Each priority is a
            clear statement of what you believe should be addressed.
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center mb-4">
            <span className="text-green-600 font-bold text-lg">2</span>
          </div>
          <h3 className="font-semibold text-gray-900 mb-2">
            Endorse &amp; Oppose
          </h3>
          <p className="text-sm text-gray-600">
            Vote on priorities by endorsing or opposing them. Rank your top
            priorities to maximize your influence.
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
            <span className="text-purple-600 font-bold text-lg">3</span>
          </div>
          <h3 className="font-semibold text-gray-900 mb-2">
            Discuss &amp; Debate
          </h3>
          <p className="text-sm text-gray-600">
            Contribute points supporting or opposing priorities. Provide
            evidence and engage in structured debate.
          </p>
        </div>
      </section>

      {/* Quick links */}
      <section className="bg-white rounded-lg border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Explore</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Link
            href="/priorities?sort=top"
            className="text-center p-4 rounded-lg bg-gray-50 hover:bg-gray-100"
          >
            <div className="font-medium text-gray-900">Top Ranked</div>
            <div className="text-sm text-gray-500">Most endorsed</div>
          </Link>
          <Link
            href="/priorities?sort=rising"
            className="text-center p-4 rounded-lg bg-gray-50 hover:bg-gray-100"
          >
            <div className="font-medium text-gray-900">Rising</div>
            <div className="text-sm text-gray-500">Gaining momentum</div>
          </Link>
          <Link
            href="/priorities?sort=controversial"
            className="text-center p-4 rounded-lg bg-gray-50 hover:bg-gray-100"
          >
            <div className="font-medium text-gray-900">Controversial</div>
            <div className="text-sm text-gray-500">Hotly debated</div>
          </Link>
          <Link
            href="/priorities?sort=newest"
            className="text-center p-4 rounded-lg bg-gray-50 hover:bg-gray-100"
          >
            <div className="font-medium text-gray-900">Newest</div>
            <div className="text-sm text-gray-500">Recently added</div>
          </Link>
        </div>
      </section>
    </div>
  );
}
