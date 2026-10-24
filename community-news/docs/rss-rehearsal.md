# RSS rehearsal

The finished reference project removed `configuredFeedHosts()`, the `RSS_ALLOWED_HOSTS` setting, the hostname allowlist check, and the custom-port restriction. Part 3 follows that decision: accept HTTPS feeds without embedded credentials and strip fragments. The worker rejects redirects, enforces a 10-second network deadline and 2 MiB response limit, rejects DTD/entity declarations, and processes at most 100 items per source. This policy is not an SSRF defense: internal HTTPS destinations remain reachable. The original handbook is preserved as written; this document records the intentional change.

## Configure and deploy

Keep the web app's database and managed auth URLs paired to the same Neon branch. Apply the source-state migration before enabling scheduled ingestion:

```sh
npm ci
npm run db:migrate
npm run backend:plan
neon deploy --env .env.local
```

Set `RSS_SCHEDULE_ENABLED=true` in the deployment environment or `.env.local` to enable the schedule, then redeploy. It defaults to disabled so deploying a preview does not automatically start another importer. No allowlist variable is required. The Function receives its own branch `DATABASE_URL` from Neon.

The importer uses session advisory locks on dedicated pg clients. Before hosted use, verify that the injected connection preserves sessions; transaction-mode pooling requires replacing this locking strategy with database leases. This has not been verified in this workspace.

The trigger calls `/scheduled` at quarter-hour UTC boundaries. Inspect it with:

```sh
neon functions get rsssync
neon triggers list
neon logs query --source function
```

The [official schedule guide](https://neon.com/docs/compute/functions/triggers/schedule) explains the hosted trigger and logs. Removing a trigger from config does not disable a remotely existing copy: set `RSS_SCHEDULE_ENABLED=false` and deploy to stop it. A queued invocation can still arrive.

## Controlled fixture publisher

```sh
npm run fixture:serve
```

The dedicated publisher listens on `127.0.0.1:8788`. Put it behind an HTTPS reverse proxy or tunnel on a hostname you control. Register `https://YOUR_FIXTURE_HOST/feed.xml` in `/sources`. The Next.js app does not host this publisher. The worker deliberately rejects direct `http://localhost:8788` URLs.

The publisher serves v1 by default. Switch its response while it runs:

```sh
printf 'v1\n' > fixtures/active-version
# Later, expose Story C while preserving A and B:
printf 'v2\n' > fixtures/active-version
```

`active-version` is gitignored. ETags derive from the XML bytes, so switching versions changes the validator. An unchanged request with a matching `If-None-Match` gets 304. `/bad.xml` serves malformed XML for failure isolation. Fixture article links intentionally use example.com and demo labels.

Demonstration:

1. Import v1 (A/B): two inserts. Repeat: no duplicates, or a 304 response.
2. Add a comment to A.
3. Switch to v2 (A/B/C). The next scheduled check inserts C; A keeps its ID and comments.
4. Add the publisher's `/bad.xml` as another source and show failure status while the good feed still succeeds.
5. Inspect structured invocation/source logs and `next_run_at` on the deployed trigger.

The seed source stays disabled and is independent of these fixtures. A successful source check includes a 304 and does not necessarily indicate new articles.

## Optional local handler replay

With the Function running through `neon dev` and a configured database, use:

```sh
curl -X POST http://localhost:8787/scheduled \
  -H 'Content-Type: application/json' \
  -H 'X-Neon-Trigger-Invocation-Id: local-rss-test' \
  -d '{"version":1,"invocation_id":"local-rss-test","trigger":{"type":"schedule","id":"trigger-local","name":"local-schedule"},"data":{"scheduled_at":"2026-10-24T12:00:00Z"}}'
```

A request without the trigger header returns 403; an invalid schedule envelope returns 400. The header can be forged locally. [Neon's hosted edge strips client-supplied X-Neon headers](https://neon.com/docs/compute/functions/triggers/overview#confirming-a-request-came-from-neon); local replay does not establish hosted scheduling or prove that deployed requests are guarded correctly.

Hosted scheduling, source fetches, 304 behavior, concurrent imports, database idempotency, and comment preservation remain unverified; runtime testing was skipped at the user's request.
