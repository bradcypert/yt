import Link from 'next/link';
import { AuthForm } from '../auth-form';

export default function SignInPage() {
  return <main>
    <AuthForm mode="sign-in" />
    <p className="text-center">
      Need an account? <Link href="/auth/sign-up">Create one</Link>
    </p>
  </main>;
}
