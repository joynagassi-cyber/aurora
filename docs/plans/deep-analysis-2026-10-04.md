# Aurora — Cartographie d'État 2026-10-04

**Session de référence** : 2026-10-04 — Tasks 1/2/3 du plan `jazzy-rolling-bubble`
(approuvé, implémenté cette session).

Ce rapport est une **cartographie comparatif** docs ↔ code au 2026-10-04,
après la livraison de la migration 0019 (`skill_catalog` + `user_skills`,
18 skills builtin seedées), l'EF `fn-skills`, le client mobile `skills-client.ts`,
la page `/skills` réécrite, les 18 templates agent (`skill-templates.ts`),
l'identité collaboration (`prompt.ts`) et l'injection multi-couches
(`fn-agent-bootstrap.ts`).

## Légende

- **FAIT** : code réel, vérifié de bout en bout, en production ou dev.
- **PARTIEL** : code existe mais non branché (blocage technique ou externe).
- **FAUX_FAIT** : UI existe mais données mock/hardcoded, zéro appel serveur.
- **NON_DEMARRE** : documenté, aucun code.
- **BLOCAGE_EXTERNE** : nécessite une action utilisateur ou service tiers
  (secrets, OAuth, provisioning) — hors de portée du repo.

## Matrice par domaine

### Productivity
| Élément | Statut | Détail |
|---|---|---|
| Tasks / Calendar / Eisenhower | FAIT | `0008` + `epics-stories.md` — vagues livrées |
| Focus (timer, pomodoro, bilan) | FAIT | `packages/focus/` (25 sons device-side, commit `ec9091f`) |
| Habits / Reviews | PARTIEL | UI + tables ; pas de coaching-loop auto |
| Time blocking (planDay, eisenhower_prioritize) | PARTIEL | 7 tools manquants corrigés **cette session** dans `loadToolContext` (39→46) ; exécution attend OQ-03 |

### Learning
| Élément | Statut | Détail |
|---|---|---|
| Cours / QCM / Flashcards | FAIT | `0008` QCM + flashcards génération ; templates `agent.qcm-design` seedés |
| Miroir cognitif (ADR S14) | FAIT | `packages/agent/src/expert-skills.ts` — 4 expert skills déterministes |
| Arbre sémantique | PARTIEL | `semantic_nodes` + `document_chunks.embedding vector(768)` (frozen) ; re-embed requis à chaque changement de provider (01 §4.10) |
| learning_import | PARTIEL | tool ID dans `loadToolContext` depuis cette session ; wiring réel OQ-03 |

### Knowledge
| Élément | Statut | Détail |
|---|---|---|
| Cours import (PDF/DOCX) | FAIT | `docs_parse`, `docs_inspect` kernel tools |
| Retrieval (RAG) | PARTIEL | `document_chunks` existantes ; index HNSW pas encore construit (neuf provider = re-embed + reindex) |

### Progress
| Élément | Statut | Détail |
|---|---|---|
| Trajectoires / Recompute | FAIT | `progress_trajectories`, `progress_analyze`, `progress_cause` kernel tools |
| Evidences | FAIT | `evidence_ref` — consommé par `expert_skills` + prompt layer 3 |

### Discovery
| Élément | Statut | Détail |
|---|---|---|
| Recherche multi-sources (Exa/Tavily/You.com) | PARTIEL | `research` tool + `researchProvider.isConfigured()` ; 3 providers, config OQ-03 |
| Gap analysis / Benin filtering | NON_DEMARRE | spécifié dans 01 S4.5, aucun code trouvé |

### Scientific Engine
| Élément | Statut | Détail |
|---|---|---|
| Solvers / RDM / BOQ / SymPy | FAIT | `scientific_evaluate`, `scientific_verify` ; commit `d51671d` kernel focus_sound_catalog |
| 5 registres (model/ai_health/ai_usage) | FAIT | policies permissives `USING (true)` justifiées par `Rationale:` (01 §4.10, AD-16b) — conforme `supabase-mcp.md` |

### Artifacts
| Élément | Statut | Détail |
|---|---|---|
| Doc generation (Pandoc/DOCX/PDF/PPTX/XLSX) | PARTIEL | `docs_generate`, `artifact_generate` ; exécution OQ-03 |
| Preview / R2 presigned URL | PARTIEL | `artifact_preview` dans `loadToolContext` depuis cette session ; wiring OQ-03 |

### Agent (Kernel)
| Élément | Statut | Détail |
|---|---|---|
| 9-stage loop | FAIT | `packages/agent/src/kernel.ts` — Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory |
| invokeModel (Agnes → Workers AI → Groq → OpenRouter) | FAIT | commit `f47d90b` — real invokeModel seam, Vercel AI SDK |
| invokeTool | PARTIEL | `fn-agent-bootstrap.ts` — `{ executed: false, note: "OQ-03 bootstrap" }` ; 46 tools addressables par le Planner |
| 46 kernel tools | FAIT | `loadToolContext.available` dérivé de `Object.keys(KERNEL_TOOLS)` (`packages/agent/src/tools.ts` — 46 entries vérifiées, identiques au tableau 46 ids). Un seul point de vérité : toute nouvelle capability seedée dans `tools.ts` + `capability.ts` est automatiquement addressable par le Planner (kernel S14). Les 7 ids manquants de la session 2026-10-04 (skill_activate, skill_create, artifact_preview, focus_sound, focus_profile, pomodoro_schedule, learning_import) étaient déjà présents dans `KERNEL_TOOLS` — le tableau durci dupliait juste un sous-ensemble, et le fait que le sous-ensemble ait été erroné (39/46) prouve le défaut de design. Correction : dérivé, plus jamais saisi à la main. |
| Capability Registry | PARTIEL | `capabilityRegistry?.available(userId)` — dégrade à `permission.capabilityIds` si absent |
| **18 skill templates builtin** | **FAIT (nouveau)** | `packages/agent/src/skill-templates.ts` — 18 entries, `source: 'builtin'`, 6 domaines, `BUILTIN_TOOL_IDS` derivé |
| **skill_catalog + user_skills (0019)** | **FAIT (nouveau)** | 18 rows seedées ; RLS `user_skills` isolé (2 policies + trigger + index) ; `skill_catalog` public-read + service-write |
| **fn-skills (6 verbes)** | **FAIT (code) / PARTIEL (live)** | Déployée v5 (ACTIVE) cette session. `list_catalog` est public (AD-3, pas de user JWT requis). Les 5 verbes user + la lecture du catalogue par l'EF s'activent dès que le secret projet `SUPABASE_SECRET_KEY` est défini (Dashboard > Edge Functions > Secrets, sans redeploy) — sans ce secret l'EF renvoie l'état dégradé honnête `{catalog:[], degraded:true}` (AD-1, ne simule jamais un catalogue). QA 27/27 attestée via le fallback service key dans l'intervalle (scripts/skills-qa.ts). |
| **skills-client.ts + page /skills réécrite** | **FAIT (nouveau)** | 3 tabs (Catalogue / Mes skills / Expert) ; zéro mock ; état dégradé honnête quand `skills` client absent |
| **AGENT_SYSTEM_PROMPT collaboration** | **FAIT (nouveau)** | `prompt.ts` réécrit : identité "agent de collaboration", 4 sections (IDENTITÉ / PRÉCISION / TON / DOMAINES), 4 placeholders runtime |
| **Prompt layering (layer 1 skills + layer 2 expert)** | **FAIT (nouveau)** | `invokeModelReal` assemble `AGENT_SYSTEM_PROMPT` + skillsLayer + expertLayer + researchContext + mirrorPrelude |

### Goal
| Élément | Statut | Détail |
|---|---|---|
| GoalProject / SubGoal / Dashboard | FAIT | `goal_create`, `goal_feature_add`, `goal_pause`, `goal_complete` |
| 7 goal capabilities | FAIT | CapabilityRegistry + `permission.capabilityIds` |

### Self-Improvement
| Élément | Statut | Détail |
|---|---|---|
| expert_skills (0008) + 4 extensions | FAIT | `expert-skills.ts` — paires contrastives, décadence, triage, firewall |
| skill_hypotheses / contrastive_pairs / skill_validation_log | FAIT | migration 0020 appliquée live cette session : 3 tables Aurora (skill_hypotheses, contrastive_pairs, skill_validation_log), RLS user-isolation + service_role SELECT-only (pas de `USING (true)` permissive), triggers `set_updated_at`, 3 indexes. Spec §4 : les colonnes enrichies d'expert_skills (provenance/obsolescence/decay_lambda) ne sont PAS appliquées ici (suivi P2 suivant) |
| user_skills (0019) + skill_catalog (0019) | FAIT | cette session |

### Integrations
| Élément | Statut | Détail |
|---|---|---|
| Composio v3.1 sessions | FAIT | commit `9691c98` + `4d5e7cd` ; page `/integrations` branchée sur le client réel |
| Spotify custom OAuth app | BLOCAGE_EXTERNE | nécessite Spotify Developer Dashboard + Composio AuthConfig (action utilisateur) |
| 14 toolkits Composio | FAIT | `fn-integrations` sessions par utilisateur |
| focus-sounds (25 sons) | FAIT | commit `ec9091f` — CC/public-domain, device-side |

### UI Shell
| Élément | Statut | Détail |
|---|---|---|
| 17 pages (premium) | FAIT | Ionic React + Capacitor + Framer + AG Grid + FullCalendar |
| `/skills` (nouveau) | FAIT | 3 tabs server-backed, zéro mock |
| `/agent` plus-sheet → `/skills` | FAIT | navigation router ajoutée cette session |
| `epics-stories.md` "all seven waves delivered" | FAUX_FAIT | changelog ne documente que vagues 0/1/2/3/5/7 (4 et 6 absentes) — à corriger |
| `build:web` vite/iife conflict | NON_DEMARRE | à fixer |

### Docs
| Élément | Statut | Détail |
|---|---|---|
| `docs/plans/` (n'existe pas → créé) | FAIT | ce rapport est le premier contenu |
| Deep-analysis 2026-10-04 | FAIT | ce fichier |
| TickTick structure (P0-P4) | NON_DEMARRE | MCP TickTick indisponible — voir "Structure TickTick (import-ready)" ci-dessous |

## Liste d'actions ordonnées

### P0 — bloque tout
1. **Wire `invokeTool` réel** — `fn-agent-bootstrap.ts` — M — nécessite OQ-03 (GitHub Secrets + EF secrets). L'agent ne peut exécuter aucun tool tant que ce stub n'est pas remplacé.
2. ~~Fix `loadToolContext` (7 tools manquants)~~ — **FAIT cette session** : le tableau durci de 39 ids a été remplacé par `Object.keys(KERNEL_TOOLS)` (46 ids, vérifiés identiques au set attendu). Tout ajout futur de capability est automatiquement addressable — plus de sous-ensemble erroné possible.

### P1 — faux-fait visible
3. ~~Remplacer mock de `/skills` par `fn-skills` EF + `skill_catalog` + `user_skills`~~ — **FAIT cette session** : migration 0019 appliquée live, EF 6 verbs, client mobile AD-3, page 3 tabs server-backed.
4. ~~Seed 18 skills builtin dans `skill_catalog`~~ — **FAIT cette session** : 18 rows (5+7+5 par batches CTE-VALUES) ; `SELECT count(*) FROM skill_catalog` = 18 vérifié.

### P2 — améliore l'agent
5. ~~Réécrire `AGENT_SYSTEM_PROMPT` (identité collaboration)~~ — **FAIT cette session** : 4 sections + 4 placeholders, `packages/agent/src/prompt.ts`.
6. ~~Injection layer 1 (user_skills) + layer 2 (expert_skills) dans le prompt~~ — **FAIT cette session** : `invokeModelReal` assemble les 2 couches avant researchContext/mirrorPrelude.
7. ~~Créer `skill_hypotheses` + `contrastive_pairs` + `skill_validation_log`~~ — **FAIT cette session** : migration 0020 (`0020_expert_skills_extensions.sql`) appliquée live. Les colonnes enrichies d'`expert_skills` (provenance/obsolescence/decay_lambda, spec §4) restent en P2 suivant — elles nécessitent de toucher le contract existant (procedure text → jsonb), volontairement non inclus pour ne pas casser le reader bootstrap.

### P3 — blocages externes
8. **Spotify custom OAuth app** — Spotify Developer Dashboard + Composio AuthConfig — externe (action utilisateur).
9. **OQ-03 GitHub Secrets staging/prod** — CI/CD — externe (action utilisateur).
10. **Secret EF `SUPABASE_SECRET_KEY` (live project)** — le projet Supabase (opagfyspdbhxthlxvlrk) n'a PAS encore de secret `SUPABASE_SECRET_KEY` défini pour les Edge Functions. TANT QUE ce secret n'est pas défini :
    - `fn-agent-run`, `fn-integrations`, `fn-job-dispatcher` (déjà déployés, wave 0) = 503 `secrets_missing`
    - `fn-skills` (déployée v5 cette session) = état dégradé HONNÊTE : `list_catalog` renvoie `{ok:true, data:{catalog:[], degraded:true, note:"SUPABASE env not configured on the EF — set the project's SUPABASE_SECRET_KEY secret (Dashboard > Edge Functions > Secrets, or `supabase secrets set SUPABASE_SECRET_KEY=...`)"; no redeploy needed, it takes effect immediately"}}` (AD-1 : on ne simule jamais un catalogue)
    - RÈGLE (supabase-mcp.md) : la valeur du secret ne passe JAMAIS par le MCP (`execute_sql` ne peut pas le définir ; pas d'endpoint API exposé pour ce projet) — c'est une action utilisateur dans le Dashboard : **https://supabase.com/dashboard/project/opagfyspdbhxthlxvlrk → Edge Functions → Secrets → `SUPABASE_SECRET_KEY` = (la clé `sb_secret_` du projet, visible dans `.env.local`)**. Pas de redeploy requis (supabase secrets = immédiat).
    - Preuve de non-blocage du reste : la QA `scripts/skills-qa.ts` (27 checks) atteste la chaîne complète (seed, RLS, verbes, prompt layer) via le service key en fallback service-key, 27/27 OK SANS le secret EF.

### P4 — non démarré
11. **`build:web` vite/iife conflict** — à fixer.
12. **`epics-stories.md` header "all seven waves"** — corriger le changelog (vagues 4/6 absentes).

## QA Skills (self-test, cette session)

- `scripts/skills-qa.ts` — 27 checks, **27 OK / 0 FAIL** (exécution 2026-10-04) :
  - seed intégrité (18 skills, 6 domaines, 18 skill_keys = 18 templates SSoT)
  - lecture publique AD-3 (publishable key lit skill_catalog — nouvelle policy `skill_catalog_public_read` à `anon, authenticated` appliquée live, fichier 0019 synchronisé)
  - RLS live (user_skills anonyme = vide)
  - 6 verbes fn-skills EF (public list_catalog + 5 verbes user, test utilisateur réel `skills-qa@aurora.test` créé/supprimé via l'API admin)
  - PRÉCISION : le payload user_skills est IDENTIQUE au skill_catalog après activation (AD-7, copie serveur)
  - layer-1 du prompt reconstruit à l'identique de fn-agent-bootstrap
  - contenu des 18 AGENT_SKILL_TEMPLATES (tools ⊂ KERNEL_TOOLS, procedure ≥ 3, constraints ≥ 1)
  - utilisateur test nettoyé en fin de run (sauf `--keep`)

- `supabase/functions/fn-skills/index.ts` — **3 correctifs majeurs cette session** (le code initial ne passait PAS le bundler de Supabase et contenait un bug de design) :
  1. **`fn-skills` n'était pas déployée** (404 sur le live). Déployée v1→v5 via le MCP `deploy_edge_function` (import_map.json vides, `verify_jwt=false`).
  2. **Le code TS strict ne compilait PAS par le bundler Deno de Supabase** : `import type` + generic + template-literals dans les appels rest() → parse errors. Réécrit en syntaxe 100 % Deno-safe (if/else, concaténation string, pas d'import type) — le repo `.ts` source reste le SSoT mais le contenu déployé est déduit manuellement. (Note de dette : le repo et le live peuvent diverger si on édite le repo sans re-déployer ; le `deploy_edge_function` ne lit PAS le repo, il reçoit le contenu inline.)
  3. **Bug de design du verbe public** : la version initiale exigeait un Bearer user pour TOUS les verbes y compris `list_catalog`, ce qui contredisait le principe AD-3 (le mobile doit pouvoir parcourir le catalogue avec sa clé publishable seule, sans utilisateur connecté). `list_catalog` est maintenant public (pas de user JWT requis), les 5 autres verbes exigent bien le user JWT (AD-7).

- `skill_catalog_public_read` (0019) : étendue de `FOR SELECT TO authenticated` à `FOR SELECT TO anon, authenticated` (appliqué live, vérifié en pg_policy : roles = `anon,authenticated`). Justification AD-3 : le catalogue est une information publique de curation (pas de donnée utilisateur sensible), le mobile doit pouvoir l'ouvrir sans session. `user_skills` reste strictement RLS-isolée par `auth.uid()`.

## Structure TickTick (import-ready)

> **Statut** : MCP TickTick (`mcp__ticktick__*`) **indisponible** cette
> session (pas dans la liste des MCP connectés). Conformément à
> `C:/Users/joyda/CLAUDE.md` (règle "MCP TickTick indisponible ou en
> erreur : STOP et signaler, ne pas continuer") et
> `.claude/rules/ticktick-planning.md`, **aucune simulation en fichier
> n'a été faite** — cette structure est prête à être importée dès que le
> MCP est de nouveau disponible. **Aucun projet ou tâche TickTick n'a
> été créé cette session.**

**Projet à créer** : `Aurora — Stabilisation & Skills (v0.1.1)`

### Tâches par niveau de priorité

```
P0 — Invalables (tag: agent)
├── Wire invokeTool réel (fn-agent-bootstrap.ts, remplace stub OQ-03)
│   priorité: High, étiquettes: [agent, p0, blocked:OQ-03]
│
P1 — Faux-fait visible (tag: skills / mobile)
├── Migration 0019_user_skills.sql (skill_catalog + user_skills)  [FAIT 2026-10-04]
├── Seed 18 skills builtin dans skill_catalog                     [FAIT 2026-10-04]
├── EF fn-skills (6 verbes)                                         [FAIT 2026-10-04]
├── skills-client.ts (AD-3 publishable scope)                       [FAIT 2026-10-04]
├── Remplacer mock /skills page par fn-skills                       [FAIT 2026-10-04]
├── Ajouter skills? à query-client.ts + main.tsx                    [FAIT 2026-10-04]
│
P2 — Améliore l'agent (tag: agent / domain / skills)
├── Réécrire AGENT_SYSTEM_PROMPT (identité collaboration)           [FAIT 2026-10-04]
├── Ajouter type AgentSkillTemplate + UserSkill dans domain        [FAIT 2026-10-04]
├── Injection layer 1 (user_skills) dans invokeModelReal           [FAIT 2026-10-04]
├── Injection layer 2 (expert_skills) dans invokeModelReal         [FAIT 2026-10-04]
├── Fix loadToolContext 7 tools manquants (39→46)                  [FAIT 2026-10-04]
├── Créer skill_hypotheses + contrastive_pairs + skill_validation_log (migration 0020) [FAIT 2026-10-04]
│
P3 — Blocages externes (tag: externe / ci-cd)
├── Spotify custom OAuth app (Spotify Developer Dashboard + Composio AuthConfig)
│   priorité: High, étiquettes: [externe, p3, action-user]
├── OQ-03 GitHub Secrets staging/prod (CI/CD)
│   priorité: High, étiquettes: [ci-cd, p3, blocked:github-secrets]
│
P4 — Non démarré (tag: docs / build)
├── Fix build:web vite/iife conflict
│   priorité: Medium, étiquettes: [build, p4]
├── Corriger epics-stories.md header "all seven waves delivered" (vagues 4/6 absentes)
│   priorité: Low, étiquettes: [docs, p4]
```

## Vérification exécutée (cette session)

- Post-apply migration 0019 : `skill_catalog` = 2 policies, `user_skills` = 2 policies + 1
  trigger (`user_skills_updated`) + index `idx_user_skills_user_active` + pkey + unique
  `user_id,skill_key` ; `SELECT count(*) FROM skill_catalog` = **18** ✓
- `sh scripts/check-rls.sh` → **OK** (policy `user_skills_service_role` : commentaire
  `Rationale:` ajouté)
- `sh scripts/check-boundaries.sh all` → **OK** (fix du faux-positif G2 : le pattern
  `sk-[A-Za-z0-9]{8,}` matchait le mot `description` — ancré à une boundary
  `(^|[^A-Za-z0-9_])`)
- `node --experimental-strip-types scripts/check-view-joins.ts` → **OK** (20 .sql scannés,
  0 JOIN inter-module)
- `pnpm tsc --noEmit` → **OK**
- `graphify update .` → **OK** (401 files, 1308 nodes, 1804 edges, 189 communities)

## Suivi à venir

- **OQ-03** (GitHub Secrets staging/prod) — bloque `invokeTool` réel +
  `learning_import` + `artifact_preview` wiring.
- **Colonnes enrichies d'`expert_skills`** (spec §4 : provenance,
  obsolescence, decay_lambda, procedure→jsonb) — follow-up P2 ; non inclus
  dans 0020 (ne pas casser le reader bootstrap existant).
- **Re-embed + reindex HNSW** — à chaque changement de provider embedding
  (01 §4.10), dimension frozen = 768.
- **Spotify OAuth app** — action utilisateur externe (P3).
- **TickTick** — dès que le MCP est de nouveau disponible : créer le projet
  `Aurora — Stabilisation & Skills (v0.1.1)` + la structure P0–P4 ci-dessus,
  cocher les tâches [FAIT 2026-10-04].
