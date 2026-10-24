import {
  pgTable, uuid, text, boolean, timestamp, uniqueIndex, index
} from 'drizzle-orm/pg-core';

export const sources = pgTable('sources', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: text('name').notNull(),
  feedUrl: text('feed_url').notNull(),
  enabled: boolean('enabled').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [uniqueIndex('sources_feed_url_unique').on(t.feedUrl)]);

export const articles = pgTable('articles', {
  id: uuid('id').defaultRandom().primaryKey(),
  sourceId: uuid('source_id').notNull().references(() => sources.id),
  externalKey: text('external_key').notNull(),
  title: text('title').notNull(),
  url: text('url').notNull(),
  excerpt: text('excerpt').notNull().default(''),
  publishedAt: timestamp('published_at', { withTimezone: true }),
  ingestedAt: timestamp('ingested_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  uniqueIndex('articles_source_external_unique').on(t.sourceId, t.externalKey),
  index('articles_recent_idx').on(t.ingestedAt, t.id),
]);
