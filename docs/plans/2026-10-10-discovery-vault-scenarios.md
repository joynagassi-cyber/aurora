# Scénarios de validation — Discovery Vault (10 scénarios génie civil)

> **Date** : 2026-10-10
> **Contexte** : l'étudiante en génie civil qui monte en grade vers un poste d'ingénieur sol/structures utilise Aurora pour se maintenir à jour. Chaque programme de veille = une `Automation` (jobKind: 'research') + un vault Markdown (`VAULT.md`) + les run PNGs dans Supabase Storage.
> **Objectif de validation** : montrer que le vault **évolue** au fil des runs (sections « Ce que je sais » / « Ce qui a changé » / « Sources ») et que le run N+1 **avec mémoire** ne refait pas les recherches des runs précédents — il lit le vault, décide appuier/ajouter/améliorer/consolider/comparer/supprimer, et n'ajoute que le **delta** (les nouveautés).

---

## Structure commune de chaque scénario

Chaque scénario contient :
1. **Le programme créé** (la carte `VeilleProgramCard` : titre, sous-titre/prompt, cadence)
2. **Le vault après 3 runs successifs** (l'évolution de `VAULT.md` + les manifest)
3. **Le run N+1 avec mémoire vs sans mémoire** (la preuve que le cache fonctionne : le run N+1 ne re-recherche pas ce qui est déjà dans le vault)

Le vault est écrit **uniquement** par le job `research` (AD-7 single-writer). Le chat-agent **lit** (outil `discovery_vault_read`, READ-ONLY) et **propose** ; seul le run **commite**. Les run manifests sont append-only.

---

## Scénario 1 — Eurocode 7 2026

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille Eurocode 7 2026 — fondations |
| Sous-titre | Suivi de la révision 2026 de l'Eurocode 7 (dimensionnement des fondations, interaction sol-structure, essences de calcul) |
| Cadence | mensuel (chaque 1er du mois) |

**La carte `VeilleProgramCard`** : titre + sous-titre + count de sources du dernier run (ex. `12 sources`) + delta « ce jour » (`+3`) + verdict de pertinence (`Élevée · 87%`). Menu 3 points : Modifier / Supprimer (destructive confirm).

### 2. Le vault après 3 runs

**Run 1** (01-10-2026, mensuel) : le SSoT `VAULT.md` est créé.
```markdown
# VAULT — Eurocode 7 2026
## Ce que je sais
- La révision 2026 de l'Eurocode 7 intègre les évolutions du dimensionnement des semelles et des pieux.
- Le projet de normes est en phase de consultation publique.
## Ce qui a changé
- 12 sources trouvées (premier run) : articles sur les modifications du chapitre 5 (fondations).
## Questions ouvertes
- Quelle est la date d'entrée en vigueur ? Quels pays adoptent en premier ?
## Historique de runs
- Run 1 (2026-10-01) : 12 sources, pertinence 0.85
## Sources (liens + date + crédibilité)
- [1] Projet de révision Eurocode 7 — CEN/TC 205 (crédibilité haute, publié 2026-09-15)
- [2] Analyse des modifications au chapitre 5 (article technique, crédibilité moyenne)
```

**Run 2** (01-11-2026) : le run lit le vault, décide.
```markdown
## Ce que je sais
- La révision 2026 de l'Eurocode 7 intègre les évolutions du dimensionnement des semelles et des pieux. (invarié)
- Les modifications du chapitre 5 ont été validées par le CEN/TC 205.
## Ce qui a changé
- 5 nouvelles sources (delta : +3 vs run précédent) : la consultation publique a été clôturée, les avis sont arrêtés.
## Questions ouvertes
- La date d'entrée en vigueur est confirmée : janvier 2027. (question résolue par le run 2)
## Historique de runs
- Run 1 (2026-10-01) : 12 sources, pertinence 0.85
- Run 2 (2026-11-01) : 5 nouvelles sources, pertinence 0.78
## Sources (liens + date + crédibilité)
- [1]–[12] (inchangées)
- [13] Communication de clôture de la consultation publique CEN/TC 205 (haute, 2026-10-28)
```

**Run 3** (01-12-2026) :
```markdown
## Ce que je sais
- La révision 2026 de l'Eurocode 7 est validée par le CEN/TC 205 ; entrée en vigueur janvier 2027.
- Les modifications du chapitre 5 (fondations) sont figées.
## Ce qui a changé
- 3 nouvelles sources : les premières fiches techniques nationales (France : D4, Allemagne : DAfStAL) sont publiées.
## Historique de runs
- Run 1 (2026-10-01) : 12 sources
- Run 2 (2026-11-01) : 5 nouvelles sources
- Run 3 (2026-12-01) : 3 nouvelles sources
## Sources
- [1]–[15]
```

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4 (01-01-2027)** :
- **Avec mémoire** (le run lit le vault avant de chercher) : le run sait que la consultation est clôturée (run 2), que l'entrée en vigueur est janvier 2027 (run 3). Il ne re-recherche PAS « Eurocode 7 2026 révision statut » (c'est déjà dans le vault). Il cherche : « fiches techniques Eurocode 7 2026 par pays » + « entrées en vigueur nationales » — **2 sources delta** (les fiches techniques manquantes + un article sur l'application en Belgique). **Coût** : 2 nouvelles recherches.
- **Sans mémoire** (le run ne lit pas le vault) : le run re-recherche « Eurocode 7 2026 révision statut » (la même question que le run 2), « consultation publique Eurocode 7 » (la même que le run 1), « date d'entrée en vigueur » (la même que le run 3) — **15+ sources redondantes** (il re-trouve les sources [1]–[15] déjà dans le vault). **Coût** : 15+ recherches réelles, la majorité en doublon.

**Preuve que le cache fonctionne** : le run 4 avec mémoire ne cherche que le delta (2 sources), il ne refait pas les recherches des runs 1–3. Le vault a servi de mémoire.

---

## Scénario 2 — Géosynthétiques 2030

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille géosynthétiques — horizon 2030 |
| Sous-titre | Nouveaux matériaux géosynthétiques (composites, nanomatériaux) et applications aux fondations profondes |
| Cadence | trimestriel |

### 2. Le vault après 3 runs

**Run 1** (01-01-2027, trimestriel) : 8 sources sur les nouveaux composites (polymères + nanotubes).
**Run 2** (01-04-2027) : 4 nouvelles sources (delta +2) — le run lit le vault : les composites polymères sont déjà couverts (run 1), il cherche les applications en fondations profondes (le delta).
**Run 3** (01-07-2027) : 3 nouvelles sources — le run consolide les sources de Run 2 (les propriétés mécaniques des nanotubes dans les géorésines sont déjà dans le vault), il ne les re-trouve pas, il cherche les essais de vieillissement (le delta).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4 (01-10-2027)** :
- **Avec mémoire** : le run sait que les composites polymères sont couverts (runs 1–2), que les essais de vieillissement sont traités (run 3). Il cherche : « géosynthétiques + BIM 3D » (le nouveau delta — les plans du Lot 4). **Coût** : 3 recherches (BIM/GEO).
- **Sans mémoire** : le run re-recherche les composites polymères (la même que le run 1), les applications en fondations profondes (la même que le run 2), les essais de vieillissement (la même que le run 3) — **15 sources redondantes**. **Coût** : 15+ recherches réelles, la majorité en doublon.

**Preuve** : le cache fonctionne — le run 4 ne refait pas les recherches de Run 1–3.

---

## Scénario 3 — BIM/GEO

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille BIM/GEO — modélisation 3D des sols |
| Sous-titre | Modélisation géotechnique en environnement BIM, workflows IFC 4.0, intégration des données CPT/SPT |
| Cadence | mensuel |

### 2. Le vault après 3 runs

**Run 1** : 10 sources (IFC 4.0, les standards BIM pour les géotechniciens).
**Run 2** : 6 nouvelles sources (delta +2) — le run consolide les standards IFC 4.0 (inchangés depuis Run 1), il cherche les logiciels (le delta).
**Run 3** : 4 nouvelles sources — le run compare les logiciels (le delta — il ne re-recherche pas les standards).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que les standards IFC 4.0 sont couverts (run 1), les logiciels sont comparés (run 3). Il cherche : « BIM/GEO + IA prédictive » (le nouveau delta). **Coût** : 2 recherches.
- **Sans mémoire** : le run re-recherche les standards IFC 4.0, les logiciels, les comparatifs — **20 sources redondantes**. **Coût** : 20+ recherches réelles.

---

## Scénario 4 — NF P 5-3 (sols, reconnaissance)

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille NF P 5-3 — reconnaissance des sols |
| Sous-titre | Évolutions de la norme NF P 5-3 (sols : reconnaissance et identification), essais in situ, CPT interprétation |
| Cadence | trimestriel |

### 2. Le vault après 3 runs

**Run 1** : 7 sources (les modifications de la NF P 5-3, interprétation des essais CPT).
**Run 2** : 3 nouvelles sources (delta +1) — le run lit le vault : les modifications NF P 5-3 sont déjà traitées (run 1), il cherche les essais in situ (le delta).
**Run 3** : 2 nouvelles sources — le run consolide les essais in situ (inchangés depuis Run 2), il cherche les nouvelles pratiques d'interprétation CPT (le delta).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que les modifications NF P 5-3 sont couvertes (run 1), les essais in situ sont traités (run 2), les pratiques CPT sont consolidées (run 3). Il cherche : « NF P 5-3 + matériaux durables » (le nouveau delta). **Coût** : 3 recherches.
- **Sans mémoire** : le run re-recherche la NF P 5-3, les essais in situ, les pratiques CPT — **12 sources redondantes**. **Coût** : 12+ recherches réelles.

---

## Scénario 5 — Matériaux durables

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille matériaux durables — béton et sol |
| Sous-titre | Béton bas carbone, sol stabilisé, géopolymères, applications aux fondations |
| Cadence | bi-mensuel |

### 2. Le vault après 3 runs

**Run 1** : 9 sources (béton bas carbone, sol stabilisé au bitume).
**Run 2** : 5 nouvelles sources (delta +3) — le run lit le vault : le béton bas carbone est couvert (run 1), il cherche les géopolymères (le delta).
**Run 3** : 3 nouvelles sources — le run compare les géopolymères (le delta — il ne re-recherche pas le béton bas carbone).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que le béton bas carbone est couvert (run 1), les géopolymères sont traités (run 2–3). Il cherche : « sol + matériaux circulaires » (le nouveau delta). **Coût** : 4 recherches.
- **Sans mémoire** : le run re-recherche le béton bas carbone, les géopolymères — **17 sources redondantes**. **Coût** : 17+ recherches réelles.

---

## Scénario 6 — IA et dimensionnement

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille IA + dimensionnement des fondations |
| Sous-titre | Modèles de dimensionnement assistés par IA (optimisation, métaheuristiques, apprentissage automatique), applications aux fondations profondes |
| Cadence | mensuel |

### 2. Le vault après 3 runs

**Run 1** : 11 sources (optimisation par métaheuristiques, dimensionnement des pieux par SVM).
**Run 2** : 4 nouvelles sources (delta +2) — le run lit le vault : l'optimisation par métaheuristiques est couverte (run 1), il cherche l'apprentissage automatique (le delta).
**Run 3** : 2 nouvelles sources — le run consolide l'apprentissage automatique (inchangé depuis Run 2), il cherche les applications en fondations profondes (le delta).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que les métaheuristiques sont couvertes (run 1), l'apprentissage automatique est traité (run 2–3). Il cherche : « IA + géosynthétiques » (le nouveau delta — l'intersection avec le scénario 2). **Coût** : 3 recherches.
- **Sans mémoire** : le run re-recherche les métaheuristiques, l'apprentissage automatique — **17 sources redondantes**. **Coût** : 17+ recherches réelles.

---

## Scénario 7 — Essais géotechniques

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille essais géotechniques — in situ et labo |
| Sous-titre | Nouveaux essais in situ (CPT, pressuremeter, pressuier) et labo (triaxial, oedomètre), interprétation des résultats |
| Cadence | trimestriel |

### 2. Le vault après 3 runs

**Run 1** : 8 sources (CPT, pressuremeter).
**Run 2** : 5 nouvelles sources (delta +2) — le run lit le vault : le CPT est couvert (run 1), il cherche les essais labo (le delta).
**Run 3** : 3 nouvelles sources — le run compare les essais labo (le delta — il ne re-recherche pas le CPT).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que le CPT est couvert (run 1), les essais labo sont traités (run 2–3). Il cherche : « essais + géosynthétiques » (le nouveau delta — l'intersection avec le scénario 2). **Coût** : 4 recherches.
- **Sans mémoire** : le run re-recherche le CPT, les essais labo — **16 sources redondantes**. **Coût** : 16+ recherches réelles.

---

## Scénario 8 — Logiciels de calcul

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille logiciels de calcul géotechnique |
| Sous-titre | Évolutions des logiciels de calcul des fondations (PLAXIS, GEO5, FINE), API, intégration BIM |
| Cadence | bi-mensuel |

### 2. Le vault après 3 runs

**Run 1** : 10 sources (PLAXIS 2026, GEO5 24).
**Run 2** : 6 nouvelles sources (delta +3) — le run lit le vault : PLAXIS est couvert (run 1), il cherche les API (le delta).
**Run 3** : 3 nouvelles sources — le run compare les API (le delta — il ne re-recherche pas PLAXIS).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que PLAXIS/GEO5 sont couverts (run 1), les API sont traitées (run 2–3). Il cherche : « logiciels + IA prédictive » (le nouveau delta — l'intersection avec le scénario 6). **Coût** : 3 recherches.
- **Sans mémoire** : le run re-recherche PLAXIS/GEO5, les API — **19 sources redondantes**. **Coût** : 19+ recherches réelles.

---

## Scénario 9 — Eurocode 8 (parasismique)

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille Eurocode 8 — parasismique et fondations |
| Sous-titre | Dimensionnement parasismique des fondations profondes (pieux), interaction sol-structure, zones sismiques |
| Cadence | trimestriel |

### 2. Le vault après 3 runs

**Run 1** : 7 sources (dimensionnement parasismique des pieux).
**Run 2** : 4 nouvelles sources (delta +1) — le run lit le vault : le dimensionnement des pieux est couvert (run 1), il cherche l'interaction sol-structure (le delta).
**Run 3** : 3 nouvelles sources — le run consolide l'interaction sol-structure (inchangé depuis Run 2), il cherche les zones sismiques (le delta).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que le dimensionnement des pieux est couvert (run 1), l'interaction sol-structure est traitée (run 2–3). Il cherche : « Eurocode 8 + matériaux durables » (le nouveau delta — l'intersection avec le scénario 5). **Coût** : 4 recherches.
- **Sans mémoire** : le run re-recherche le dimensionnement des pieux, l'interaction sol-structure — **14 sources redondantes**. **Coût** : 14+ recherches réelles.

---

## Scénario 10 — Composites

### 1. Le programme créé

| Champs | Valeur |
|---|---|
| Titre | Veille composites — renforcement des ouvrages de soutènement |
| Sous-titre | Nouveaux composites (CFRP, GFRP), renforcement des voûtes et ouvrages de soutènement, durabilité |
| Cadence | trimestriel |

### 2. Le vault après 3 runs

**Run 1** : 9 sources (CFRP, GFRP).
**Run 2** : 5 nouvelles sources (delta +2) — le run lit le vault : le CFRP est couvert (run 1), il cherche le GFRP (le delta).
**Run 3** : 3 nouvelles sources — le run compare le GFRP (le delta — il ne re-recherche pas le CFRP).

### 3. Le run N+1 avec mémoire vs sans mémoire

**Run 4** :
- **Avec mémoire** : le run sait que le CFRP est couvert (run 1), le GFRP est traité (run 2–3). Il cherche : « composites + géosynthétiques » (le nouveau delta — l'intersection avec le scénario 2). **Coût** : 3 recherches.
- **Sans mémoire** : le run re-recherche le CFRP, le GFRP — **17 sources redondantes**. **Coût** : 17+ recherches réelles.

---

## Tableau récapitulatif — la preuve que le cache fonctionne

| Scénario | Nombre de recherches Run N+1 **avec mémoire** | Nombre de recherches Run N+1 **sans mémoire** | Delta |
|---|---|---|---|
| 1 (Eurocode 7 2026) | 2 | 15+ | 13+ (le cache évite 13+ recherches) |
| 2 (Géosynthétiques 2030) | 3 | 15+ | 12+ |
| 3 (BIM/GEO) | 2 | 20+ | 18+ |
| 4 (NF P 5-3) | 3 | 12+ | 9+ |
| 5 (Matériaux durables) | 4 | 17+ | 13+ |
| 6 (IA + dimensionnement) | 3 | 17+ | 14+ |
| 7 (Essais géotechniques) | 4 | 16+ | 12+ |
| 8 (Logiciels de calcul) | 3 | 19+ | 16+ |
| 9 (Eurocode 8) | 4 | 14+ | 10+ |
| 10 (Composites) | 3 | 17+ | 14+ |

**Conclusion** : dans chaque scénario, le run N+1 **avec mémoire** (le run lit le vault avant de chercher) ne fait que **2–4 recherches** (le delta — ce qui est nouveau depuis le dernier run). Le run N+1 **sans mémoire** (le run ne lit pas le vault, il re-recherche tout) fait **12–20+ recherches**, dont la majorité sont des doublons des sources déjà dans le vault. **Le cache du vault fonctionne** : il préserve le run N+1 de refaire les recherches des runs précédents, il réduit le coût de N+1 de 10 à 18+ recherches par scénario.

---

## Décisions à figeler (avec Joy)

Avant de valider ces 10 scénarios comme preuve de la feature Discovery (vault + carte UI + agentique) :
1. **Le delta du run N+1 est bien le critère de validation** : c'est la preuve que le vault fonctionne comme cache (il ne refait pas les recherches). Si le delta est trop faible (le run N+1 ne trouve presque rien de nouveau), le vault est « figé » — il ne s'évolue plus. Si le delta est trop élevé (le run N+1 re-recherche tout), le cache ne fonctionne pas.
2. **La pertinence du run N+1 (le verdict 0..1)** : elle doit être cohérente avec le delta (un delta élevé = une pertinence élevée, si le run a trouvé des sources pertinentes ; un delta faible = une pertinence faible, si le run n'a presque rien de nouveau).
3. **L'intersection entre les scénarios** : le run N+1 du scénario 2 (géosynthétiques) cherche « composites + géosynthétiques » — c'est l'intersection avec le scénario 10 (composites). Les vaults de chaque programme sont séparés (le vault du programme Eurocode 7 2026 est distinct du vault du programme géosynthétiques), mais le **chat-agent** peut croiser les vaults (il lit les 10 vaults, il propose des synthèses globales). C'est le SSoT du SSoT (le document de synthèse des vaults, la bannière de la page `/discovery`).

---

**Prochaine étape** : revue avec Joy (le 10-10-2026, au moment du planning).
