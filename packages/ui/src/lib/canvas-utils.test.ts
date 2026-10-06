/**
 * canvas-utils tests — markdown → HTML (marked, sécurité) + ancres de
 * commentaire (offsets [start, end) sur le texte plat de la session).
 * Contrat enregistré ici (0022, AD-10 / AD-16b) :
 * - le rendu markdown n'est JAMAIS porteur de HTML brut (pas de
 *   `<script>` ni de handlers inline injectables),
 * - les offsets sont sur `blocks.map(b => b.content).join('\n\n')`.
 */
import { describe, it, expect } from "vitest";
import { markdownToHtml, commentAnchors } from "./canvas-utils";

describe("markdownToHtml", () => {
  it("rend un titre + un paragraphe en HTML", () => {
    const html = markdownToHtml("# Titre\n\nBonjour le **monde**.");
    expect(html).toContain("<h1");
    expect(html).toContain("Titre");
    expect(html).toContain("<strong>monde</strong>");
    expect(html).toContain("Bonjour le");
  });

  it("neutralise le <script> brut (pas de payload exécutable dans le rendu)", () => {
    for (const raw of [
      "<script>alert(1)</script>",
      "<SCRIPT>alert(1)</SCRIPT>",
      "<script\n src=x>",
    ]) {
      const html = markdownToHtml(raw);
      expect(html).not.toContain("alert(1)");
      expect(html.toLowerCase()).not.toContain("<script");
    }
  });

  it("neutralise les handlers inline (onclick) et les iframes dans le HTML brut", () => {
    expect(markdownToHtml('<div onclick="alert(1)">x</div>')).not.toContain("onclick");
    expect(markdownToHtml("<iframe src=x></iframe>")).not.toContain("<iframe");
  });

  it("échappe le HTML brut de listes/tables (pas de balise littérale dans le rendu)", () => {
    // Regression : le vieux `BLOCK_LIST_RE` rendait `<ul ...>` littéral
    // (non-échappé), ce qui ré-injectait des balises dangereuses dans
    // dangerouslySetInnerHTML. Maintenant le HTML brut = texte échappé.
    const html = markdownToHtml("<ul onclick=alert(1)><li>x</li></ul>");
    expect(html).not.toContain("<ul");
    expect(html).not.toContain("onclick");
    // Toute balise HTML littérale doit avoir disparu du rendu — le payload
    // ne survit que sous forme échappée (le bloc complet étant dropé, le
    // résultat peut légitimement être vide).
    expect(html).not.toMatch(/<\s*(ul|ol|li|table|script)\b/i);
  });

  it("laisse passer le markdown propre (rendu correct, aucune altération)", () => {
    expect(markdownToHtml("Salut le **monde**")).toBe("<p>Salut le <strong>monde</strong></p>");
  });
});

describe("commentAnchors (offsets [start, end) sur le texte plat = join \"\\n\\n\")", () => {
  const blocks = [
    { content: "Bloc un" },
    { content: "Bloc deux" },
  ];
  // Texte plat : "Bloc un\n\nBloc deux"
  //              0123456789...
  // 'un'  -> [5, 7]
  // 'deux' -> [14, 18]

  it("trouve l'ancre du 1er bloc (offsets exacts)", () => {
    expect(commentAnchors("un", blocks)).toEqual([5, 7]);
  });

  it("trouve l'ancre du 2e bloc (au-delà du séparateur \\n\\n)", () => {
    expect(commentAnchors("deux", blocks)).toEqual([14, 18]);
  });

  it("retourne null si le terme est absent du texte plat", () => {
    expect(commentAnchors("inexistant", blocks)).toBeNull();
  });

  it("retourne null si le terme est vide (offset dégénéré interdit)", () => {
    expect(commentAnchors("", blocks)).toBeNull();
  });
});
