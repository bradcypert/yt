import type { Metadata } from 'next';
import Link from 'next/link';
import './globals.css';

export const metadata: Metadata = {
  title: 'Community News',
  description: 'A shared news reader built with Next.js and Neon.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body className="min-h-screen">
    <nav aria-label="Main navigation" className="border-b p-4">
      <Link href="/" className="font-bold">Community News</Link>
    </nav>
    {children}
  </body></html>;
}
