import Link from 'next/link';
import { listArticles } from '@/lib/news';
export const dynamic = 'force-dynamic';

export default async function Home() {
  const articles = await listArticles();
  return <main className="mx-auto max-w-3xl p-6">
    <h1 className="break-words text-3xl font-bold">Community News</h1>
    {!articles.length && <p>No articles yet.</p>}
    <ul className="mt-6 space-y-5">{articles.map(article =>
      <li key={article.id} className="rounded border p-4">
        <Link className="break-words text-xl underline" href={`/articles/${article.id}`}>
          {article.title}
        </Link>
        <p>{article.sourceName} · {article.publishedAt
          ? <time dateTime={article.publishedAt.toISOString()}>{article.publishedAt.toISOString().slice(0, 10)}</time>
          : 'Publication date unavailable'}</p>
        <p>{article.excerpt || 'No excerpt provided.'}</p>
      </li>
    )}</ul>
  </main>;
}
