// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://yayalin.com',
  integrations: [
    sitemap({
      filter: (page) => !page.includes('/write') && !page.includes('/survey/') && !page.includes('/unsubscribe'),
    }),
  ],
  vite: {
    plugins: [tailwindcss()]
  }
});