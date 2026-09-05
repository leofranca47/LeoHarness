// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mdx from '@astrojs/mdx';
import rehypeAutoLinkAtRefs from './src/plugins/auto-link-at-refs.mjs';

export default defineConfig({
  site: 'https://openharness.local',
  markdown: {
    rehypePlugins: [
      rehypeAutoLinkAtRefs,
    ],
  },
  integrations: [
    starlight({
      title: 'OpenHarness',
      description:
        'Sistema comunitário de engenharia assistida por IA para OpenCode.',
      locales: {
        root: {
          label: 'Português (Brasil)',
          lang: 'pt-BR',
        },
        en: {
          label: 'English',
          lang: 'en',
        },
      },
      sidebar: [
        {
          label: 'Começando',
          items: [{ link: '/pt/readme/', label: 'Sobre o OpenHarness' }],
        },
        {
          label: 'Comandos',
          items: [{ autogenerate: { directory: 'commands' } }],
        },
        {
          label: 'Agentes',
          items: [{ autogenerate: { directory: 'agents' } }],
        },
        {
          label: 'Harness',
          items: [{ autogenerate: { directory: 'harness' } }],
        },
      ],
      social: [],
      components: {
        // Header.astro custom removido no fix bug layout — Starlight nativo
        // entrega o menu mobile (button popovertarget="starlight__sidebar") e
        // o lang selector (<starlight-lang-select>) sem override.
      },
      customCss: [
        './src/styles/tokens.css',
        './src/styles/custom.css',
      ],
      favicon: '/favicon.svg',
      expressiveCode: {
        themes: ['github-dark-high-contrast'],
        styleOverrides: {
          borderRadius: '0.25rem',
          codeFontSize: '0.8125rem',
          codeLineHeight: '1.6',
        },
      },
    }),
    mdx(),
  ],
});
