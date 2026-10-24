import type { Metadata } from 'next';
import { AuthNavigation } from './components/auth-navigation';
import './globals.css';

export const dynamic = 'force-dynamic';

export const metadata: Metadata = {
  title: 'Community News',
  description: 'A shared news reader built with Next.js and Neon.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body className="min-h-screen">
    <AuthNavigation />
    {children}
  </body></html>;
}
