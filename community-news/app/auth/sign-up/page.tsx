import Link from 'next/link';
import { AuthForm } from '../auth-form';

export default function SignUpPage() {
  return <main>
    <AuthForm mode="sign-up" />
    <p className="text-center">
      Already have an account? <Link href="/auth/sign-in">Sign in</Link>
    </p>
  </main>;
}
