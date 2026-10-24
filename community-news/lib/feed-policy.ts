export function normalizeFeedUrl(value: string): string {
  const url = new URL(value);
  if (url.protocol !== "https:" || url.username || url.password) {
    throw new Error('Feed URL must use HTTPS without embedded credentials.')
  }

  url.hash = '';
  return url.toString();
}
