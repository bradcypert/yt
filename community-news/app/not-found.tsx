import Link from 'next/link';

export default function NotFound() {
  return <main className="mx-auto max-w-3xl space-y-4 p-6">
    <h1 className="text-3xl font-bold">Article not found</h1>
    <p>This article may have moved or does not exist.</p>
    <Link href="/" className="underline">Back to the news</Link>
  </main>;
}
