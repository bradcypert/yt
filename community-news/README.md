# Community News — Part 1

A shared news reader built with Next.js, Drizzle, and Neon Postgres. This checkpoint implements the read-only reader. Auth and comments arrive in Part 2; sources and scheduled RSS ingestion arrive in Part 3.

Our backend is declared in neon.ts and deployed with neon deploy. Our Next.js app connects to that backend and runs on Vercel.

## Local setup

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

See [the stacked PR workflow](docs/stacked-prs.md). Stop here for review and your Part 1 commit. Do not add auth or RSS code to this checkpoint.

The installed Neon CLI is 8.0.2. Dependencies are pinned in package.json and package-lock.json. The workstation currently has Node 25; use Node 24 for recording and Functions runtime alignment.

Verification for this checkpoint: migration generation, typecheck, lint, and production build passed. The build used a placeholder database URL solely to compile dynamic routes; database reads, migration application, seed execution, and hosted deployment have not been verified. `npm audit --omit=dev` reports zero vulnerabilities; four moderate findings remain in Drizzle Kit's development dependency chain. Next.js and Zod were updated from the reference project's versions to patched releases.
