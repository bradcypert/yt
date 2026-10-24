ALTER TABLE "sources" ADD COLUMN "added_by" text;--> statement-breakpoint
ALTER TABLE "sources" ADD COLUMN "etag" text;--> statement-breakpoint
ALTER TABLE "sources" ADD COLUMN "last_modified" text;--> statement-breakpoint
ALTER TABLE "sources" ADD COLUMN "last_checked_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "sources" ADD COLUMN "last_success_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "sources" ADD COLUMN "last_error" text;--> statement-breakpoint
ALTER TABLE "sources" ADD COLUMN "consecutive_failures" integer DEFAULT 0 NOT NULL;