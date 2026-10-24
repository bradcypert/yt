'use client';
import { useActionState } from 'react';
import { addComment } from './actions';

export function CommentForm({ articleId }: { articleId: string }) {
  const [state, action, pending] = useActionState(addComment, null);
  return <form action={action} className="mt-6 space-y-3">
    <input type="hidden" name="articleId" value={articleId} />
    <label htmlFor="comment">Add a comment</label>
    <textarea id="comment" name="body" required maxLength={2000}
      className="block w-full rounded border p-3" />
    <button disabled={pending} type="submit">
      {pending ? 'Posting…' : 'Post comment'}
    </button>
    <p aria-live="polite">{state?.error || (state?.success ? 'Comment posted.' : '')}</p>
  </form>;
}
