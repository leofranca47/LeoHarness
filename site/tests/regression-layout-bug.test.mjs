// @ts-check
/**
 * regression-layout-bug.test.mjs
 *
 * Testes de regressão para o bug "layout desktop bagunçado + mobile sem menu"
 * introduzido em iteração anterior.
 *
 * Os checks abaixo garantem que os padrões CSS identificados como
 * causa-raiz NÃO reapareçam:
 *
 *   1. custom.css NÃO deve definir um grid `.main-frame` (conflita com Starlight)
 *   2. custom.css NÃO deve aplicar `h1 { font-size: Nrem }` direto (gigantiza tudo)
 *   3. HomeHero.astro NÃO deve usar `-webkit-text-fill-color: transparent`
 *      (esconde o título)
 *   4. astro.config.mjs NÃO deve referenciar `components.Header` apontando
 *      para um componente custom (suspeito de esconder menu mobile nativo)
 *
 * Estratégia: testes estáticos baseados em conteúdo de arquivo.
 * São determinísticos, rodam em < 50ms, e quebram o build (TDD-friendly).
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = path.resolve(__dirname, '..');

async function read(rel) {
  return fs.readFile(path.join(SITE_ROOT, rel), 'utf-8');
}

describe('Layout bug regression', () => {
  it('1. custom.css NÃO redefine .main-frame como grid (conflita com Starlight)', async () => {
    const css = await read('src/styles/custom.css');
    // Procura por definição de grid no .main-frame
    assert.doesNotMatch(
      css,
      /\.main-frame\s*\{\s*display:\s*grid/,
      '.main-frame { display: grid } está redefinindo o layout nativo do Starlight'
    );
  });

  it('2. custom.css NÃO aplica font-size global em h1 (gigantiza cabeçalhos)', async () => {
    const css = await read('src/styles/custom.css');
    // Procura por h1 direto com font-size em rem (não em variable, e não dentro de media)
    const lines = css.split(/\r?\n/);
    let inMedia = false;
    let braceDepth = 0;
    let inSelector = '';
    let selectorBraceDepth = 0;
    let selector = '';
    let buffer = '';
    let flagged = false;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // Track @media blocks
      if (line.match(/^@media/)) {
        inMedia = true;
        continue;
      }
      if (inMedia && line.match(/^\}/)) {
        inMedia = false;
        continue;
      }

      // Reset selector detection on opening {
      if (selectorBraceDepth === 0) {
        const m = line.match(/^([^{]+)\{([^}]*)$/);
        if (m) {
          selector = m[1].trim();
          selectorBraceDepth = 1;
          buffer = m[2] || '';
        }
        continue;
      }

      buffer += '\n' + line;
      selectorBraceDepth += (line.match(/\{/g) || []).length;
      selectorBraceDepth -= (line.match(/\}/g) || []).length;

      if (selectorBraceDepth === 0) {
        // selector is complete
        const trimmed = selector.replace(/,$/, '').trim();
        const trimmedBuf = buffer.trim();

        // Detect: h1 { font-size: number-rem } in non-media context
        if (
          !inMedia &&
          /^\s*h1\s*(\s*,\s*\w+)?\s*\{/.test(trimmed + ' {') &&
          /font-size\s*:\s*[\d.]+rem/i.test(trimmedBuf)
        ) {
          flagged = true;
        }

        selector = '';
        buffer = '';
      }
    }

    assert.ok(
      !flagged,
      'custom.css aplica h1 { font-size: Xrem } em escopo global — isso gigantiza cabeçalhos das páginas.'
    );
  });

  it('3. HomeHero.astro NÃO usa -webkit-text-fill-color: transparent (esconde título)', async () => {
    const src = await read('src/components/HomeHero.astro');
    // Text-fill transparente dentro de gradient é o padrão problemático.
    assert.doesNotMatch(
      src,
      /-webkit-text-fill-color\s*:\s*transparent/i,
      'HomeHero está usando -webkit-text-fill-color: transparent — risco de título invisível.'
    );
  });

  it('4. astro.config.mjs NÃO sobrepõe components.Header (esconde menu mobile nativo)', async () => {
    const cfg = await read('astro.config.mjs');
    // Aceita overrides Legítimos em outras keys, mas rejeita `Header:` (chave de override Starlight)
    const hasHeaderOverride = /components\s*:\s*\{[^}]*Header\s*:/m.test(cfg);
    assert.ok(
      !hasHeaderOverride,
      'astro.config.mjs contém override de components.Header — Starlight nativo já entrega o menu mobile e o lang selector.'
    );
  });

  it('5. Header.astro custom NÃO existe (ou não está sendo importado)', async () => {
    // Headers alternativos não sobrescrevendo o nativo do Starlight.
    const exists = await fs
      .stat(path.join(SITE_ROOT, 'src/components/Header.astro'))
      .then(() => true)
      .catch(() => false);
    if (exists) {
      // Se existir, precisa renderizar DefaultHeader + NÃO esconder o mobile menu
      const src = await fs.readFile(path.join(SITE_ROOT, 'src/components/Header.astro'), 'utf-8');
      assert.ok(
        src.includes('DefaultHeader'),
        'Header.astro existe mas não importa @astrojs/starlight/components/Header — vai suprimir o menu nativo.'
      );
    }
  });

  it('6. sync-content remove o H1 do body quando extrai como title (evita duplicação visual)', async () => {
    // Testa diretamente o módulo syncContent com fixture.
    const { syncContent } = await import('../scripts/sync-content.mjs');
    const { promises: fsp } = await import('node:fs');
    const path = await import('node:path');

    const tmpSrc = await fsp.mkdtemp('/tmp/sync-strip-src-');
    const tmpOut = await fsp.mkdtemp('/tmp/sync-strip-out-');

    try {
      // Cria fixture com H1 que será extraído como title
      const withH1 = `---
description: Implementa uma nova feature
---

# Implementa uma nova feature

Conteúdo do body.
`;
      await fsp.mkdir(`${tmpSrc}/commands`, { recursive: true });
      await fsp.writeFile(`${tmpSrc}/commands/feature.md`, withH1);

      await syncContent({
        sourceDir: tmpSrc,
        contentDir: tmpOut,
        langs: ['pt-BR', 'en'],
        rootLang: 'pt-BR',
      });

      // PT-BR (root): frontmatter deve ter title; body NÃO deve ter H1 duplicado
      const ptContent = await fsp.readFile(`${tmpOut}/commands/feature.md`, 'utf-8');
      assert.match(ptContent, /title:.*Implementa uma nova feature/);
      assert.ok(
        !/^# Implementa uma nova feature/m.test(ptContent.replace(/---[\s\S]*?---\s*/, '')),
        'H1 ainda está presente no body após extração de title'
      );
    } finally {
      await fsp.rm(tmpSrc, { recursive: true, force: true });
      await fsp.rm(tmpOut, { recursive: true, force: true });
    }
  });
});
