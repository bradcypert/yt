import Link from 'next/link';
import { z } from 'zod';
import { notFound } from 'next/navigation';
import { asc, eq } from 'drizzle-orm';
import { getArticle } from '@/lib/news';
import { auth } from '@/lib/auth/server';
import { db } from '@/lib/db/client';
import { comments } from '@/lib/db/schema';
import { CommentForm } from '../comment-form';
export const dynamic = 'force-dynamic';

export default async function ArticlePage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!z.string().uuid().safeParse(id).success) notFound();
  const article = await getArticle(id);
  if (!article) notFound();
  const [sessionResult, discussion] = await Promise.all([
    auth.getSession(),
    db.select().from(comments).where(eq(comments.articleId, id))
      .orderBy(asc(comments.createdAt), asc(comments.id)).limit(101),
  ]);
  const visible = discussion.slice(0, 100);
  return <main className="mx-auto max-w-3xl p-6">
    <h1 className="break-words text-3xl font-bold">{article.title}</h1>
    <p>{article.sourceName} · {article.publishedAt
      ? <time dateTime={article.publishedAt.toISOString()}>{article.publishedAt.toISOString().slice(0, 10)}</time>
      : 'Publication date unavailable'}</p>
    <p className="my-6">{article.excerpt || 'No excerpt provided.'}</p>
    <a className="underline" href={article.url} rel="noopener noreferrer">
      Read the original article
    </a>
    <section className="mt-8" aria-labelledby="comments-heading">
      <h2 id="comments-heading">Discussion</h2>
      {!visible.length && <p>No comments yet. Start the conversation.</p>}
      <ol className="space-y-4">{visible.map(comment =>
        <li key={comment.id} className="rounded border p-4">
          <p>{comment.authorName} · <time dateTime={comment.createdAt.toISOString()}>
            {comment.createdAt.toISOString().slice(0, 16).replace('T', ' ')} UTC
          </time></p>
          <p className="whitespace-pre-wrap break-words">{comment.body}</p>
        </li>
      )}</ol>
      {discussion.length > 100 && <p>Showing the first 100 comments.</p>}
      {sessionResult.data?.user
        ? <CommentForm articleId={id} />
        : <Link href="/auth/sign-in">Sign in to comment</Link>}
    </section>
  </main>;
}
