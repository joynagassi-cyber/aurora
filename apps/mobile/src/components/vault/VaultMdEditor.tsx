/**
 * VaultMdEditor — le rendu « style Notion » du VAULT.md de veille.
 * (discovery-vault plan 2026-10-10, Lot 4.1)
 *
 * La carte de veille (Lot 4) EXPOSE le SSoT `vaultMd` (le VAULT.md
 * évolutif du programme). Le rendu passe par TipTap (déjà branché dans
 * `apps/mobile`, cf. `canvas/index.tsx`) :
 *
 *   LECTURE — le SSoT markdown est converti en HTML « style Notion »
 *             via `markdownToHtml` (`@aurora/ui`, AD-16b : HTML brut
 *             neutralisé), puis chargé dans un TipTap `editable: false`
 *             (le rendu EST la surface de lecture, pas un writer du
 *             SSoT — AD-7). TipTap rend l'HTML directement (pas besoin
 *             de l'extension `tiptap-markdown` qui n'est PAS dans le
 *             lockfile — `markdownToHtml` fait le travail, le DOM est
 *             déjà du HTML ProseMirror que TipTap lit).
 *
 * Le composant est READ-ONLY vis-à-vis du SSoT : il rend le document,
 * il ne le committe jamais. La PERSISTANCE reste le rôle de la carte
 * (qui préfère l'émettre à l'agent — le chat propose, seul le run
 * committe, AD-7). La classe `.vault-md-view` porte le rendu (zéro hex,
 * AD-17 — le bloc CSS est dans `data.css`, Lot 4.1).
 */
import { EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { useMemo } from 'react';
import { markdownToHtml } from '@aurora/ui';

export function VaultMdEditor({
  content,
  domaine,
  ariaLabel,
}: {
  /** the SSoT markdown (the VAULT.md content of the program). */
  content: string;
  /** the domain key of the vault (the `data-vault` attribute). */
  domaine: string;
  /** the accessible label (the aria-label of the ProseMirror region). */
  ariaLabel: string;
}) {
  // Le SSoT markdown est lu en HTML « style Notion » (AD-16b : le HTML
  // brut est neutralisé par `markdownToHtml`, cf. `packages/ui/src/lib/
  // canvas-utils.ts`). `useMemo` : le markdown SSoT n'évolue QUE au
  // commit du run (AD-7), donc la conversion est stable par contenu.
  const html = useMemo(() => markdownToHtml(content), [content]);

  // L'éditeur TipTap en MODE LECTURE (editable: false) — le contenu
  // est le SSoT HTML (pas éditable), `key` sur `content` pour resync
  // le DOM au commit du run suivant (append-only).
  const editor = useEditor(
    {
      extensions: [StarterKit],
      content: html,
      editable: false,
      immediatelyRender: true,
      shouldRerenderOnTransaction: false,
      editorProps: {
        attributes: {
          class: 'vault-md-view tiptap',
          role: 'region',
          'aria-label': ariaLabel,
          'data-vault': domaine,
        },
      },
    },
    [content],
  );

  return <EditorContent editor={editor} />;
}
