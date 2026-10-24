# Community News — Part 3

A shared news reader built with Next.js, Drizzle, and Neon Postgres. Part 1 is committed and tagged. Part 2 adds managed auth, signup/signin pages, session navigation, and shared article discussions. Part 3 adds source management and a scheduled RSS importer.

Our backend is declared in neon.ts and deployed with neon deploy. Our Next.js app connects to that backend and runs on Vercel.

## Part 3 setup

Current branch: `community-news/part-3`, based on the committed/tagged Part 2. Sources are listed publicly at `/sources`; members can register a feed for import on the next scheduled run. Status shows last success or a generic failure with a consecutive failure count.

Apply migrations with `npm run db:migrate`, then follow [RSS deployment and fixture instructions](docs/rss-rehearsal.md). Set `RSS_SCHEDULE_ENABLED=true` for the intended deployment and run `neon deploy --env .env.local`. The schedule is disabled by default until explicitly enabled. No deployment or migration application was performed here.

This version matches the finished reference project's URL policy: HTTPS without embedded credentials, no publisher allowlist or custom-port restriction, and redirects rejected by the worker. No `RSS_ALLOWED_HOSTS` setting is used. This permits internal HTTPS requests and is not an SSRF defense.

The Function checks up to 10 least-recently-checked enabled sources per tick, processes up to 100 items per feed, stores plain-text metadata, and uses `(source_id, external_key)` conflict handling to preserve existing articles and comments. It handles conditional requests and records per-source failures without stopping other feeds. Session advisory locks require a session-preserving database connection; confirm that before hosted use.

## Part 2 setup

Part 2 is committed and tagged as `part-2`. Auth and comments were implemented together in that checkpoint. The local auth checkpoint was skipped at your request; managed-service behavior remains unverified.

1. Run `npm ci`. In `.env.local`, keep `DATABASE_URL` for your intended demo Neon branch.
2. Run `npm run backend:plan` and `npm run backend:deploy` to enable `auth: true` on that linked branch.
3. Set `NEON_AUTH_BASE_URL` from that branch's Auth configuration. This is the hosted Auth URL, not localhost.
4. Run `openssl rand -base64 32` privately and save its output as `NEON_AUTH_COOKIE_SECRET` in `.env.local`. The secret must be at least 32 characters. `.env.example` contains placeholders only.
5. Enable **Allow Localhost** in the branch's Auth configuration and run/restart `npm run dev`.
6. Open http://localhost:3000/auth/sign-up, create a demo account, and confirm the navigation shows the member name.
7. Sign out, sign back in at http://localhost:3000/auth/sign-in, and test an incorrect password. Expect an inline error without navigating away.

Keep `DATABASE_URL` and `NEON_AUTH_BASE_URL` on the same Neon branch. Match the signup password rules to the managed service configuration. On Vercel, set all three server-only variables and register the deployed origin as a trusted domain.

This implementation follows the [Managed Better Auth Next.js API quickstart](https://neon.com/docs/auth/quick-start/nextjs-api-only). The catch-all route proxies auth requests; the two page files provide the visible forms. Reading articles remains public, without global auth middleware.

Apply the tracked comments migration separately from backend provisioning:

```sh
npm run db:migrate
```

Article pages show the first 100 comments in chronological order and label capped conversations. Signed-in members can post 1–2,000 characters; the server derives author ID/name from the session. Article lists show zero/singular/plural comment counts. Discussions update on navigation or refresh, without live push updates.

Author names are snapshots. Auth account deletion does not automatically remove comments because the application does not own or migrate Neon’s managed auth tables.

The guide’s runtime checks (two members, anonymous submission, spoofed author, body bounds, literal HTML, and counts) remain unverified. No remote migrations or deployments were run from this workspace.

## Part 1 setup (still applies)

Use Node 24 (`nvm use`). Run commands from `community-news/` inside the `yt` repository.

```sh
npm ci
cp .env.example .env.local
neon login
neon link --no-config
neon checkout main
npm run backend:plan
npm run backend:deploy
```

Use a dedicated Neon demo project in AWS Ohio (`aws-us-east-2`); create one first if needed with `neon projects create --name community-news --region-id aws-us-east-2`. Confirm the project and database branch before applying changes. Put that branch's connection string in `.env.local` as `DATABASE_URL`. Never commit credentials or `.neon` CLI context.

```sh
npm run db:migrate
npm run db:seed
npm run dev
```

Open http://localhost:3000. Expect three clearly labeled demo articles, publisher links, an empty excerpt fallback, and missing publication date fallbacks. The placeholder feed is disabled so Part 3 cannot accidentally fetch it. Rerunning the seed preserves article IDs and existing rows. See [the complete original handbook](docs/tutorial-plan.md), including the supporting code and rehearsal checks at its end.

`neon deploy` provisions backend configuration; `db:migrate` applies application schema separately. The Part 1 config sets only a seven-day TTL for new non-default Neon branches. No auth or Functions are provisioned yet.

## Validation and deployment

```sh
npm run typecheck
npm run lint
npm run build
```

Build compiles the app; verify actual list/detail reads against your configured demo database. Check an empty database after migration and before seeding; verify malformed and nonexistent article IDs show the not-found page. Inspect the browser to confirm database credentials stay server-side.

Deploy Next.js separately to Vercel. Configure server-only `DATABASE_URL` on that host, migrate and seed the matching database branch, then deploy. Neon and Vercel have separate deployment steps. See the [official backend quickstart](https://neon.com/docs/get-started/full-backend-quickstart).

If database access fails, check `.env.local`, restart Next.js after editing it, and confirm migrations ran against that exact branch. Do not use `db:generate` instead of `db:migrate`: the generated migration is already tracked. Generate a new migration only when changing the schema.

## Recording notes

- 0:00: final reader and architecture.
- 3:30: project linking and `neon.ts`; distinguish provisioning from migrations.
- 10:00: source/article schema, join, and duplicate constraint.
- 17:00: Server Component query and list.
- 24:00: detail page, publisher link, and missing article.
- 29:00: migrate/seed the target branch and deploy the web host.
- 35:00: demonstrate deployed list and detail.

Exercise: add a source filter and explain why its query still executes on the server.

## Git checkpoints

See [the stacked PR workflow](docs/stacked-prs.md). Part 1 is committed. Part 2 is committed. Part 3 is ready for review and a phase commit; runtime checks were skipped at your request.

The installed Neon CLI is 8.0.2. Dependencies are pinned in package.json and package-lock.json. The workstation currently has Node 25; use Node 24 for recording and Functions runtime alignment.

Verification for Part 1: migration generation, typecheck, lint, and production build passed. The build used a placeholder database URL solely to compile dynamic routes; database reads, migration application, seed execution, and hosted deployment have not been verified. `npm audit --omit=dev` reports zero vulnerabilities; four moderate findings remain in Drizzle Kit's development dependency chain. Next.js and Zod were updated from the reference project's versions to patched releases.


## Part 2 recording notes

- 0:00: demonstrate two members sharing a conversation.
- 1:00: enable managed auth in `neon.ts`; explain service provisioning.
- 4:00: server SDK, proxy route, forms, and session navigation.
- 15:00: comments migration and the application/auth ownership boundary.
- 20:00: session-derived identity and validated comment insertion.
- 26:00: discussion UI and indexed counts in a single article-list query.
- 31:00: refresh in a second browser and show rejected anonymous submissions.

Exercise: let an author delete their own comment, deriving ownership from the server session and revalidating the list/detail pages.

To commit this phase from the `yt` repository root:

```sh
git add community-news
git commit -m "Add managed auth and shared article comments"
git tag part-2
```


## Part 3 recording notes

- 0:00: add a source and show an imported article.
- 1:30: source-state migration, listing, and authenticated registration.
- 5:00: explain the simplified HTTPS URL policy and its limits.
- 9:00: bounded fetch, RSS/Atom parsing, and normalization.
- 16:00: database duplicate identity and repeat imports.
- 21:00: reusable pool, advisory locks, and trigger guard.
- 26:00: declare the Function and schedule in `neon.ts`.
- 30:00: fixture v1/v2, logs, and preserving existing comments.
- 36:00: bad-feed isolation and the 15-minute production cadence.

Exercise: record duration and inserted/skipped/error totals for each invocation, then explain why repeated imports preserve article identity.

To commit Part 3 from the `yt` root:

```sh
git add community-news
git commit -m "Add source management and scheduled RSS ingestion"
git tag part-3
```
