import { sql } from 'drizzle-orm';
import {
  pgTable, uuid, text, boolean, timestamp, integer, uniqueIndex, index, check
} from 'drizzle-orm/pg-core';

export const sources = pgTable('sources', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: text('name').notNull(),
  feedUrl: text('feed_url').notNull(),
  enabled: boolean('enabled').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  addedBy: text('added_by'),
  etag: text('etag'),
  lastModified: text('last_modified'),
  lastCheckedAt: timestamp('last_checked_at', { withTimezone: true }),
  lastSuccessAt: timestamp('last_success_at', { withTimezone: true }),
  lastError: text('last_error'),
  consecutiveFailures: integer('consecutive_failures').notNull().default(0),
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

export const comments = pgTable('comments', {
  id: uuid('id').defaultRandom().primaryKey(),
  articleId: uuid('article_id').notNull()
    .references(() => articles.id, { onDelete: 'cascade' }),
  authorId: text('author_id').notNull(),
  authorName: text('author_name').notNull(),
  body: text('body').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('comments_article_created_idx').on(t.articleId, t.createdAt, t.id),
  check('comments_body_length', sql`char_length(btrim(${t.body})) between 1 and 2000`),
]);
