# Canvas TipTap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Une page `/canvas/:id` (page dédiée) + un mode canvas accessible depuis `/agent` où l'utilisateur écrit directement dans des blocs TipTap, ajoute des commentaires sur une sélection, indexe une sélection verbatim dans le chat (composer agent), et bascule la visualisation d'un artefact en markdown ⇄ HTML.

**Architecture:**
1. Migration Supabase `0022_canvas.sql` : tables `canvas_sessions` (avec `artifact_id uuid` nullable) + `canvas_comments`, RLS user (`user_id = auth.uid()`), pattern 0007/0008. Le canvas EST la surface d'édition d'une session d'artefact ; l'onglet HTML rend l'artefact en lecture seule.
2. Blocs TipTap : chaque `block` est une entrée JSON `block.kind === 'md'` dont `data.content` est du markdown éditable par TipTap. Le contenu est normalisé markdown → JSON → markdown (idempotent) : la bascule md/HTML est donc une bascule de vue sur le MÊME contenu, pas deux sources de vérité.
3. Client `apps/mobile/src/lib/canvas-client.ts` : `createCanvasClient(supabase, supabaseKey)` (pattern `agent-client.ts`, AD-3 : publishable key uniquement). Hook TanStack `useCanvas` (chargement + upsert debounce 1 s + commentaires).
4. « Indexer dans le chat » : action du menu de sélection canvas qui prépend le texte contextualisé dans le draft du composer agent (réutilise `selectionToDraft` d'`/agent` — zéro nouveau backend).

**Tech Stack:** `@tiptap/react@2` + `@tiptap/starter-kit` (+ `marked` côté UI pour le rendu HTML de lecture), `react-markdown@9` + `remark-gfm` (déjà dans apps/mobile), Supabase + TanStack Query (déjà présents), pattern renderer de `packages/ui`. Déjà acté en `docs/ui-libraries.md` (ligne 50, ADR v1.5).

**Contexte repo (à lire avant de coder) :**
- `apps/mobile` : React 18 + Ionic + Vite, 17 routes figées (`apps/mobile/src/router.tsx`). Une page = dossier `src/pages/<name>/index.tsx` + CSS dans `src/styles/<name>.css` (importé par `main.tsx`, vérifier le pattern).
- Test UI : vitest jsdom dans `packages/ui` (`pnpm -F @aurora/ui test`). Test logique node:test dans `packages/agent` et `apps/mobile/test/` (`node --experimental-strip-types --test`).
- RLS : chaque table passe `ENABLE` + `FORCE ROW LEVEL SECURITY` + policy user_isolation + trigger `set_updated_at()` (copier le bloc `DO $$` de `supabase/migrations/0008_agent_integrations.sql` lignes 85-115).
- Gate statique : `sh scripts/check-rls.sh` (scanne `supabase/migrations/*.sql`).
- `apps/mobile/package.json` `type: module` → les tests écrits dans `apps/mobile/test/` importent `node:test`/`node:assert` et s'exécutent avec `node --experimental-strip-types --test`.
- Frontière AD-1/AD-10 : les apps n'importent les vendors que via les contrats ; TipTap est un vendor de UI → le composant de rendu/basculance vit dans `packages/ui` et la page `/canvas` ne fait que l'orchestrer. Les utils de conversion (markdown ⇄ JSON TipTap) vivent dans `packages/ui/src/lib/canvas-utils.ts` (testables en jsdom).

---

## Task 1: Dépendances TipTap + vérification du build

**Files:**
- Modify: `apps/mobile/package.json` (deps)
- Modify: `packages/ui/package.json` (deps : TipTap + `marked`)

**Step 1: Ajouter les déps**

`apps/mobile/package.json` → `dependencies` :
```json
"@tiptap/react": "^2.11.0",
"@tiptap/starter-kit": "^2.11.0"
```
`packages/ui/package.json` → `dependencies` :
```json
"@tiptap/core": "^2.11.0",
"@tiptap/pm": "^2.11.0",
"marked": "^15.0.0"
```
(Starter-kit = headings/bold/italic/paragraph/lists/bullet-list/ordered-list + History — le strict YAGNI pour v1 : pas de table/math/link en v1, déjà actés mais pas nécessaires ici.)

**Step 2: Installer**

Run: `pnpm install`
Expected : lockfile mis à jour, erreurs 0.

**Step 3: Typecheck**

Run: `pnpm -F @aurora/mobile typecheck && pnpm -F @aurora/ui typecheck`
Expected : PASS (aucun code encore, juste vérifier que les packages résolvent).

**Step 4: Commit**

```bash
git add apps/mobile/package.json packages/ui/package.json pnpm-lock.yaml
git commit -m "feat(canvas): deps TipTap v2 + marked"
```

---

## Task 2: Migration 0022 (canvas_sessions + canvas_comments, RLS)

**Files:**
- Create: `supabase/migrations/0022_canvas.sql`

**Step 1: Écrire la migration**

`supabase/migrations/0022_canvas.sql` :
```sql
-- =============================================================================
-- Aurora — Migration 0022: Canvas module (block editor + commentaires)
-- canvas_sessions: un canvas = la surface d'édition d'une session d'artefact
-- (artifact_id nullable — un canvas peut exister sans artefact généré).
-- blocks jsonb: [{ id, kind: 'md', content: markdown }] (SSoT contenu).
-- canvas_comments: ancre de sélection (offset_start/offset_end dans le
-- texte de la session) + body du commentaire. Pattern RLS 0007/0008.
-- =============================================================================

CREATE TABLE canvas_sessions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title         text NOT NULL DEFAULT '',
  blocks        jsonb NOT NULL DEFAULT '[]'::jsonb,
  artifact_id   uuid REFERENCES artifacts (id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX canvas_sessions_user_idx ON canvas_sessions (user_id);

CREATE TABLE canvas_comments (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  session_id     uuid NOT NULL REFERENCES canvas_sessions (id) ON DELETE CASCADE,
  anchor_start   int NOT NULL,
  anchor_end     int NOT NULL,
  body           text NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX canvas_comments_session_idx ON canvas_comments (session_id);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['canvas_sessions','canvas_comments'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY %I_user_isolation ON %I
       USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())', t, t);
    EXECUTE format(
      'CREATE POLICY %I_service_role ON %I FOR SELECT TO service_role
       USING (user_id = auth.uid())', t, t);
    EXECUTE format(
      'CREATE TRIGGER %I_updated BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
  END LOOP;
END $$;

GRANT SELECT, INSERT, UPDATE, DELETE ON canvas_sessions, canvas_comments TO authenticated;
```

⚠️ Si `artifacts` n'existe pas dans l'instance live (collision de nom, cf. règle supabase-mcp) : renommer la table canvas en `canvas_documents` et retirer le FK `artifact_id`. Le FK est nullable + `ON DELETE SET NULL` : un canvas orphelin reste lisible.

**Step 2: Appliquer via le MCP (cf. règle supabase-mcp — bloc par bloc, collision check d'abord)**

1. `mcp__supabase__list_migrations` → delta.
2. Vérifier collisions : `SELECT relname FROM pg_class WHERE relname IN ('canvas_sessions','canvas_comments','artifacts')`.
3. `mcp__supabase__execute_sql` — appliquer le fichier en 3 blocs (2× CREATE TABLE+INDEX / DO$$+GRANT). Le MCP échoue sur le dollar-quoting imbriqué → si `DO $$...END $$` plante, décomposer en instructions autonomes (ALTER + CREATE POLICY par table).

**Step 3: Gate statique RLS**

Run: `sh scripts/check-rls.sh`
Expected : `RLS static checks passed` (les 2 nouvelles tables sont couvertes par le scan global).

**Step 4: Commit**

```bash
git add supabase/migrations/0022_canvas.sql
git commit -m "feat(canvas): migration 0022 canvas_sessions + canvas_comments (RLS user)"
```

---

## Task 3: Types domain + client canvas (node:test, TDD)

**Files:**
- Create: `packages/domain/src/entities-canvas.ts`
- Modify: `packages/domain/src/index.ts` (export)
- Create: `apps/mobile/src/lib/canvas-client.ts`
- Create: `apps/mobile/test/canvas-client.test.ts`

**Step 1: Types (SSoT contenu du bloc)**

`packages/domain/src/entities-canvas.ts` :
```ts
/** Canvas entities (0022). Un canvas = session d'édition d'artefact ;
 *  le SSoT contenu = markdown par bloc (block.kind 'md'). */
export interface CanvasBlock {
  id: string;
  /** v1 unique : 'md' (markdown éditable TipTap). */
  kind: 'md';
  /** contenu markdown du bloc. */
  content: string;
}

export interface CanvasSession {
  id: string;
  userId: string;
  title: string;
  blocks: CanvasBlock[];
  artifactId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CanvasComment {
  id: string;
  userId: string;
  sessionId: string;
  /** offset [start, end) dans le texte plat de la session (join '\n\n'). */
  anchorStart: number;
  anchorEnd: number;
  body: string;
  createdAt: string;
}
```
Ajouter dans `packages/domain/src/index.ts` : `export * from './entities-canvas';`

**Step 2: Écrire le test qui échoue**

`apps/mobile/test/canvas-client.test.ts` :
```ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCanvasClient, type CanvasClient } from '../src/lib/canvas-client.ts';

/** Supabase fake minimal : la couche postgrest (from()) + les types. */
function fakeSupabase(responses: Map<string, unknown[]>) {
  return {
    from(table: string) {
      const rows = responses.get(table) ?? [];
      let filter: Record<string, unknown> | undefined;
      const chain: Record<string, unknown> = {};
      const chainable = new Proxy({} as Record<string, unknown>, {
        get(_, prop) {
          if (prop === 'eq') return (k: string, v: unknown) => { filter = { [k]: v }; return chainable; };
          if (prop === 'select') return (cols: string) => chainable;
          if (prop === 'upsert') return (payload: unknown) => { chain.__upserted = payload; return chainable; };
          if (prop === 'insert') return (payload: unknown) => { chain.__inserted = payload; return chainable; };
          if (prop === 'then') return (ok: (r: unknown) => unknown) =>
            ok({ data: filter ? rows.filter((r) => (r as Record<string, unknown>)[filter!['id']] === filter!['id']) : rows, error: null });
          return undefined;
        },
      });
      return chainable;
    },
  };
}

test('get renvoie null quand la row est absente (AD-7: état vide honnête, jamais de fausse data)', async () => {
  const client = createCanvasClient(fakeSupabase(new Map()), 'test-key') as CanvasClient;
  assert.equal(await client.get('nonexistent'), null);
});

test('create insère avec user_id scope (AD-3: la row est bornée par l\'appelant)', () => {
  // Vérifié par le test d'intégration 0022 (live RLS) — ici on n'exige que
  // que le client EXPOSE la surface (API contract).
  const client = createCanvasClient(fakeSupabase(new Map()), 'test-key') as CanvasClient;
  assert.ok(typeof client.create === 'function');
  assert.ok(typeof client.addComment === 'function');
});
```

⚠️ Le fake ci-dessus est le strict minimum viable ; si le Proxy se révèle fragile à l'exécution, simplifier le test contractuel : `createCanvasClient` doit exposer exactement `{ get, save, create, listComments, addComment, deleteComment }` (assert par noms de méthodes), et garder les tests de comportement dans le vitest jsdom (Task 8). L'important : le contrat de surface est figé par un test.

**Step 3: Lancer le test — il échoue**

Run: `node --experimental-strip-types --no-warnings --test apps/mobile/test/canvas-client.test.ts`
Expected : FAIL (`Cannot find module '../src/lib/canvas-client.ts'`).

**Step 4: Implémenter `canvas-client.ts`**

`apps/mobile/src/lib/canvas-client.ts` (pattern `agent-client.ts` — commentaire d'en-tête AD-3) :
```ts
/**
 * canvas-client.ts — device-side canvas client (0022, AD-3).
 * Publishable Supabase client only — zero secrets on the device.
 * Les tables canvas_* passent RLS user (0022) : chaque op est bornée
 * par auth.uid(), le scope user n'est PAS en paramètre (RLS fait le job).
 */
import type { AuroraSupabaseClient } from '@aurora/data';
import type { CanvasSession, CanvasBlock, CanvasComment } from '@aurora/domain';

export interface CanvasClient {
  /** GET une session (null = absente — état vide honnête, AD-7). */
  get(id: string): Promise<CanvasSession | null>;
  /** INSERT une nouvelle session (title + blocks initiaux). */
  create(title: string, blocks: CanvasBlock[]): Promise<CanvasSession>;
  /** UPSERT blocs d'une session (debounce côté UI, pas ici). */
  save(id: string, blocks: CanvasBlock[]): Promise<void>;
  /** Commentaires d'une session (tri créa). */
  listComments(sessionId: string): Promise<CanvasComment[]>;
  addComment(sessionId: string, anchor: { start: number; end: number }, body: string): Promise<CanvasComment>;
  deleteComment(commentId: string): Promise<void>;
}

const mapSession = (row: Record<string, unknown>): CanvasSession => ({
  id: String(row.id),
  userId: String(row.user_id),
  title: String(row.title ?? ''),
  blocks: (row.blocks as CanvasBlock[]) ?? [],
  artifactId: row.artifact_id ? String(row.artifact_id) : undefined,
  createdAt: String(row.created_at),
  updatedAt: String(row.updated_at),
});

const mapComment = (row: Record<string, unknown>): CanvasComment => ({
  id: String(row.id),
  userId: String(row.user_id),
  sessionId: String(row.session_id),
  anchorStart: Number(row.anchor_start),
  anchorEnd: Number(row.anchor_end),
  body: String(row.body),
  createdAt: String(row.created_at),
});

export function createCanvasClient(
  supabase: AuroraSupabaseClient,
  supabaseKey: string,
): CanvasClient {
  const s = supabase as unknown as Record<string, (...a: unknown[]) => unknown>;
  return {
    async get(id) {
      const { data, error } = await (s.from('canvas_sessions')! as any)
        .select('*').eq('id', id);
      if (error) throw new Error(`canvas get: ${error.message ?? 'unknown'}`);
      return data?.[0] ? mapSession(data[0]) : null;
    },
    async create(title, blocks) {
      const { data, error } = await (s.from('canvas_sessions')! as any)
        .insert({ title, blocks }).select('*').single();
      if (error) throw new Error(`canvas create: ${error.message ?? 'unknown'}`);
      return mapSession(data);
    },
    async save(id, blocks) {
      const { error } = await (s.from('canvas_sessions')! as any)
        .update({ blocks }).eq('id', id);
      if (error) throw new Error(`canvas save: ${error.message ?? 'unknown'}`);
    },
    async listComments(sessionId) {
      const { data, error } = await (s.from('canvas_comments')! as any)
        .select('*').eq('session_id', sessionId).order('created_at');
      if (error) throw new Error(`comments: ${error.message ?? 'unknown'}`);
      return (data ?? []).map(mapComment);
    },
    async addComment(sessionId, anchor, body) {
      const { data, error } = await (s.from('canvas_comments')! as any)
        .insert({ session_id: sessionId, anchor_start: anchor.start, anchor_end: anchor.end, body })
        .select('*').single();
      if (error) throw new Error(`comment add: ${error.message ?? 'unknown'}`);
      return mapComment(data);
    },
    async deleteComment(commentId) {
      const { error } = await (s.from('canvas_comments')! as any)
        .delete().eq('id', commentId);
      if (error) throw new Error(`comment delete: ${error.message ?? 'unknown'}`);
    },
  };
}
```
(Nota : le `supabaseKey` est accepté mais NON transmis — AD-3 le client injecté est déjà scoped ; le paramètre préserve la signature testable de `agent-client.ts`.)

**Step 5: Lancer le test — il passe**

Run: `node --experimental-strip-types --no-warnings --test apps/mobile/test/canvas-client.test.ts`
Expected : PASS.

**Step 6: Typecheck**

Run: `pnpm -F @aurora/mobile typecheck`
Expected : PASS.

**Step 7: Commit**

```bash
git add packages/domain/src/entities-canvas.ts packages/domain/src/index.ts apps/mobile/src/lib/canvas-client.ts apps/mobile/test/canvas-client.test.ts
git commit -m "feat(canvas): types domain + client postgrest (0022, AD-3)"
```

---

## Task 4: Utils markdown ⇄ HTML (vitest jsdom dans packages/ui, TDD)

**Files:**
- Create: `packages/ui/src/lib/canvas-utils.ts`
- Create: `packages/ui/src/lib/canvas-utils.test.ts`

**Step 1: Écrire le test qui échoue**

`packages/ui/src/lib/canvas-utils.ts.test.ts` :
```ts
import { describe, it, expect } from 'vitest';
import { markdownToHtml, commentAnchors } from './canvas-utils.ts';

describe('markdownToHtml', () => {
  it('rend un titre + un paragraphe en HTML', () => {
    const html = markdownToHtml('# Titre\n\nBonjour le **monde**.');
    expect(html).toContain('<h1');
    expect(html).toContain('Titre');
    expect(html).toContain('<strong>monde</strong>');
  });
  it('échappe le HTML brut (pas de <script> injectable)', () => {
    expect(markdownToHtml('<script>alert(1)</script>')).not.toContain('<script>alert');
  });
});

describe('commentAnchors (offsets sur le texte plat = join "\\n\\n")', () => {
  it('trouve l\'ancre du commentaire dans le 2e bloc', () => {
    const flat = 'Bloc un\n\nBloc deux';
    const offsets = commentAnchors('un', ['Bloc un', 'Bloc deux']);
    expect(offsets).toEqual([5, 7]); // 'un' dans la flat (offsets 5..7, hors \n\n)
  });
});
```
(Ajuster les offsets attendus en exécutant : la fonction `commentAnchors(term, blocks)` retourne `[start, end)` de `term` dans `blocks.join('\n\n')`. Si `term` n'est pas présent → `null`. Enregistrer les valeurs exactes observées au 1er run vert comme contrat.)

**Step 2: Lancer — échec**

Run: `pnpm -F @aurora/ui test canvas-utils`
Expected : FAIL (module absent).

**Step 3: Implémenter**

`packages/ui/src/lib/canvas-utils.ts` :
```ts
/**
 * canvas-utils — conversions SSoT contenu canvas (0022, AD-10 pattern).
 * Le SSoT contenu = markdown par bloc ; le rendu HTML (onglet lecture)
 * passe par marked + sanitization minimale (pas de raw HTML dans le md).
 */
import { marked } from 'marked';

const renderer = new marked.Renderer();
// Interdiction du HTML brut dans le markdown canvas (AD-16b sécurité) :
// marqué par défaut échappe ; on verrouille explicitly.
renderer.html = () => '';

export function markdownToHtml(md: string): string {
  const html = marked.parse(md, { renderer, breaks: true, gfm: true });
  return typeof html === 'string' ? html : '';
}

/**
 * Ancre de commentaire : offsets [start, end) de `term` dans le texte
 * plat de la session (`blocks.map(b => b.content).join('\n\n')`).
 * null si le terme n'est pas trouvé.
 */
export function commentAnchors(
  term: string,
  blocks: Array<{ content: string }>,
): [number, number] | null {
  if (!term) return null;
  const flat = blocks.map((b) => b.content).join('\n\n');
  const start = flat.indexOf(term);
  if (start < 0) return null;
  return [start, start + term.length];
}
```
Exporter `markdownToHtml`/`commentAnchors` depuis `packages/ui/src/index.ts` (une seule ligne) pour la frontière AD-1.

**Step 4: Lancer — passe**

Run: `pnpm -F @aurora/ui test canvas-utils`
Expected : PASS (4 assertions + échappement script).

**Step 5: Commit**

```bash
git add packages/ui/src/lib/canvas-utils.ts packages/ui/src/lib/canvas-utils.test.ts packages/ui/src/index.ts
git commit -m "feat(canvas): utils md→html + ancres de commentaire (marked, jsdom)"
```

---

## Task 5: Hook `useCanvas` (chargement + save debounce + commentaires)

**Files:**
- Create: `apps/mobile/src/query/canvas.ts`
- Modify: `apps/mobile/src/query/context.tsx` (exposer `canvas` sur `MobileDataProvider`, comme `agent`)
- Modify: `apps/mobile/src/shell/*.tsx` (boot : construire `createCanvasClient(supabase, key)` si l'env existe — localiser le fichier de boot qui construit l'`agent` client, c'est le même endroit)

**Step 1: Écrire le hook**

`apps/mobile/src/query/canvas.ts` :
```ts
// canvas.ts — canvas device hooks (0022, AD-7/AD-3).
// useCanvas(id): charge la session + commentaires ; save est un upsert
// debounce 1 s des blocs (le bloc jsonb est le SSoT contenu).
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { qk } from './query-client';
import { useMobileData } from './context';
import type { CanvasBlock, CanvasComment } from '@aurora/domain';

export function useCanvasSession(id: string | undefined) {
  const { canvas } = useMobileData();
  return useQuery<{ session: import('@aurora/domain').CanvasSession | null; comments: CanvasComment[] }>({
    queryKey: qk.canvas.session(id ?? ''),
    queryFn: async () => {
      if (!canvas || !id) return null;
      const [session, comments] = await Promise.all([
        canvas.get(id),
        canvas.listComments(id),
      ]);
      return { session, comments };
    },
    enabled: Boolean(canvas && id),
    retry: false,
  });
}

/** Sauvegarde debounce 1 s des blocs (l'upsert porte la charge réseau). */
export function useCanvasSave() {
  const { canvas } = useMobileData();
  const qc = useQueryClient();
  let timer: ReturnType<typeof setTimeout> | undefined;
  return (id: string, blocks: CanvasBlock[]) => {
    clearTimeout(timer);
    timer = setTimeout(async () => {
      await canvas!.save(id, blocks);
      qc.invalidateQueries({ queryKey: qk.canvas.session(id) });
    }, 1000);
  };
}
```
Ajouter `canvas?: CanvasClient` sur `MobileDataProvider` + une entrée `canvas` dans la fabrique `qk` (`qk.canvas = (id) => ['canvas', id]` — trouver la `qk` dans `query-client.ts`).

**Step 2: Brancher le client au boot**

Dans le fichier de boot qui construit `agent` (grep `createAgentClient` dans `apps/mobile/src/`), ajouter :
```ts
canvas: supabase && publishableKey ? createCanvasClient(supabase, publishableKey) : undefined,
```

**Step 3: Typecheck + test contractuel du hook**

Run: `pnpm -F @aurora/mobile typecheck`
Expected : PASS.
(Pour un test du debounce : le repousser à Task 7 avec le composant — le hook seul n'apporte pas de test isolable sans DOM, YAGNI.)

**Step 4: Commit**

```bash
git add apps/mobile/src/query/canvas.ts apps/mobile/src/query/context.tsx apps/mobile/src/query/query-client.ts apps/mobile/src/shell/
git commit -m "feat(canvas): hook useCanvas (load + save debounce + comments)"
```

---

## Task 6: Page `/canvas/:id` (bloc éditable + menu sélection + commentaires + bascule md/HTML)

**Files:**
- Create: `apps/mobile/src/pages/canvas/index.tsx`
- Create: `apps/mobile/src/styles/canvas.css`
- Modify: `apps/mobile/src/main.tsx` (import `canvas.css` — pattern des autres styles)
- Modify: `apps/mobile/src/router.tsx` (route + `AppRoute` l. 115)

**Step 1: Route**

`apps/mobile/src/router.tsx` :
```tsx
import { CanvasPage } from './pages/canvas';
// ... dans children:
{ path: '/canvas/:id', element: <CanvasPage /> },
// AppRoute:
| '/canvas/:id'
```

**Step 2: Le composant**

`apps/mobile/src/pages/canvas/index.tsx` (squelette, à compléter dans l'implémentation — 4 blocs de responsabilités) :
```tsx
/**
 * CanvasPage — /canvas/:id (0022). Blocs TipTap éditables + commentaires
 * sur sélection + « indexer dans le chat » + bascule md ⇄ HTML de l'artefact.
 * Pattern UxStates 6 états (docs/design-system) : offline/killed/loading/
 * empty/error — jamais de preview factice.
 */
import { useParams } from 'react-router-dom';
import { EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { useState, useRef, useEffect } from 'react';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useCanvasSession, useCanvasSave } from '../../query/canvas';
import { useMobileData } from '../../query/context';
import { useOnlineStatus } from '../../hooks/use-online';
import { useUiStateStore } from '../../state/ui-state';
import { markdownToHtml } from '@aurora/ui';
import type { CanvasBlock } from '@aurora/domain';

type View = 'edit' | 'markdown' | 'html';

export function CanvasPage() {
  const { id } = useParams<{ id: string }>();
  const [view, setView] = useState<View>('edit');
  const { data, status, isError } = useCanvasSession(id);
  const save = useCanvasSave();
  const [comments, setComments] = useState<CanvasComment[]>([]);
  const [view, setView] = useState<View>('edit');
  const [selection, setSelection] = useState<{ text: string; x: number; y: number } | null>(null);
  const [addingComment, setAddingComment] = useState(false);
  const [commentDraft, setCommentDraft] = useState('');
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = { offline: !online, killed };

  const session = data?.session ?? null;
  // Édition : blocs locaux (le state UI est le SSoT pendant l'edition ;
  // le save debouncé les pousse vers 0022).
  const [blocks, setBlocks] = useState<CanvasBlock[]>(session?.blocks ?? [{ id: 'b1', kind: 'md', content: '' }]);
  useEffect(() => { if (session) setBlocks(session.blocks); }, [session?.id]);

  // Sélection canvas → menu flottant (pattern selectionToDraft d'/agent)
  useEffect(() => { /* observer document 'selectionchange' borné au container */ }, []);

  function onIndexInChat() {
    if (!selection) return;
    // Indexation verbatim dans le chat : préfixe contextuel (session + bloc),
    // navigation au /agent avec le draft pré-rempli (?q= encoded).
    const text = `>[canvas ${id}/${currentBlock?.id}] ${selection.text}`;
    window.location.assign(`/agent?q=${encodeURIComponent(text)}`);
    setSelection(null);
    window.getSelection()?.removeAllRanges();
  }

  function onAddComment() {
    if (!selection || !commentDraft.trim() || !id) return;
    void canvas?.addComment(id, commentAnchors(selection.text, blocks), commentDraft.trim()).then((c) => {
      setComments((prev) => [...prev, c]);
      setCommentDraft('');
      setAddingComment(false);
    });
  }

  const htmlRender = view === 'html' ? markdownToHtml(blocks.map((b) => b.content).join('\n\n')) : null;

  return (
    <>
      <IonHeader>...</IonHeader>
      <IonContent>
        <div className="canvas-page" data-canvas-id={id}>
          <div className="canvas-toolbar" role="toolbar">
            {(['edit', 'markdown', 'html'] as const).map((v) => (
              <button key={v} type="button" className={view === v ? 'is-active' : ''} onClick={() => setView(v)}>
                {v === 'edit' ? 'Éditer' : v === 'markdown' ? 'Markdown' : 'HTML'}
              </button>
            ))}
          </div>

          <UxStates state={...}> {/* loading si session; empty si !id; error si isError */}
            {view === 'edit' && (
              <div className="canvas-editor" data-canvas="editor">
                {blocks.map((b) => (
                  <CanvasBlockEditor key={b.id} block={b} onChange={(content) => {
                    setBlocks((prev) => prev.map((x) => (x.id === b.id ? { ...x, content } : x)));
                  }} />
                ))}
              </div>
            )}
            {view === 'markdown' && (
              <pre className="canvas-source">{blocks.map((b) => b.content).join('\n\n')}</pre>
            )}
            {view === 'html' && (
              <div className="canvas-html" dangerouslySetInnerHTML={{ __html: htmlRender ?? '' }} />
            )}

            {selection && (
              <div className="canvas-selection-menu" style={{ left: selection.x, top: selection.y }} role="menu">
                <button type="button" onClick={onIndexInChat}>Indexer dans le chat</button>
                <button type="button" onClick={() => setAddingComment((v) => !v)}>Commenter</button>
              </div>
            )}
            {addingComment && (
              <div className="canvas-comment-composer">
                <textarea value={commentDraft} onChange={(e) => setCommentDraft(e.target.value)} aria-label="Commentaire" />
                <button type="button" onClick={onAddComment}>Envoyer</button>
              </div>
            )}
            {comments.length > 0 && <div className="canvas-comments">{/* liste + suppression */}</div>}
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}

function CanvasBlockEditor({ block, onChange }: { block: CanvasBlock; onChange: (md: string) => void }) {
  const editor = useEditor({
    extensions: [StarterKit],
    content: block.content,
    onTransaction: () => {
      // normalisation SSoT : markdown → TipTap → markdown (idempotent),
      // le state UI porte le markdown (pas le JSON) → la bascule de vue
      // est une vue sur un SSoT unique.
      if (editor && !editor.isDestroyed) onChange(editor.isEmpty ? '' : stripTipTapJson(editor.getJSON(), block.content));
    },
  });
  return <EditorContent editor={editor} className="canvas-block" />;
}
```
`stripTipTapJson(json, fallbackMd)` : util local qui re-sérilise le doc TipTap en markdown (via `editor.storage.markdown?.get?.(state)` si dispo, sinon `fallbackMd` — la v1 accepte le Fallback : la bascule md/HTML ne casse pas l'editing ; noter en TODO dans le fichier). L'essentiel pour v1 : **l'état du SSoT = le markdown du bloc** ; le JSON TipTap est un intermédiaire éphémère de l'édition.

**Step 3: Styles (pattern `agent.css`)**

`apps/mobile/src/styles/canvas.css` : `.canvas-page`, `.canvas-toolbar`, `.canvas-block` (min-height 320px, contenteditable focus ring tokens `--aurora-*`), `.canvas-selection-menu` (position fixed, z-index sur les gestures d'agent), `.canvas-html` (typographie 02 S6 : 16px/1.6). Import dans `main.tsx` à côté de `agent.css`.

**Step 4: Vérification manuelle + typecheck**

Run: `pnpm -F @aurora/mobile typecheck && pnpm -F @aurora/mobile lint`
Puis `pnpm dev` → `/canvas/<id>` (avec une session 0022 créée manuellement en SQL pendant le dev — ou un canvas sans id → état empty avec CTA « Nouvelle session » si l'env `canvas` est disponible ; sinon état offline honnête).

**Step 5: Commit**

```bash
git add apps/mobile/src/pages/canvas/ apps/mobile/src/styles/canvas.css apps/mobile/src/router.tsx apps/mobile/src/main.tsx
git commit -m "feat(canvas): page /canvas/:id — blocs TipTap + commentaires + md⇄HTML"
```

---

## Task 7: Mode canvas depuis `/agent` (bouton + préfill du draft)

**Files:**
- Modify: `apps/mobile/src/pages/agent/index.tsx`
- Modify: `apps/mobile/src/styles/agent.css`

**Step 1: Bouton « Canvas » dans la rangée de chips actives**

Dans `AgentPage` (après le chip `+`, ligne ~654) :
```tsx
<button
  type="button"
  className="agent-chip"
  onClick={() => navigate(`/canvas/${canvasId ?? 'new'}`, { state: { from: '/agent' } })}
  aria-label="Ouvrir le canvas"
>
  <PenLine size={12} />
  <span>Canvas</span>
</button>
```
(où `canvasId` = l'artefact courant de la session si dispo, sinon `'new'` = création au retour.)

**Step 2: Préfill du draft par `?q` (indexation verbatim depuis le canvas)**

En tête du composant :
```tsx
const [searchParams] = useSearchParams();
const qParam = searchParams.get('q');
useEffect(() => {
  if (qParam) {
    setDraft((prev) => (prev ? prev + '\n' + qParam : qParam));
    // nettoie le param sans bloquer l'historique (state.from préservé)
    searchParams.delete('q');
    navigate({ search: searchParams.toString() }, { replace: true });
  }
}, []); // mount only
```
Le texte indexé depuis le canvas arrive préfixé `>[canvas ...]` → le user peut le copier tel quel ou l'étoffer avant l'envoi.

**Step 3: Typecheck + test contractuel (apps/mobile/test)**

Écrire dans un test node:test que la page agent rend un bouton `.agent-chip` dont l'aria-label contient « canvas » — exécution par build vite d'un SSR minimal est trop lourd ; le test contractuel accepté ici = grep sur le fichier (pattern `release-gate.test.ts`) :
```ts
test('agent page expose l\'entrée canvas (0022)', () => {
  const src = readFileSync(join(REPO_ROOT, 'apps/mobile/src/pages/agent/index.tsx'), 'utf8');
  assert.ok(src.includes('/canvas/'), 'entrée canvas manquante');
  assert.ok(src.includes('searchParams.get(\'q\')'), 'prefill ?q manquant');
});
```

**Step 4: Commit**

```bash
git add apps/mobile/src/pages/agent/index.tsx apps/mobile/src/styles/agent.css apps/mobile/test/
git commit -m "feat(agent): entrée canvas + prefill du draft par ?q (indexation verbatim)"
```

---

## Task 8: Tests UI (vitest jsdom, packages/ui) + gate finale

**Files:**
- Create: `packages/ui/test/canvas-page.test.tsx` (test contractuel du pattern page canvas : la toolbar md/html bascule + le menu sélection n'apparaît QUE pour une sélection dans le container canvas)

**Step 1: Le test**

```tsx
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { CanvasPage } from '@aurora/ui'; // si le composant est hébergé ui-side ; sinon : tester les sous-composants ui exposés

describe('canvas toolbar (0022)', () => {
  it('bascule markdown ⇄ HTML sur le même contenu (un seul SSoT)', () => {
    // render(<CanvasToolbar view="edit" onChange={...}/>) ; clic « HTML »
    // → l'output = rendu markdownToHtml du même contenu (idempotence)
  });
});
```
Si le `CanvasPage` entier reste en apps/mobile (décision : oui, voir Task 6), tester dans `apps/mobile/test/` avec le setup jsdom de `packages/ui` en ré-utilisant `@testing-library/react` (déjà présent, vérifier `packages/ui/test/setup.ts`). Le test minimal acceptable v1 : la pureté de `markdownToHtml` (déjà testée Task 4) + le composant toolbar isolé.

**Step 2: Gate finales**

```bash
sh scripts/check-rls.sh                 # (déjà passé à la Task 2, re-runs sont idempotentes)
pnpm -F @aurora/ui test                # jsdom
pnpm -F @aurora/mobile typecheck && pnpm -F @aurora/mobile lint
node --experimental-strip-types --no-warnings --test apps/mobile/test/*.test.ts
```
Expected : tout vert.

**Step 3: Test RLS live (rule supabase-mcp, TODO wave 1)**

Via `mcp__supabase__execute_sql` :
```sql
SET ROLE authenticated;
SET request.jwt.claims = '{"sub":"<user_a>"}';
SELECT count(*) FROM canvas_sessions WHERE user_id = '<user_b>';
-- → 0 attendu (user A ne lit pas user B)
```

**Step 4: Commit + doc**

```bash
git add packages/ui/test/ docs/progress/
git commit -m "test(canvas): toolbar md⇄html (jsdom) + gate 0022"
```
Mettre à jour `progress/claude.md` (checklist 0022 + le canvas dans l'inventaire des routes).

---

## Définitions de fin (feature)

- `/canvas/:id` : blocs TipTap éditables, menu sélection (Indexer dans le chat / Commenter), bascule md ⇄ HTML sur un SSoT unique (markdown).
- `/agent` : chip « Canvas » + prefill du draft par `?q` (verbatim, contextualisé `>[canvas …]`).
- Commentaire = texte + ancre d'offsets `[start, end)` sur le texte plat de la session (`blocks.join('\n\n')`) ; persisté dans `canvas_comments` (0022), RLS user.
- « Indexer une sélection dans le chat » = préfixage du texte sélectionné dans le composer agent (zéro nouveau backend) ; le verbatim reste réversible (le user peut l'éditer avant l'envoi).
- Bascule markdown/HTML = **une seule source de contenu** ; le HTML n'est qu'un rendu lecture (onglet), pas un 2e bloc éditable.
- Hors périmètre v1 : multi-collab CRDT temps réel, drag-and-drop de blocs, exports PDF/DOCX du canvas, images inline dans le bloc md.

## Risques et notes d'implémentation

- **TipTap mobile + keyboard (Capacitor)** : `contenteditable` dans la webview → éviter le défilement du viewport quand le clavier s'ouvre (Keyboard plugin Capacitor déjà présent ; pattern inbox à réutiliser).
- **RLS live (TODO wave 1)** : le test d'intégration user A ne lit pas user B sur `canvas_sessions`/`canvas_comments` doit passer avant push ; `execute_sql` via le MCP (cf. règle supabase-mcp).
- **`?q` ne doit pas polluer l'historique** : `replace: true` + `state.from` préservé (pattern agent-page existant).
- **`check-rls.sh`** reste le gate statique à re-runs à chaque migration ajoutée ; la Task 2 est déjà dans le chemin.
- **Idempotence md ⇄ HTML** : la normalisation du SSoT markdown doit être stable (markdown → TipTap JSON → markdown = identique) pour que la bascule de vue ne corrompe pas l'édition ; la Task 6 note le `stripTipTapJson` fallback.
