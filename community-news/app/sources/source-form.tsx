'use client';
import { useActionState } from "react";
import { addSource } from './actions';

export function SourceForm() {
  const [state, action, pending] = useActionState(addSource, null);
  return <form action={action} className="space-y-3">
    <label className="block">Publisher name
      <input className="block border" name="name" required maxLength={100} />
    </label>
    <label className="block">RSS feed URL
      <input className="block w-full border" name="feedUrl" type="url" required
        maxLength={2048} />
    </label>
    <p>Use an HTTPS RSS or Atom feed without embedded credentials.</p>
    <button disabled={pending}>{pending ? 'Adding…' : 'Add feed'}</button>
    <p aria-live="polite">{state?.error || (state?.success
      ? 'Feed added; articles arrive after the next import.' : '')}</p>
  </form>;
}
