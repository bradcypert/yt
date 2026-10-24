import { loadEnvConfig } from '@next/env';
import { neon } from '@neondatabase/serverless';
loadEnvConfig(process.cwd());
const sql = neon(process.env.DATABASE_URL!);

async function main() {
  const [source] = await sql`
    insert into sources (name, feed_url, enabled)
    values ('Tutorial Fixture', 'https://example.com/tutorial-feed.xml', false)
    on conflict (feed_url) do update set name=excluded.name
    returning id
  `;
  const items = [
    { key: 'guid:demo-a', title: 'Demo: a new database release',
      excerpt: 'A sample story for our first discussion.', date: '2026-10-01T12:00:00Z' },
    { key: 'guid:demo-b', title: 'Demo: understanding RSS',
      excerpt: 'RSS lets a reader discover new items from a publisher.', date: null },
    { key: 'guid:demo-c', title: 'Demo: community news', excerpt: '', date: null },
  ];
  for (const item of items) {
    await sql`
      insert into articles (source_id, external_key, title, url, excerpt, published_at)
      values (${source.id}, ${item.key}, ${item.title},
        ${'https://example.com/' + item.key.replace('guid:', '')},
        ${item.excerpt}, ${item.date})
      on conflict (source_id, external_key) do nothing
    `;
  }
  console.log('Seed complete: three demo articles.');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
