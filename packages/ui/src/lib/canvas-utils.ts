/**
 * canvas-utils — conversions SSoT contenu canvas (0022, AD-10 / AD-16b).
 *
 * Le SSoT contenu = markdown par bloc (block.kind 'md', 0022) ; le rendu
 * HTML (onglet lecture) passe par marked + une neutralisation explicite du
 * HTML brut : le markdown canvas n'est JAMAIS porteur de `<script>` ni de
 * handlers inline (sécurité AD-16b — le rendu de lecture est
 * dangerouslySetInnerHTML côté page, donc on ne laisse rien passer).
 *
 * API v15 de marked : plus de `renderer.html = fn` sur l'instance publique
 * mais un override de Renderer via l'option `renderer` de parse
 * (`new marked.Renderer()` + `.html`), vérifié contre lib/marked.d.ts.
 */
import { marked, Renderer, type Tokens } from "marked";

/**
 * Renderer sécurisé : le HTML brut du markdown est neutralisé —
 * scripts/balises interactives retirés, le reste échappé (afin que le
 * rendu reste littéral, jamais exécutable).
 */
function createSafeRenderer(): InstanceType<typeof Renderer> {
  const renderer = new Renderer();
  renderer.html = (token: Tokens.HTML | Tokens.Tag) => {
    const raw = (token.text ?? "").trim();
    if (!raw) return "";
    if (/(^|<)\s*script\b/i.test(raw)) return ""; // payload <script> jamais restitué
    if (/^\s*<iframe\b/i.test(raw)) return ""; // frame injectable
    if (/^\s*<(?:embed|object|form|button|input|textarea|select|link|meta|base)\b/i.test(raw)) return "";
    if (/\bon(?:click|load|error|abort|change|input|focus|blur|submit)\s*=/i.test(raw)) return ""; // handler inline
    const escaped = raw
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
    // Le HTML brut du markdown canvas n'est JAMAIS restitué littéral :
    // il est HTML-échappé (donc non exécutable) et rendu comme texte.
    // Rendre les listes/table brutes non-échappées (l'ancienne règle
    // BLOCK_LIST_RE) ré-injectait des balises dangereuses (ex.
    // `<ul onclick=…>` ou `<table><script>…`) dans le rendu lecture.
    return escaped;
  };
  return renderer;
}

/**
 * Rend le markdown en HTML de lecture (gfm + breaks). Le HTML brut est
 * neutralisé par le renderer ci-dessus — aucun `<script>` ni handler
 * inline ne survit au rendu (testé dans canvas-utils.test.ts).
 */
export function markdownToHtml(md: string): string {
  if (!md) return "";
  const renderer = createSafeRenderer();
  const out = marked.parse(md, {
    renderer,
    breaks: true,
    gfm: true,
  });
  return typeof out === "string" ? out.trim() : "";
}

/**
 * Ancre de commentaire : offsets [start, end) de `term` dans le texte
 * plat de la session (`blocks.map(b => b.content).join('\n\n')`).
 * null si le terme est vide ou absent — un ancre dégénéré [x, x) est
 * interdit (0022, AD-7 : pas de data factice).
 */
export function commentAnchors(
  term: string,
  blocks: Array<{ content: string }>,
): [number, number] | null {
  if (!term) return null;
  const flat = blocks.map((b) => b.content).join("\n\n");
  const start = flat.indexOf(term);
  if (start < 0) return null;
  return [start, start + term.length];
}
