// @ts-check
import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { docsSchema, i18nSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: glob({
      pattern: '**/[^_]*.{md,mdx}',
      base: './src/content/docs',
    }),
    schema: docsSchema(),
  }),
  i18n: defineCollection({
    loader: glob({
      pattern: '**/[^_]*.{json,yml,yaml}',
      base: './src/content/i18n',
    }),
    schema: i18nSchema(),
  }),
};
