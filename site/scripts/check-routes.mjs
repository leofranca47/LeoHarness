#!/usr/bin/env node
// @ts-check
/**
 * check-routes.mjs — Smoke test
 *
 * Sobe um servidor Astro preview na porta 4321 e bate em URLs-chave
 * para verificar HTTP 200 nas rotas principais.
 *
 * Uso:
 *   1. `npm run build` (uma vez)
 *   2. Num terminal: `npm run preview` (sobe servidor)
 *   3. Noutro terminal: `npm run check:routes`
 *
 * OU usar a função `runSmokeTests()` programaticamente.
 */

import http from 'node:http';
import process from 'node:process';

const HOST = '127.0.0.1';
const PORT = 4321;
const TIMEOUT_MS = 5000;

const ROUTES = [
  // Home
  '/',
  '/en/',
  // PT — README/AGENTS mapeiam para slugs readme/principles
  '/readme/',
  '/principles/',
  '/agents/architect/',
  '/agents/debugger/',
  '/agents/investigator/',
  '/agents/reviewer/',
  '/commands/feature/',
  '/commands/bug/',
  '/commands/debug/',
  '/commands/refactor/',
  '/commands/refine/',
  '/commands/review/',
  '/commands/spec/',
  '/commands/init-project/',
  '/commands/refresh-context/',
  '/harness/workflows/feature/',
  '/harness/workflows/bugfix/',
  '/harness/workflows/debug/',
  '/harness/workflows/refactor/',
  '/harness/workflows/review/',
  '/harness/workflows/refinement/',
  '/harness/workflows/specification/',
  '/harness/workflows/investigation/',
  '/harness/workflows/tdd/',
  '/harness/core/principles/',
  '/harness/core/completion-criteria/',
  '/harness/core/context-strategy/',
  '/harness/core/model-strategy/',
  '/harness/core/task-classification/',
  '/harness/gates/discovery/',
  '/harness/gates/planning/',
  '/harness/gates/completion/',
  '/harness/profiles/generic/',
  '/harness/profiles/laravel/',
  '/harness/profiles/php/',
  '/harness/templates/project-context/',
  // EN — mirror (slugs same + /en/ prefix)
  '/en/readme/',
  '/en/principles/',
  '/en/agents/architect/',
  '/en/commands/feature/',
  '/en/harness/workflows/feature/',
];

/**
 * @param {string} path
 * @returns {Promise<{status: number, body: string}>}
 */
function fetchRoute(path) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        host: HOST,
        port: PORT,
        path,
        method: 'GET',
        timeout: TIMEOUT_MS,
        headers: { 'Accept': 'text/html' },
      },
      (res) => {
        let body = '';
        res.setEncoding('utf-8');
        res.on('data', (c) => (body += c));
        res.on('end', () => resolve({ status: res.statusCode, body }));
      }
    );
    req.on('timeout', () => {
      req.destroy();
      reject(new Error(`Timeout for ${path}`));
    });
    req.on('error', reject);
    req.end();
  });
}

/**
 * Hits all expected routes via http and reports status codes.
 * Espera um servidor Astro preview rodando.
 * @param {string[]} [routes]
 * @param {{host?: string, port?: number}} [opts]
 */
export async function runSmokeTests(routes = ROUTES, opts = {}) {
  const host = opts.host ?? HOST;
  const port = opts.port ?? PORT;

  const results = [];
  for (const route of routes) {
    try {
      const { status, body } = await fetchRoute(route);
      results.push({ route, status, ok: status === 200 });

      // Validação adicional: páginas EN devem ter o banner de pending translation.
      if (status === 200 && route.startsWith('/en/') && route !== '/en/') {
        // Procura pelo texto do banner (PT: "Conteúdo refletido"; EN: "Content mirrored")
        const hasPendingBanner =
          body.includes('refletido de') ||
          body.includes('Conteúdo refletido') ||
          body.includes('Content mirrored') ||
          body.includes('tradução nativa') ||
          body.includes('translation');
        results.push({ route: route + ' (banner)', status: hasPendingBanner ? 200 : 404, ok: hasPendingBanner });
      }
    } catch (err) {
      results.push({ route, status: 0, ok: false, error: err.message });
    }
  }

  const ok = results.filter((r) => r.ok).length;
  const fail = results.filter((r) => !r.ok);

  return { total: results.filter((r) => !r.route.endsWith('(banner)')).length, bannerChecks: results.length - ROUTES.length, ok, fail };
}

// CLI entrypoint
if (import.meta.url === `file://${process.argv[1]}`) {
  runSmokeTests()
    .then((summary) => {
      console.log(`[check-routes] ${summary.ok}/${summary.total} OK`);
      if (summary.fail.length > 0) {
        console.error(`[check-routes] FAIL:${' '.repeat(0)}`);
        for (const r of summary.fail) console.error(`  ${r.route} → ${r.status}${r.error ? ' (' + r.error + ')' : ''}`);
        process.exit(1);
      }
      process.exit(0);
    })
    .catch((err) => {
      console.error('[check-routes] error:', err);
      process.exit(2);
    });
}
