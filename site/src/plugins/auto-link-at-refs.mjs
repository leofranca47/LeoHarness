// @ts-check
/**
 * auto-link-at-refs.mjs
 * Plugin Rehype que transforma referências textuais do tipo
 * `@harness/workflows/tdd.md` em links internos para a rota Astro
 * correspondente (mesmo idioma da página atual).
 *
 * Roda no AST (não no texto cru), então escapa automáticamente o que
 * está dentro de code blocks.
 *
 * Funciona como rehype plugin: recebe tree, muta, retorna tree.
 */

import { visit } from 'unist-util-visit';

/**
 * @typedef {Object} Options
 * @property {string} lang   Locale atual da página (ex: 'pt', 'en', 'pt-BR')
 * @property {string} [baseDir]  Diretório-base relativo ao Starlight para resolver slugs
 */

const REF_PATTERN = /@([\w./-]+)\.md\b/g;

/**
 * @param {object} [options]
 * @param {string} [options.defaultLang]  Fallback se a vfile não tiver locale detectável
 */
export default function rehypeAutoLinkAtRefs(options = {}) {
  const defaultLang = options.defaultLang || 'pt-BR';

  return (tree, file) => {
    // Detecta lang a partir do vfile path (Astro passa o caminho de origem).
    let lang = defaultLang;
    try {
      // file pode ser vfile (tem .path) ou um objeto simples vindo de context
      const fp = file?.path || file?.history?.[0] || (typeof file === 'string' ? file : '');
      if (typeof fp === 'string' && fp.includes('/content/docs/en/')) {
        lang = 'en';
      }
    } catch {
      // mantém defaultLang
    }
    const isRoot = lang === defaultLang || lang === 'pt-BR' || lang === 'pt';
    const urlPrefix = isRoot ? '' : `/${lang}`;

    visit(tree, 'text', (node, index, parent) => {
      if (!parent || index == null) return;
      // Não mexe em nodes filhos de <code> ou <pre>
      if (
        parent.type === 'element' &&
        (parent.tagName === 'code' || parent.tagName === 'pre')
      ) {
        return;
      }

      const value = node.value;
      if (typeof value !== 'string' || !value.includes('@harness')) return;

      const matches = [...value.matchAll(REF_PATTERN)];
      if (matches.length === 0) return;

      /** @type {any[]} */
      const newChildren = [];
      let lastIndex = 0;
      for (const m of matches) {
        const fullMatch = m[0];
        const pathInsideAt = m[1]; // ex: "harness/workflows/tdd"
        const start = /** @type {number} */ (m.index);
        const end = start + fullMatch.length;

        if (start > lastIndex) {
          newChildren.push({
            type: 'text',
            value: value.slice(lastIndex, start),
          });
        }

        const href = `${urlPrefix}/${pathInsideAt}/`;
        newChildren.push({
          type: 'element',
          tagName: 'a',
          properties: {
            href,
            className: ['at-ref-link'],
            'data-at-ref': fullMatch,
          },
          children: [{ type: 'text', value: fullMatch }],
        });

        lastIndex = end;
      }

      if (lastIndex < value.length) {
        newChildren.push({
          type: 'text',
          value: value.slice(lastIndex),
        });
      }

      parent.children.splice(index, 1, ...newChildren);
      return index + newChildren.length;
    });
  };
}
