import Parser from 'rss-parser';
import { convert } from 'html-to-text';
import type { PoolClient } from 'pg';
import { normalizeFeedUrl } from '../lib/feed-policy';

const parser = new Parser();
const MAX_BYTES = 2 * 1024 * 1024;
const MAX_ITEMS = 100;

export type Source = {
  id: string; feed_url: string;
  etag: string | null; last_modified: string | null;
};

async function readBounded(response: Response) {
  const declared = Number(response.headers.get('content-length'));
  if (declared > MAX_BYTES) throw new Error('Feed exceeds size limit');
  if (!response.body) throw new Error('Feed has no body');
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > MAX_BYTES) throw new Error('Feed exceeds size limit');
      chunks.push(value);
    }
  } finally {
    await reader.cancel().catch(() => { });
    reader.releaseLock();
  }
  return Buffer.concat(chunks).toString('utf8');
}

export async function ingestSource(client: PoolClient, source: Source) {
  const feedUrl = normalizeFeedUrl(source.feed_url);
  const headers: Record<string, string> = {
    'User-Agent': 'CommunityNewsTutorial/1.0',
    Accept: 'application/rss+xml, application/atom+xml, application/xml, text/xml',
  };
  if (source.etag) headers['If-None-Match'] = source.etag;
  if (source.last_modified) headers['If-Modified-Since'] = source.last_modified;
  const response = await fetch(feedUrl, {
    headers, redirect: 'error', signal: AbortSignal.timeout(10_000),
  });
  if (response.status === 304) {
    await client.query(`update sources set last_checked_at=now(),
      last_success_at=now(), last_error=null, consecutive_failures=0 where id=$1`,
      [source.id]);
    return { inserted: 0, skipped: 0, notModified: true };
  }
  if (!response.ok) throw new Error(`Feed HTTP ${response.status}`);
  const xml = await readBounded(response);
  if (/<!DOCTYPE|<!ENTITY/i.test(xml)) throw new Error('DTD feeds are unsupported');
  const feed = await parser.parseString(xml);
  let inserted = 0;
  let skipped = 0;
  await client.query('BEGIN');
  try {
    for (const item of feed.items.slice(0, MAX_ITEMS)) {
      let link: URL;
      try {
        if (!item.link) throw new Error('Missing link');
        link = new URL(item.link, feedUrl);
        if (!['https:', 'http:'].includes(link.protocol) || link.username || link.password) {
          throw new Error('Invalid article link');
        }
        link.hash = '';
        if (link.toString().length > 4096) throw new Error('Article URL too long');
      } catch { skipped++; continue; }
      const title = convert(item.title || '', { wordwrap: false }).trim().slice(0, 300);
      if (!title) { skipped++; continue; }
      const guid = item.guid?.trim();
      const key = guid ? `guid:${guid}` : `url:${link.toString()}`;
      if (key.length > 4096) { skipped++; continue; }
      const rawDate = item.isoDate || item.pubDate;
      const parsedDate = rawDate ? new Date(rawDate) : null;
      const publishedAt = parsedDate && !Number.isNaN(parsedDate.getTime())
        ? parsedDate : null;
      const excerpt = convert(item.contentSnippet || item.content || '', {
        wordwrap: false, selectors: [{ selector: 'a', options: { ignoreHref: true } }],
      }).trim().slice(0, 1000);
      const result = await client.query(`insert into articles
        (source_id, external_key, title, url, excerpt, published_at)
        values ($1,$2,$3,$4,$5,$6)
        on conflict (source_id, external_key) do nothing returning id`,
        [source.id, key, title, link.toString(), excerpt, publishedAt]);
      inserted += result.rowCount || 0;
    }
    await client.query(`update sources set etag=$2, last_modified=$3,
      last_checked_at=now(), last_success_at=now(), last_error=null,
      consecutive_failures=0 where id=$1`,
      [source.id, response.headers.get('etag'), response.headers.get('last-modified')]);
    await client.query('COMMIT');
    return { inserted, skipped, notModified: false };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  }
}
