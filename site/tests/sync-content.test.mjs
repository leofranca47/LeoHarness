// @ts-check
import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { syncContent } from '../scripts/sync-content.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const FIXTURE_SRC = path.resolve(__dirname, 'fixtures/src');
const FIXTURE_OUT = path.resolve(__dirname, 'fixtures/out');

/**
 * Helper: limpa output dir antes de cada teste.
 */
async function cleanOut() {
  await fs.rm(FIXTURE_OUT, { recursive: true, force: true });
  await fs.mkdir(FIXTURE_OUT, { recursive: true });
}

/** Helper: lista arquivos gerados recursivamente. */
async function listFilesRecursive(dir, base = dir) {
  const out = [];
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      out.push(...(await listFilesRecursive(full, base)));
    } else {
      out.push(path.relative(base, full));
    }
  }
  return out;
}

describe('syncContent()', () => {
  beforeEach(cleanOut);

  it('espelha cada arquivo .md do source para PT (root) e EN (subpasta)', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    // PT-BR (root) — arquivos ficam direto em contentDir/
    const ptFiles = await listFilesRecursive(FIXTURE_OUT);
    // EN fica em contentDir/en/
    const enFiles = await listFilesRecursive(path.join(FIXTURE_OUT, 'en'));

    assert.ok(ptFiles.includes('README.md'), 'PT deve ter README.md na raiz');
    assert.ok(enFiles.includes('README.md'), 'EN deve ter README.md');
    assert.ok(ptFiles.includes(path.join('commands', 'feature.md')));
    assert.ok(enFiles.includes(path.join('commands', 'feature.md')));
    assert.ok(ptFiles.includes(path.join('harness', 'workflows', 'feature.md')));
  });

  it('preserva a estrutura de diretórios do source', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    const ptFiles = await listFilesRecursive(FIXTURE_OUT);
    assert.ok(
      ptFiles.some((f) => f.startsWith(path.join('harness', 'workflows', ''))),
      'Diretórios aninhados preservados para root'
    );
    const enFiles = await listFilesRecursive(path.join(FIXTURE_OUT, 'en'));
    assert.ok(
      enFiles.some((f) => f.startsWith(path.join('harness', 'workflows', ''))),
      'Diretórios aninhados preservados para EN'
    );
  });

  it('preserva o frontmatter YAML original', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    const ptContent = await fs.readFile(
      path.join(FIXTURE_OUT, 'commands', 'feature.md'),
      'utf-8'
    );
    assert.match(ptContent, /^---\s*[\r\n]/);
    assert.match(ptContent, /description:.*Implementa uma nova/);
    assert.match(ptContent, /agent: build/);
  });

  it('marca EN como pending translation quando arquivos são PT-only', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    const enFeature = await fs.readFile(
      path.join(FIXTURE_OUT, 'en', 'commands', 'feature.md'),
      'utf-8'
    );
    assert.match(enFeature, /translation-status:\s*pending/);
  });

  it('NÃO marca PT-BR root como pending translation', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    const ptFeature = await fs.readFile(
      path.join(FIXTURE_OUT, 'commands', 'feature.md'),
      'utf-8'
    );
    assert.doesNotMatch(ptFeature, /translation-status:\s*pending/);
  });

  it('adiciona um title quando não há frontmatter (extraído do H1)', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    const wfPt = await fs.readFile(
      path.join(FIXTURE_OUT, 'harness', 'workflows', 'feature.md'),
      'utf-8'
    );
    assert.match(wfPt, /^---\s*[\r\n]/);
    assert.match(wfPt, /title:\s*["']?Workflow: FEATURE \(fixture\)["']?/);
  });

  it('faz merge de frontmatter (original + novos campos), preservando originais', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    const ptFeature = await fs.readFile(
      path.join(FIXTURE_OUT, 'commands', 'feature.md'),
      'utf-8'
    );
    assert.match(ptFeature, /description:.*Implementa uma nova/);
    assert.match(ptFeature, /agent: build/);
    assert.match(ptFeature, /title:/);
  });

  it('idempotente: rodar duas vezes não duplica frontmatter', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });
    const firstPT = await fs.readFile(
      path.join(FIXTURE_OUT, 'commands', 'feature.md'),
      'utf-8'
    );

    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });
    const secondPT = await fs.readFile(
      path.join(FIXTURE_OUT, 'commands', 'feature.md'),
      'utf-8'
    );

    const firstTitles = (firstPT.match(/^title:/gm) || []).length;
    const secondTitles = (secondPT.match(/^title:/gm) || []).length;
    assert.equal(firstTitles, 1, 'Primeira sync deve ter 1 campo title');
    assert.equal(secondTitles, 1, 'Segunda sync ainda deve ter 1 campo title (idempotente)');
  });

  it('lida gracefully com frontmatter incompleto (só description)', async () => {
    await syncContent({
      sourceDir: FIXTURE_SRC,
      contentDir: FIXTURE_OUT,
      langs: ['pt-BR', 'en'],
      rootLang: 'pt-BR',
    });

    const content = await fs.readFile(
      path.join(FIXTURE_OUT, 'commands', 'incomplete-frontmatter.md'),
      'utf-8'
    );
    assert.match(content, /description:/);
    assert.match(content, /title:/);
  });
});
