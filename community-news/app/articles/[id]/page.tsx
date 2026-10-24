import { z } from 'zod';
import { notFound } from 'next/navigation';
import { getArticle } from '@/lib/news';
export const dynamic = 'force-dynamic';

export default async function ArticlePage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!z.string().uuid().safeParse(id).success) notFound();
  const article = await getArticle(id);
  if (!article) notFound();
  return <main className="mx-auto max-w-3xl p-6">
    <h1 className="break-words text-3xl font-bold">{article.title}</h1>
    <p>{article.sourceName} · {article.publishedAt
          ? <time dateTime={article.publishedAt.toISOString()}>{article.publishedAt.toISOString().slice(0, 10)}</time>
          : 'Publication date unavailable'}</p>
    <p className="my-6">{article.excerpt || 'No excerpt provided.'}</p>
    <a className="underline" href={article.url} rel="noopener noreferrer">
      Read the original article
    </a>
  </main>;
}
