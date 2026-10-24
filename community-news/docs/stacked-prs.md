# Stacked tutorial changes

All branches belong to the existing `yt` repository. The three names are reserved at the initial base; later branch tips must advance after each reviewed phase is committed. Reserving the names alone does not establish the final stack.

| Phase | Branch | PR base | Scope |
| --- | --- | --- | --- |
| 1 | `community-news/part-1` | `main` | Reader, source/article schema, seed, backend config |
| 2 | `community-news/part-2` | `community-news/part-1` | Managed auth, session navigation, comments migration and forms |
| 3 | `community-news/part-3` | `community-news/part-2` | Source management, fetch-state migration, RSS Function and fixtures |

The `starter` tag marks the unchanged starting commit. At each checkpoint, review the diff, commit the phase, and add its `part-N` tag. From the `yt` repository root, Part 1 is:

```sh
git add community-news
git commit -m "Build community news reader with Neon Postgres"
git tag part-1
```

After that commit, advance the reserved next branch by fast-forwarding it before implementing the next phase:

```sh
git switch community-news/part-2
git merge --ff-only community-news/part-1
```

Implement/review Part 2, commit, and tag `part-2`. Then:

```sh
git switch community-news/part-3
git merge --ff-only community-news/part-2
```

Implement/review Part 3, commit, and tag `part-3`. Open each PR with the base listed above so its diff shows only that episode. Push branches/tags when ready. No PRs are opened automatically.

Part 2 originally specified an intermediate local auth checkpoint; the user explicitly skipped it. Managed-service behavior remains unverified. Keep the auth and database URLs paired to the same Neon branch.

Part 3 must include the controlled A/B → A/B/C fixture demonstration, comment preservation on repeat import, failure isolation, bounded fetches, 304 handling, concurrent insert protection, and hosted trigger verification. Verify session-preserving connections before using advisory locks. Keep the production cron at 15 minutes; explicitly disable unused schedules with `enabled: false` and deploy. A local replay does not prove hosted scheduling.

Each phase owns its generated migration and README updates. Keep Part 1's seed independent of auth and fetch-state columns. Never copy the finished source's single final-schema migration into Part 1.

Part 3 follows the finished reference project’s simplified HTTPS feed policy instead of the handbook’s publisher allowlist. See `rss-rehearsal.md` for the exact difference and deployment controls.
