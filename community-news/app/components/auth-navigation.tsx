import Link from 'next/link';
import { auth } from '@/lib/auth/server';
import { signOut } from '@/app/auth/actions';

export async function AuthNavigation() {
  const { data: session, error } = await auth.getSession();
  return <nav aria-label="Main navigation"
    className="flex flex-wrap items-center gap-4 border-b p-4">
    <Link href="/">Community News</Link>
    <Link href="/sources">Sources</Link>
    {!error && session?.user ? <>
      <span>Signed in as {session.user.name || 'Member'}</span>
      <form action={signOut}><button type="submit">Sign out</button></form>
    </> : <>
      <Link href="/auth/sign-in">Sign in</Link>
      <Link href="/auth/sign-up">Create account</Link>
    </>}
  </nav>;
}
