# Part 3 checkpoint

Branch: `community-news/part-3`, based on Part 2 commit `33ae4d6` (tag `part-2`).

Implemented:

- Source fetch-state migration, public source list/status, authenticated add form, and navigation.
- Finished reference project's simplified HTTPS policy; removed stale approved-publisher messaging. No allowlist or custom-port restriction added.
- Bounded RSS/Atom ingestion, plain-text normalization, GUID/URL identity, conditional requests, and transactional insert/status updates.
- Scheduled Hono Function, trigger header/envelope validation, reusable pg pool, per-source advisory locks, and structured logs.
- Explicit `RSS_SCHEDULE_ENABLED` deployment switch with a 15-minute UTC cron.
- A/B and A/B/C fixtures plus a switchable dedicated publisher with ETags and a malformed-feed endpoint.
- Setup, local replay, hosted demonstration, and recording notes.

No runtime tests, hosted provisioning, or migration application were performed. Auth, ingestion, scheduling, fixture serving, concurrent deduplication, and comment preservation remain unverified at the user's request. Advisory locks still require verifying a session-preserving hosted connection.

No phase commit or `part-3` tag has been created. Review and commit this checkpoint before publishing the stack.

Completed checks: source-state-only migration generation/inspection, typecheck, ESLint, and Next.js production build all pass. Build used placeholder environment values. No live database or managed-service behavior was exercised.
