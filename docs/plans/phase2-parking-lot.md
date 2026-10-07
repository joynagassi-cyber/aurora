# Parking lot Phase 2 — mémo de décision (P6-1…P6-4, ~1 j)

> **Règle du parking (spine AD-13, ADR §23.1/§23.3)** : Phase 1 = mobile-only.
> Chaque item ci-dessous = **décision à trancher, pas de code dans V1**. Le tranché
> se note **additif** en `_bmad-output/project-context.md` §5 (jamais modif du spine,
> jamais re-déclaration d'un type AD-15 hors `packages/domain`).
> **Critère de déclenchement** = condition observable qui justifie de rouvrir l'item.

## P6-1 — Electron adapter

- **Statut V1** : exclu (pack 04 R8) — Android (Capacitor) seulement.
- **Forme en Phase 2** (si tranché **POUR**) : adapter **ajouté**, core
  platform-agnostic — **pas de réécriture** (spine §23). Zéro impact
  `packages/domain` / `packages/data` (le port Capacitor de `packages/platform`
  reste le SSoT ; Electron = 2ᵉ adapter derrière le même port).
- **Recommandation** : **DIFFÉRER**.
- **Critère de déclenchement** : ≥ 2 personas desktop confirmés (owner + usage
  pro) + une feature bloquante sur mobile seulement (ex. multi-écran Gantt) —
  sinon le mobile + web-app suffit.
- **ADR** : additif (AD-13 : adapter = ajout, pas spine change).

## P6-2 — Yjs multi-device

- **Statut V1** : **exclu** — le CRDT OR-Set est **figé** (AD-7/F-03, SSoT
  `packages/domain/crdt`), conflits simples = server-wins + `updated_at`.
- **Forme en Phase 2** (si tranché **POUR**) : Yjs **côté sync seulement**
  (la vérité = toujours Supabase + PowerSync ; Yjs ne devient jamais SoT,
  AD-6 : l'engine n'est jamais source de vérité).
- **Recommandation** : **DIFFÉRER** — le cas d'usage multi-appareil (2 écrans
  actifs sur le même utilisateur, collaboration temps réel) n'est **pas
  démontré** pour un produit personnel ; l'OR-Set couvre le merge de listes.
- **Critère de déclenchement** : feature collaborative (partage de session /
  co-edit d'un canvas) validée par l'owner + un besoin > 2 sessions
  simultanées.
- **ADR** : additif (nouveaux types `YjsDoc*` **via** `packages/domain` d'abord,
  AD-15).

## P6-3 — STT local (speech-to-text on-device)

- **Statut V1** : exclu (ADR §23.1/§23.3) — la transcription reste une
  **capacité optionnelle** via le port `Audio/Transcription`
  (`packages/platform`), jamais locale dans V1 (le job serveur + R2 reste le
  chemin AD-8 ; dégradation = capture manuelle).
- **Forme en Phase 2** (si tranché **POUR**) : adapter Capacitor
  `@capacitor-community/voice` (ou équivalent) **ajouté à la whitelist 04 §3.1**
  = 1 PR Foundation (AD-16c) + le job reste le fallback (AD-1 : dégradation
  gracieuse si le provider est absent).
- **Recommandation** : **DIFFÉRER / NE PAS FAIRE en V1.0** — la transcription
  distante (optionnel, AD-1) couvre le besoin ; le STT local n'est pertinent
  que si : (a) offline-strict démontré sur le device cible, (b) exigence
  privacy (audio ne quitte jamais le device).
- **Critère de déclenchement** : usage offline-strict + modèle ≤ 100 Mo
  testé sur Pixel 4a (budget OQ-11 : ≤ 300 Ko JS gz — un modèle STT y est
  incompatible → à isoler dans un service worker dédié, à mesurer).
- **ADR** : additif (whitelist 04 §3.1 = 1 PR Foundation, pas spine change).

## P6-4 — Microservices (découpage du backend)

- **Statut V1** : exclu (spine AD-13 mobile-only, Supabase = SoT unique +
  Workers pour l'AI) — **pas de microservices en V1, point final**.
- **Recommandation** : **REJETER pour le Phase 2 aussi** (sauf échelle
  multi-produit). Le backend Supabase (EF + pg_cron + R2) reste
  monolithique ; le découpage n'a de sens qu'à **≥ 2 équipes backend
  concurrentes + SLA distincts par service** (critère de non-découpage).
- **Critère de déclenchement** : 2ᵉ produit partageant le kernel agent
  (ex. Aurora Pro / Aurora Team) avec des SLA distincts — **alors** 1 service
  par produit, pas par feature (YAGNI).
- **ADR** : si tranché **POUR** = breaking → **PR dédiée + review**
  (convention spine : breaking = ADR dédié, pas additif).

## Suivi du tranché (après P6)

- [ ] Chaque décision (POUR/CONTRE/DIFFÉRÉ) **notée en 1 ligne** dans
      `_bmad-output/project-context.md` §5 (`date — décision — par qui`).
- [ ] **Changelog `docs/release/changelog.md`** : section « Promotion v1.0.0 »
      + parking lot referencé (ce document).
- [ ] **Zéro code V1 impacté** par ces tranchés (spine read-only respecté).
