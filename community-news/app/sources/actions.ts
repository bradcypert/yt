'use server';
import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { auth } from '@/lib/auth/server';
import { db } from '@/lib/db/client';
import { sources } from '@/lib/db/schema';
import { normalizeFeedUrl } from '@/lib/feed-policy';

type SourceState = { error?: string; success?: boolean } | null;
export async function addSource(_: SourceState, form: FormData) {
  const { data: session, error } = await auth.getSession();
  if (error || !session?.user) return { error: 'Sign in to add a feed.' };
  const input = z.object({
    name: z.string().trim().min(1).max(100),
    feedUrl: z.string().trim().min(1).max(2048),
  }).safeParse(Object.fromEntries(form));
  if (!input.success) return { error: 'Provide a feed name and URL.' };
  let feedUrl: string;
  try {
    feedUrl = normalizeFeedUrl(input.data.feedUrl);
  } catch {
    return { error: 'Use an HTTPS feed URL without embedded credentials.' };
  }
  const inserted = await db.insert(sources).values({
    name: input.data.name, feedUrl, addedBy: session.user.id,
  }).onConflictDoNothing({ target: sources.feedUrl }).returning({ id: sources.id });
  if (!inserted.length) return { error: 'That feed is already registered.' };
  revalidatePath('/sources');
  return { success: true };
}
