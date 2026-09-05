// @ts-check
/**
 * visual-check.mjs — Verificação visual do layout com Playwright.
 *
 * Captura screenshots em 3 viewports para 3 rotas:
 *   - mobile  (375×667)
 *   - tablet  (820×1180)
 *   - desktop (1440×900)
 *
 * Saída: site/screenshots/*.png — revisar manualmente para confirmar layout.
 *
 * NÃO é parte do test suite (não roda em CI por ora). É uma verificação
 * manual quando você quer ver o que o usuário veria.
 *
 * Uso: `node scripts/visual-check.mjs` (requer `npm run preview` em outra aba)
 */

import { chromium } from 'playwright';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const BASE_URL = 'http://127.0.0.1:4321';
const OUT_DIR = path.resolve('./screenshots');

const VIEWPORTS = [
  { name: 'mobile',  width: 375,  height: 667  },
  { name: 'tablet',  width: 820,  height: 1180 },
  { name: 'desktop', width: 1440, height: 900  },
];

const ROUTES = [
  { name: 'home',           url: '/' },
  { name: 'command',        url: '/commands/feature/' },
  { name: 'workflow',       url: '/harness/workflows/feature/' },
];

async function main() {
  await fs.mkdir(OUT_DIR, { recursive: true });

  const browser = await chromium.launch();
  console.log(`[visual-check] outDir = ${OUT_DIR}`);
  console.log(`[visual-check] capturing ${VIEWPORTS.length} viewports × ${ROUTES.length} routes`);

  for (const vp of VIEWPORTS) {
    const context = await browser.newContext({
      viewport: { width: vp.width, height: vp.height },
      deviceScaleFactor: 1,
    });

    for (const r of ROUTES) {
      const page = await context.newPage();
      const url = `${BASE_URL}${r.url}`;
      try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 10000 });
      } catch {
        // fallback sem networkidle
        await page.goto(url, { waitUntil: 'load', timeout: 10000 });
      }
      const fileName = `${r.name}@${vp.name}.png`;
      const out = path.join(OUT_DIR, fileName);
      await page.screenshot({ path: out, fullPage: false });
      console.log(`  ${vp.name.padEnd(8)} ${url.padEnd(36)} → ${fileName}`);
      await page.close();
    }
    await context.close();
  }

  await browser.close();
  console.log('[visual-check] done. revisar manualmente as PNGs em site/screenshots/');
}

main().catch((err) => {
  console.error('[visual-check] failed:', err);
  process.exit(1);
});
