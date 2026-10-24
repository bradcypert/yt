import Link from 'next/link';
import { asc } from 'drizzle-orm';
import { auth } from '@/lib/auth/server';
import { db } from '@/lib/db/client';
import { sources } from '@/lib/db/schema';
import { SourceForm } from './source-form';
export const dynamic = 'force-dynamic';

export default async function SourcesPage() {
  const [sessionResult, rows] = await Promise.all([
    auth.getSession(), db.select().from(sources).orderBy(asc(sources.name)).limit(100),
  ]);
  return <main className="mx-auto max-w-3xl space-y-6 p-6">
    <h1>News sources</h1>
    {sessionResult.data?.user ? <SourceForm />
      : <Link href="/auth/sign-in">Sign in to add a feed</Link>}
    {!rows.length && <p>No sources registered yet.</p>}
    <ul>{rows.map(source => <li key={source.id} className="my-4 rounded border p-4">
      <h2>{source.name}</h2><p className="break-all">{source.feedUrl}</p>
      <p>{!source.enabled ? 'Disabled' : source.lastError
        ? `Import failed (${source.consecutiveFailures} consecutive failures)`
        : source.lastSuccessAt
          ? `Last successful check: ${source.lastSuccessAt.toISOString()}`
          : 'Waiting for first import'}</p>
    </li>)}</ul>
    {rows.length === 100 && <p>Showing up to 100 sources.</p>}
  </main>;
}
