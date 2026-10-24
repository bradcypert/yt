CREATE TABLE "articles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"source_id" uuid NOT NULL,
	"external_key" text NOT NULL,
	"title" text NOT NULL,
	"url" text NOT NULL,
	"excerpt" text DEFAULT '' NOT NULL,
	"published_at" timestamp with time zone,
	"ingested_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sources" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"feed_url" text NOT NULL,
	"enabled" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "articles" ADD CONSTRAINT "articles_source_id_sources_id_fk" FOREIGN KEY ("source_id") REFERENCES "public"."sources"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "articles_source_external_unique" ON "articles" USING btree ("source_id","external_key");--> statement-breakpoint
CREATE INDEX "articles_recent_idx" ON "articles" USING btree ("ingested_at","id");--> statement-breakpoint
CREATE UNIQUE INDEX "sources_feed_url_unique" ON "sources" USING btree ("feed_url");