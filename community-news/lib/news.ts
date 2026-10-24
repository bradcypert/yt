import 'server-only';
import { desc, eq } from 'drizzle-orm';
import { db } from './db/client';
import { articles, sources } from './db/schema';

export function listArticles() {
  return db.select({
    id: articles.id, title: articles.title, excerpt: articles.excerpt,
    sourceName: sources.name, publishedAt: articles.publishedAt,
  }).from(articles)
    .innerJoin(sources, eq(articles.sourceId, sources.id))
    .orderBy(desc(articles.ingestedAt), desc(articles.id)).limit(30);
}

export async function getArticle(id: string) {
  const [article] = await db.select({
    id: articles.id, title: articles.title, excerpt: articles.excerpt,
    url: articles.url, sourceName: sources.name,
    publishedAt: articles.publishedAt,
  }).from(articles).innerJoin(sources, eq(articles.sourceId, sources.id))
    .where(eq(articles.id, id)).limit(1);
  return article;
}
