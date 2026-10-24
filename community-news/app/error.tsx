'use client';

export default function ErrorPage({ reset }: { reset: () => void }) {
  return <main className="mx-auto max-w-3xl space-y-4 p-6">
    <h1 className="text-3xl font-bold">Could not load the news</h1>
    <p>Please try again in a moment.</p>
    <button className="rounded border px-4 py-2" onClick={reset}>Try again</button>
  </main>;
}
