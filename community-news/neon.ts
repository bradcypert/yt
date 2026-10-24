import { defineConfig } from '@neon/config/v1';

export default defineConfig({
  auth: true,
  branch: (branch) => {
    if (!branch.isDefault && !branch.exists) return { ttl: '7d' };
    return {};
  },
});
