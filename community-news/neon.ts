import { defineConfig } from '@neon/config/v1';

export default defineConfig({
  auth: true,
  functions: {
    rsssync: { name: 'RSS article importer', source: './functions/rss.ts' },
  },
  triggers: {
    'rss-every-15-minutes': {
      type: 'schedule', function: 'rsssync', functionPath: '/scheduled',
      cron: '*/15 * * * *', enabled: process.env.RSS_SCHEDULE_ENABLED === 'true',
    },
  },
  branch: (branch) => {
    if (!branch.isDefault && !branch.exists) return { ttl: '7d' };
    return {};
  },
});
