'use client';
import { useActionState } from 'react';
import { signIn, signUp } from './actions';

export function AuthForm({ mode }: { mode: 'sign-in' | 'sign-up' }) {
  const creating = mode === 'sign-up';
  const [state, action, pending] = useActionState(creating ? signUp : signIn, null);
  return <form action={action} className="mx-auto max-w-md space-y-4 p-6">
    <h1>{creating ? 'Create account' : 'Sign in'}</h1>
    {creating && <label className="block">Name
      <input className="block border" name="name" required maxLength={80}
        autoComplete="name" />
    </label>}
    <label className="block">Email
      <input className="block border" name="email" type="email" required
        autoComplete="email" />
    </label>
    <label className="block">Password
      <input className="block border" name="password" type="password" required
        minLength={creating ? 8 : 1}
        autoComplete={creating ? 'new-password' : 'current-password'} />
    </label>
    <button disabled={pending}>{pending ? 'Working…' : creating ? 'Create account' : 'Sign in'}</button>
    <p aria-live="polite">{state?.error}</p>
  </form>;
}
