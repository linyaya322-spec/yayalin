import { defineCollection, z } from 'astro:content';
import { glob, file } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    category: z.enum(['生活隨筆', '兒少議題', '興趣分享']),
    excerpt: z.string(),
  }),
});

const timeline = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/timeline' }),
  schema: z.object({
    date: z.coerce.date(),
    title: z.string(),
    description: z.string(),
  }),
});

const quotes = defineCollection({
  loader: file('./src/content/quotes/quotes.json', {
    parser: (text) => JSON.parse(text).quotes,
  }),
  schema: z.object({
    id: z.string(),
    text: z.string(),
  }),
});

export const collections = { blog, timeline, quotes };
