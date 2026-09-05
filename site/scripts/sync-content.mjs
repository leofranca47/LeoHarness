#!/usr/bin/env node
// @ts-check
/**
 * sync-content.mjs — Espelha arquivos .md do source-of-truth do OpenHarness
 * para src/content/docs/, gerando as coleções do Starlight.
 *
 * ATENÇÃO: snapshot pre-fix. NÃO strip o H1 do body quando extrai como
 * title (causa H1 duplicado nas páginas doc). Fix aplicado em commit
 * posterior.
 */

import { promises as fs } from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const REPO_ROOT = path.resolve(new URL('.', import.meta.url).pathname, '../..');
const DEFAULT_SOURCE_DIR = REPO_ROOT;
const DEFAULT_CONTENT_DIR = path.resolve(
  new URL('.', import.meta.url).pathname,
  '../src/content/docs'
);
const DEFAULT_ROOT_LANG = 'pt-BR';
const DEFAULT_LANGS = [DEFAULT_ROOT_LANG, 'en'];

/** Renomeações aplicadas para evitar colisão de slug com pastas homônimas. */
const RENAME_MAP = new Map([
  // AGENTS.md no raiz colide com a pasta agents/. Renomeado para principles.md
  // (o conteúdo descreve os princípios globais do harness).
  ['AGENTS.md', 'principles.md'],
  ['harness/AGENTS.md', 'harness/principles.md'],
]);

/** Lista todos os arquivos .md sob `dir` recursivamente, pulando dirs de ignore. */
async function listMarkdownFiles(dir) {
  /** @type {string[]} */
  const results = [];
  /** @type {string[]} */
  const stack = [dir];

  const IGNORE_DIRS = new Set([
    'node_modules',
    '.git',
    'site',
    'dist',
    '.astro',
    '.opencode',
  ]);

  while (stack.length > 0) {
    const current = /** @type {string} */ (stack.pop());
    let entries;
    try {
      entries = await fs.readdir(current, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) {
        if (IGNORE_DIRS.has(entry.name) || entry.name.startsWith('.')) continue;
        stack.push(full);
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        results.push(full);
      }
    }
  }
  return results;
}

/** Extrai o H1 (primeira linha começando com "# "). */
function extractH1(body) {
  for (const line of body.split(/\r?\n/)) {
    const m = line.match(/^#\s+(.+?)\s*$/);
    if (m) return m[1];
  }
  return null;
}

/** Parseia YAML frontmatter simples. */
function parseFrontmatter(content) {
  const m = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/);
  if (!m) return { frontmatter: null, body: content };

  const raw = m[1];
  const body = content.slice(m[0].length);

  /** @type {Record<string, string>} */
  const fm = {};
  for (const line of raw.split(/\r?\n/)) {
    const kv = line.match(/^([\w-]+):\s*(.*?)\s*$/);
    if (kv) {
      let v = kv[2];
      if (
        (v.startsWith("'") && v.endsWith("'")) ||
        (v.startsWith('"') && v.endsWith('"'))
      ) {
        v = v.slice(1, -1);
      }
      fm[kv[1]] = v;
    }
  }
  return { frontmatter: fm, body };
}

/** Serializa objeto frontmatter de volta. */
function serializeFrontmatter(fm) {
  const lines = ['---'];
  for (const [k, v] of Object.entries(fm)) {
    if (typeof v === 'string') {
      const needsQuotes = /[:#\n]/.test(v);
      lines.push(`${k}: ${needsQuotes ? JSON.stringify(v) : v}`);
    }
  }
  lines.push('---', '');
  return lines.join('\n');
}

/** Heurística: detecta texto como PT-BR. */
function looksPortuguese(text) {
  if (!text) return false;
  return /\b(é|você|para|como|seu|sua|este|esta|pelo|pela|com|do|da|dos|das|os|as|um|uma|não|são|ser|workflow|workflows|criar|implementar|usar|disponíveis|atualização|instalação|funcionalidade|harness|comandos)\b/i.test(
    text
  );
}

/** Aplica RENAME_MAP ao nome do arquivo. */
function applyRenames(relativePath) {
  const renamed = RENAME_MAP.get(relativePath);
  return renamed ?? relativePath;
}

/**
 * Processa um arquivo de origem e gera saída para cada idioma.
 */
async function mirrorFile({ sourcePath, relativePath, contentDir, langs, rootLang }) {
  const original = await fs.readFile(sourcePath, 'utf-8');
  const { frontmatter, body } = parseFrontmatter(original);
  const h1 = extractH1(body);

  /** @type {Record<string, string>} */
  const baseFm = frontmatter ? { ...frontmatter } : {};

  // Title — adicionar se faltar (snapshop PRE-FIX: NÃO strip H1 do body)
  if (!baseFm.title) {
    if (h1) baseFm.title = h1;
    else if (baseFm.description) baseFm.title = baseFm.description;
    else baseFm.title = path.basename(relativePath, '.md').replace(/[-_]/g, ' ');
  }

  const finalRelative = applyRenames(relativePath);

  for (const lang of langs) {
    const isRoot = lang === rootLang;
    const outDir = isRoot
      ? path.join(contentDir, path.dirname(finalRelative))
      : path.join(contentDir, lang, path.dirname(finalRelative));
    const outFile = isRoot
      ? path.join(contentDir, finalRelative)
      : path.join(contentDir, lang, finalRelative);

    try { await fs.unlink(outFile); } catch {}

    await fs.mkdir(outDir, { recursive: true });

    /** @type {Record<string, string>} */
    const fm = { ...baseFm };

    if (!isRoot) {
      const isPtOnly = looksPortuguese(baseFm.title || h1 || '');
      if (isPtOnly) {
        fm['translation-status'] = 'pending';
        fm['translation-source'] = rootLang;
        fm['banner'] = {
          content: `Conteúdo refletido de **${rootLang}** — tradução nativa ainda não disponível.`,
        };
      }
    }

    const fmText = Object.keys(fm).length > 0 ? serializeFrontmatter(fm) : '';
    await fs.writeFile(outFile, fmText + body, 'utf-8');
  }
}

/**
 * Função pública: sincroniza sourceDir → contentDir.
 */
export async function syncContent({ sourceDir, contentDir, langs, rootLang = DEFAULT_ROOT_LANG }) {
  const files = await listMarkdownFiles(sourceDir);

  const tasks = files.map((fullPath) => ({
    sourcePath: fullPath,
    relativePath: path.relative(sourceDir, fullPath),
    contentDir,
    langs,
    rootLang,
  }));

  await Promise.all(tasks.map((t) => mirrorFile(t)));
  return { count: files.length };
}

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  let sourceDir = DEFAULT_SOURCE_DIR;
  let contentDir = DEFAULT_CONTENT_DIR;
  let langs = DEFAULT_LANGS;
  let rootLang = DEFAULT_ROOT_LANG;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--source' && args[i + 1]) sourceDir = path.resolve(args[++i]);
    else if (args[i] === '--content-dir' && args[i + 1]) contentDir = path.resolve(args[++i]);
    else if (args[i] === '--langs' && args[i + 1]) langs = args[++i].split(',').map((s) => s.trim());
    else if (args[i] === '--root-lang' && args[i + 1]) rootLang = args[++i];
  }

  console.log(`[sync-content] source=${sourceDir}`);
  console.log(`[sync-content] contentDir=${contentDir}`);
  console.log(`[sync-content] langs=${langs.join(',')} root=${rootLang}`);

  syncContent({ sourceDir, contentDir, langs, rootLang })
    .then((res) => {
      console.log(`[sync-content] mirrored ${res.count} file(s) into ${langs.length} locale(s).`);
    })
    .catch((err) => {
      console.error('[sync-content] error:', err);
      process.exit(1);
    });
}
