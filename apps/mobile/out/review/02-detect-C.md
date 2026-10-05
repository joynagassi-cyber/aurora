# 02 — Detect C : concurrency / effect bugs + form 4-state gaps

**Lens** : C — concurrence, effet-bord, in-flight guards, forme 4-états.
**Scope** : `pages/skills/index.tsx` (505), `pages/agent/index.tsx` (483), `pages/integrations/index.tsx` (249) + `styles/agent.css`.
**Méthode** : lecture séquentielle des trois fichiers, greps ciblés `useEffect`/`useRef`/`catch`, vérif CSS `safe-area-inset-bottom`.

---

## Résumé

| Sévérité | Qté |
|----------|-----|
| 🔴 Critical | 1 |
| 🟡 High | 2 |
| 🟠 Medium | 3 |
| 🔵 Low | 3 |
| **Total** | **9** |

---

## Liste classée

| # | severity | file:line | category | symptom | fix_hint | confidence |
|---|----------|-----------|----------|---------|----------|------------|
| 1 | 🔴 Critical | `src/pages/integrations/index.tsx:185-196` | concurrency | « Tout connecter » déclenche 5 `window.open` simultanes — l'utilisateur voit potentiellement 5 popups OAuth empilés ; le `forEach` est synchrone, aucun `await`, aucun `Promise.all` ; chaque `toggle()` reset `setConnectError(null)` → seul le dernier échec s'affiche, les autres sont silencieusement écrasés. | Factoriser avec `Promise.allSettled(google.map((g) => toggle(g.id)))` + attendre avant de réinitialiser ; ajouter un flag `isConnecting` global + `disabled` sur le preset button pendant l'opération. | 🟢 |
| 2 | 🟡 High | `src/pages/skills/index.tsx:420-424` + `451-454` | unhandled-rejection | Les deux inline `onClick={async () => {…}}` (toggle perso + désactiver catalog-activated) n'ont aucun `.catch` et ne capturent pas les erreurs — si `deactivateSkill` ou `activateSkill` rejette, l'erreur rebondit comme un unhandled promise rejection dans la console, l'UI ne se met pas à jour, et l'utilisateur ne reçoit aucun feedback. | Ajouter `try/catch` explicite avec `setLoadError(...)` ou un toast d'erreur, et `disabled` sur le bouton pendant l'opération. | 🟢 |
| 3 | 🟡 High | `src/pages/integrations/index.tsx:89-107` + `:185-196` | concurrency | 5 appels `connect()` parallèles sans `disabled` global, sans déduplication, sans état de chargement par item — le bouton « Tout connecter » reste cliquable pendant que les 5 connexions s'exécutent ; clic redondant = 5x plus de requests + 5 popups. | Ajouter un booléen `isConnecting` shared, `disabled={isConnecting}` sur le preset et tous les toggles, `setIsConnecting(true/false)` avec `finally`. | 🟢 |
| 4 | 🟠 Medium | `src/pages/agent/index.tsx:129-149` | concurrency | Deux `useEffect` séparés, même clé `[runRow, activeRun]` : le premier pousse un entry terminal, le deuxième scroll. Si `runRow` arrive puis `activeRun` est cleared dans le premier effet, le second effect voit `[runRow, undefined]` et sa condition `runRow.id === activeRun` échoue — pas de double-scroll. **Cependant** : aucun cleanup, pas de `useRef` pour capturer la dernière valeur, et si un second `runRow` arrive pendant l'exécution du premier (micro-task), les deux effets peuvent se superposer. | Fusionner les deux effets en un seul (`useEffect` avec `setEntries` + scroll synchrones), ou capturer `runRow` via ref pour éviter les ratches. | 🟡 |
| 5 | 🟠 Medium | `src/pages/skills/index.tsx:93-120` | concurrency | `toggleCatalogSkill` n'a aucun in-flight guard : taper rapidement sur 5 cartes « Activer » déclenche 5 appels `activateSkill` parallèles. L'état `userSkills` est rafraîchi après chaque appel, mais comme `activeKeys` vient du state antérieur, chaque toggle voit `isActive = false` et envoie son propre activate — risque de 5 rows dupliquées ou d'état incohérent si le backend est idempotent (ou pire, si non-idempotent). | Ajouter un `Set<string>` de `inFlightKeys` dans un `useRef` pour bloquer les appels multiples sur la même clé. | 🟢 |
| 6 | 🟠 Medium | `src/pages/skills/index.tsx:131-149` | form-state | `createPersonalSkill` : si `createUserSkill` réussit mais `listUserSkills` échoue (ligne 143), le `catch` (l.144-148) set `setLoadError(...)` avec le message de la LISTE, pas de la création — l'utilisateur voit un message trompeur alors que le skill a été créé côté serveur. Form fields (`newSkillName`, `newSkillTrigger`, `showCreate`) sont remis à zéro (l.140-142) avant le list — bon UX, mais le loadError induit en erreur. | Séparer le try/catch du list en bloc indépendant, ou utiliser un `loadError` spécifique (ex. « Impossible de rafraîchir la liste ») distinct de « création en échec ». | 🟢 |
| 7 | 🔵 Low | `src/pages/skills/index.tsx:122-129` | unhandled-rejection | `deletePersonalSkill` appelé via `onClick={() => void deletePersonalSkill(...)}` (l.411) — le `void` avale la promesse, mais s'il rejette, c'est une unhandled rejection en console ; l'UI ne reflète pas l'erreur, le skill reste affiché mais potentiellement déjà supprimé côté serveur. | Wrap dans try/catch avec `setLoadError` ou ignoré si le comportement « optimistic delete » est acceptable (pas de rollback sur erreur). | 🟡 |
| 8 | 🔵 Low | `src/pages/agent/index.tsx:313-319` | form-state | Input composer : `disabled={!agent || isFetching}` — `isFetching` est truthy dès que `useAgentRun` refetch (polling 3s). Sur mobile iOS/Android, l'input natif n'a pas de gestion automatique de la safe-area via le framework Ionic — le CSS `agent-composer` inclut `env(safe-area-inset-bottom)` (l.175), ce qui compense visuellement, mais l'input lui-même n'est pas within un `IonInput` qui gérerait le keyboard resize automatiquement. | Remplacer le `<input>` natif par `<IonInput>` ou s'assurer que `overflow-scroll` est activé sur le parent (`IonContent` l'est déjà par défaut) — vérifier avec un device physique. | 🟡 |
| 9 | 🔵 Low | `src/pages/skills/index.tsx:358-395` | form-state | Formulaire create personal skill : pas d'état `error` propre au formulaire (le `loadError` est partagé avec le catalogue, l.226-235). L'utilisateur ne sait pas si l'erreur vient de la création ou du load initial. Le champ name/trigger n'ont pas de validation inline (regex, longueur max). | Ajouter un `formError` local (useState) affiché juste sous le bouton « Créer », distinct de `loadError` ; limiter `newSkillName` à ex. 80 chars. | 🟡 |

---

## Vérifié clean / NON-findings

- **`agent/index.tsx:135-137` double-terminal-entry** : la garde `prev.some((e) => e.id === id)` est **suffisante** — même si les deux effets firent ensemble, le premier effect ajoute l'entrée avec `id = term:${runRow.id}` et le second n'ajoute rien (pas de push). Aucun double-push.
- **`agent/index.tsx:140` `setActiveRun(undefined)` twice** : impossible — le second effet ne modifie pas `activeRun`, et le premier ne peut pas fire deux fois sur le même `runRow` (la clé `[runRow, activeRun]` change après le premier set).
- **`skills/index.tsx` : pas de `useEffect` cleanup** — confirmé par grep : un seul `useEffect` (l.89) pour `loadAll`, pas de `useRef` ailleurs dans le fichier. Ce n'est pas un bug en soi car il n'y a pas de subscription externe à nettoyer (les appels sont des `await` sync dans `useCallback`).
- **`agent/index.tsx:submit()` in-flight guard** : `thinking` est `activeRun !== undefined && !runRow` (l.118). Le bouton send est `disabled={!agent || draft.trim().length === 0 || thinking}` (l.322). **Aucune fenêtre** où le bouton serait enabled mais le run pas démarré — le `setActiveRun(handle.traceId)` (l.168) est synchrone juste avant la fin de `submit()`.
- **`integrations/index.tsx` : connectError stacking** — il n'y a qu'un seul `connectError` state, pas de stack d'erreurs. Seul le dernier setting de `setConnectError` persiste. Ce n'est pas un « stack de banners » mais plutôt un error swap silencieux.
- **Safe-area agent.css:175** : `padding: 12px 16px calc(12px + env(safe-area-inset-bottom))` s'applique bien à `.agent-composer` (conteneur du `<input>`), donc l'input natif a bien l'inset. C'est fonctionnellement correct, mais l'absence de `IonInput` reste un Low risk sur iOS.keyboard.resize.

---

## Question critique (🔴 finding #1)

**Question à poser à l'utilisateur / lead** :
> Sur l'écran `/integrations`, le bouton « Tout connecter » (l.185-196) déclenche 5 appels `window.open` simultérés sans aucune protection. Est-ce que ce comportement est volontaire (l'utilisateur devrait voir 5 popups OAuth d'un coup) ou doit-on le bloquer avec un `Promise.allSettled` + un `disabled` global ? En l'état actuel, seul le dernier échec est affiché dans la bannière `connectError` — les 4 autres échecs sont silencieux.
