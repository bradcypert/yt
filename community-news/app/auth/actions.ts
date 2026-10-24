'use server';
import { z } from 'zod';
import { redirect } from 'next/navigation';
import { auth } from '@/lib/auth/server';

type FormState = { error?: string } | null;
const loginInput = z.object({
  email: z.string().trim().email(),
  password: z.string().min(1),
});
const signupInput = loginInput.extend({
  name: z.string().trim().min(1).max(80),
  password: z.string().min(8),
});

export async function signUp(_: FormState, form: FormData) {
  const input = signupInput.safeParse(Object.fromEntries(form));
  if (!input.success) return { error: 'Check your name, email, and password.' };
  const { error } = await auth.signUp.email(input.data);
  if (error) return { error: error.message || 'Could not create account.' };
  redirect('/');
}

export async function signIn(_: FormState, form: FormData) {
  const input = loginInput.safeParse(Object.fromEntries(form));
  if (!input.success) return { error: 'Enter your email and password.' };
  const { error } = await auth.signIn.email(input.data);
  if (error) return { error: 'Could not sign in. Check your details.' };
  redirect('/');
}

export async function signOut() {
  await auth.signOut();
  redirect('/');
}
