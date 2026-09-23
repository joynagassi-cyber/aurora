# Context-Preserving Navigation

Status: design phase. Authority: 02 §4 (layers), 02 §6 (routing), 02 §3 (ui-state
store), 03 §3 (repositories). Rule: **moving between pages never loses the useful
context** — the required example chain:

```
/learn/:courseId → /learn/:courseId/chapters/:chapterId → formula (Tiptap/MathBlock)
→ /learn/:courseId/flashcards?from=formula:&nodeId=… → /learn/:courseId/qcm?from=flashcards
→ /progress/:skillId?from=qcm&session=:sessionId
```

The user can back-navigate at any point and land *in the same place they left*
(entity + position + open overlays), because:

## 1. What travels where (normative)

| Kind | Mechanism | Rule |
|---|---|---|
| **Entity IDs** (course, chapter, node, task, skill, artifact, session) | route params (`:courseId`, `:nodeId`…) | one param per level; IDs come from AD-15 SSoT types (never re-declared); a page with an unknown id = its `error`/`empty` state (02 §7), not a crash |
| **Query params** (filter, `from`, selection, period) | URL search string | serializable + shareable/deep-linkable; the ui-state store mirrors them (store = single writer of the cosmetic state, 02 §3.2; URL → store on mount, store → URL on change) |
| **Navigation state** (which tab, open overlays/modals, stack depth) | IonRouter + IonModal stack (02 §6.1: details open **over** the tab, never switch tabs) | returning from an overlay restores the exact list position (scroll anchor = ui-state persist, 02 §3) |
| **Session IDs** (learning session, focus session, agent run) | route/state + persisted row | `learning_sessions` / `focus_sessions` (03 §4.2) / `AgentRunState` (F-09) — a session id in the URL lets a deep link resume the session; interrupted sessions surface a resume affordance (focus spec §7) |
| **Drafts** (Tiptap notes/sheets/annotations, form state) | local persistence via the repository (back-button saves automatically, 02 §6.3) | drafts belong to the entity (draft key = entity id + screen), not to the navigation stack; closing the app never loses a draft (AD-7) |
| **Return destination** | native back + "close overlay" | overlay closes → origin page in its saved state (scroll, filters, open branch in the tree); tab switches keep per-tab state (each tab = its own routes, 02 §6.1) |
| **Context chain metadata** | `from` query param + a light breadcrumb (visible only when the chain depth > 1) | the chain Course→Chapter→Formula→Flashcards→QCM→Progress is *data* (entity ids), not UI memory — it can be re-entered from any deep link |

## 2. The required chain, concretely

1. `/learn/:courseId` → chapter list (course context in the route).
2. `…/chapters/:chapterId` → formula blocks (`MathBlock`, 05 §3.6.8; each formula
   carries its `nodeId` in the semantic tree, 01 §4.3).
3. "make flashcards" (from a formula block or the sheet) →
   `/learn/:courseId/flashcards?from=formula&nodeId=:nodeId` — the deck is scoped to
   the chain; the back button returns to the formula with its position.
4. "test me" → `/learn/:courseId/qcm?from=flashcards&nodeId=:nodeId` — QCM results
   write `FlashcardReviewed` (AD-9) and create a `learning_sessions` row
   (`:sessionId` becomes the session id).
5. "see my progress" → `/progress/:skillId?from=qcm&session=:sessionId` — the
   Progress view shows that session's evidence in context; back → the QCM result,
   then the deck, then the formula.

## 3. Failure & offline behavior

- Unknown entity id (deleted object / not synced yet) = `error` state with a retry
  (sync) action, not a blank page (02 §7).
- Offline: the whole chain works on local mirrors (AD-7); generation steps
  (flashcards from formula) degrade to queued jobs (01 §6) with the `loading` state.
- Reboot/kill mid-chain: the chain is re-derivable from the ids in the URL +
  persisted drafts (04 §6.1 "kill = re-read, not crash").
