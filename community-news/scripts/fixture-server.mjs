import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

// Serve behind your own HTTPS reverse proxy for the deployed importer.
// Change fixtures/active-version between v1 and v2 while this process runs.
const root = new URL('../fixtures/', import.meta.url);
const port = Number(process.env.FIXTURE_PORT || 8788);

createServer(async (request, response) => {
  if (request.method !== 'GET') {
    response.writeHead(405, { Allow: 'GET' }).end();
    return;
  }
  if (request.url === '/bad.xml') {
    response.writeHead(200, { 'Content-Type': 'application/xml' });
    response.end('<rss><broken>');
    return;
  }
  if (request.url !== '/feed.xml') {
    response.writeHead(404).end('Not found');
    return;
  }
  try {
    const version = await readFile(new URL('active-version', root), 'utf8')
      .then(value => value.trim()).catch(() => 'v1');
    if (!['v1', 'v2'].includes(version)) throw new Error('Use v1 or v2');
    const xml = await readFile(new URL(`feed-${version}.xml`, root));
    const etag = `"${createHash('sha256').update(xml).digest('hex')}"`;
    response.setHeader('ETag', etag);
    response.setHeader('Cache-Control', 'no-cache');
    if (request.headers['if-none-match'] === etag) {
      response.writeHead(304).end();
      return;
    }
    response.writeHead(200, { 'Content-Type': 'application/rss+xml; charset=utf-8' });
    response.end(xml);
  } catch (error) {
    console.error(error);
    response.writeHead(500).end('Fixture unavailable');
  }
}).listen(port, '127.0.0.1', () => {
  console.log(`Fixture publisher: http://127.0.0.1:${port}/feed.xml (use HTTPS for ingestion)`);
});
