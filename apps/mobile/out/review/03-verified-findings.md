# 03 — Verified findings (adversarial-verify panel, 21 agents)

Source : `02-detect.md` (38 findings) · Input au workflow : 7 findings Critical/High les plus
impactés (D1, D2, D3, D4, C1, C2, F1). Méthode : 3 skeptics indépendants par finding
(correctness / severity-context / repro), règle majority-refute (≥2/3 réfutés = finding écarté,
sinon retenu). Le panel a aussi recalibré la sévérité de chaque finding survivant.

## Totaux après vérification

| Finding | Sévérité initiale | Sévérité finale | Réfutations | Statut |
|---------|-------------------|-----------------|-------------|--------|
| D1 | Critical | **Low** | 0 | ✅ survit (downranked) |
| D2 | High | **Low** | 1 (correctness) | ⚠️ survit mais fausse en substance |
| D3 | High | **Medium** | 0 | ✅ survit |
| D4 | High | **Medium** | 0 | ✅ survit |
| C1 | Critical | **Medium** | 1 (severity-context) | ✅ survit (downranked) |
| C2 | High | **Medium** | 0 | ✅ survit (downranked) |
| F1 | High | **Medium** | 1 (severity-context) | ⚠️ survit mais réformulé |
| B1 | High | — | non vérifié | ✅ (re-vérifié par l'orchestrator, voir note 2) |
| B2 | High | — | non vérifié | ✅ (re-vérifié par l'orchestrator, voir note 2) |

### Note 1 — D2 est fausse en substance

Le lens `correctness` (l'agent le plus pointu sur la substance du bug) a **réfuté** D2 :
« showPicker et showPlusSheet **ne peuvent jamais être simultanément true** dans un flow
utilisateur réaliste — chaque exit path du picker (× / Auto / model-select) passe par
`setShowPicker(false)` d'abord ; le trigger du plus-sheet est physiquement couvert par le
scrim du picker (z-index 1000) quand celui-ci est ouvert, et réciproquement. »

Le seul angle qui survit est un **risque de maintenance latent** : aucune garde mutuelle
n'existe structurellement, donc un futur CTA in-page (qui ne navigue pas) pourrait ré-exposer
le double-dialog. **Fix recommandé : ne pas traiter D2 comme un bug ; ajouter 1 ligne de garde
(`if (showPicker) setShowPlusSheet(false)`) en prévention** — coût quasi nul, mais ce n'est
plus un finding High.

### Note 2 — B1/B2 n'ont pas passé par le panel, mais ont été re-vérifiés manuellement

Le scope du workflow (11 findings) ne couvrait pas B1/B2. L'orchestrator a re-vérifié :
- B1 : `src/pages/agent/index.tsx` (grep `type="file"` = 0 ; `AgentRunRequest` dans
  `lib/agent-client.ts:34-49` = pas de champ `files`) → **confirmé**, reste High.
- B2 : `src/pages/inbox/index.tsx` (`captured: string[] = []` hardcodé, l.18 ; le CTA «
  Capturer » ne fait que `setDraft('')`, l.43) → **confirmé**, reste High.

## Récapitulatif des findings à fixer après validation utilisateur

| ID | Sévérité finale | Type de fix |
|----|----------------|-------------|
| D1 | Low | Greffer le pattern `floating.tsx` (Escape + `aria-modal` + focus-trap + scrim-click) sur les 2 overlays agent |
| D2 | Low (latent) | 1 ligne de garde mutuelle (`showPicker` / `showPlusSheet`) |
| D3 | Medium | `aria-controls` + `tabindex` roving + `onKeyDown` arrow-keys sur les tab strips de `skills/index.tsx` + `agent/index.tsx` |
| D4 | Medium | Idem, sur `focus/index.tsx` (2 strips) |
| C1 | Medium | `Promise.allSettled(google.map(g => connectOne(g)))` + flag `isConnecting` + `disabled` |
| C2 | Medium | `try/catch` + `setLoadError` sur les 2 handlers inline `skills/index.tsx:420-424,451-454` |
| F1 | Medium | Remplacer le header SSoT par une déclaration honnête (le connect est un stub — pas de dérive de données réelle) ; brancher `discoverTools()` si la wave-N le justifie |
| B1 | High | Retirer le faux picker de fichiers (AD-7 : honnêteté) tant que le kernel n'expose pas `files` |
| B2 | High | Retirer le CTA « Capturer » (AD-7) tant que le verbe EF Inbox n'est pas câblé |
