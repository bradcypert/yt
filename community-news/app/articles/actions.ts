'use server';
import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { eq } from 'drizzle-orm';
import { auth } from '@/lib/auth/server';
import { db } from '@/lib/db/client';
import { articles, comments } from '@/lib/db/schema';

type CommentState = { error?: string; success?: boolean } | null;
const inputSchema = z.object({
  articleId: z.string().uuid(),
  body: z.string().trim().min(1).max(2000),
});

export async function addComment(_: CommentState, form: FormData) {
  const { data: session, error } = await auth.getSession();
  if (error || !session?.user) return { error: 'Sign in to comment.' };
  const input = inputSchema.safeParse(Object.fromEntries(form));
  if (!input.success) return { error: 'Write a comment between 1 and 2,000 characters.' };
  const [article] = await db.select({ id: articles.id }).from(articles)
    .where(eq(articles.id, input.data.articleId)).limit(1);
  if (!article) return { error: 'This article no longer exists.' };
  await db.insert(comments).values({
    articleId: input.data.articleId,
    body: input.data.body,
    authorId: session.user.id,
    authorName: session.user.name || 'Member',
  });
  revalidatePath(`/articles/${input.data.articleId}`);
  revalidatePath('/');
  return { success: true };
}
