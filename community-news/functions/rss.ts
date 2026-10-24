import { Hono } from 'hono';
import { Pool } from 'pg';
import { attachDatabasePool } from '@neon/functions';
import { ingestSource, type Source } from './ingest';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: 5 });
attachDatabasePool(pool);
const app = new Hono();

app.post('/scheduled', async c => {
  const invocationId = c.req.header('x-neon-trigger-invocation-id');
  if (!invocationId) return c.json({ error: 'Not a trigger call' }, 403);
  let scheduledAt: string;
  try {
    const body = await c.req.json();
    if (body.version !== 1 || body.trigger?.type !== 'schedule' ||
      typeof body.data?.scheduled_at !== 'string' ||
      Number.isNaN(Date.parse(body.data.scheduled_at))) throw new Error('Bad envelope');
    scheduledAt = body.data.scheduled_at;
  } catch {
    return c.json({ error: 'Invalid schedule payload' }, 400);
  }

  const summary = { invocationId, scheduledAt, inserted: 0, failed: 0, locked: 0 };
  const { rows } = await pool.query<Source>(`select id, feed_url, etag, last_modified
    from sources where enabled=true
    order by last_checked_at asc nulls first, id limit 10`);
  for (const source of rows) {
    const client = await pool.connect();
    let locked = false;
    let destroy = false;
    try {
      const result = await client.query<{ locked: boolean }>(
        'select pg_try_advisory_lock(hashtextextended($1, 0)) as locked',
        [`rss:${source.id}`]);
      locked = result.rows[0].locked;
      if (!locked) { summary.locked++; continue; }
      // Re-read after locking: another run may have advanced its validators.
      const fresh = await client.query<Source>(
        'select id, feed_url, etag, last_modified from sources where id=$1 and enabled=true',
        [source.id]);
      if (!fresh.rows.length) continue;
      const outcome = await ingestSource(client, fresh.rows[0]);
      summary.inserted += outcome.inserted;
      console.log(JSON.stringify({ invocationId, sourceId: source.id, ...outcome }));
    } catch (error) {
      summary.failed++;
      const message = error instanceof Error ? error.message : 'Import failed';
      console.error(JSON.stringify({ invocationId, sourceId: source.id, error: message }));
      try {
        await client.query(`update sources set last_checked_at=now(), last_error=$2,
          consecutive_failures=consecutive_failures+1 where id=$1`,
          [source.id, message.slice(0, 500)]);
      } catch { destroy = true; }
    } finally {
      if (locked && !destroy) {
        try {
          await client.query('select pg_advisory_unlock(hashtextextended($1, 0))',
            [`rss:${source.id}`]);
        } catch { destroy = true; }
      }
      client.release(destroy);
    }
  }
  console.log(JSON.stringify(summary));
  return c.json(summary);
});

export default app;
