# Discovery Engine + Semantic Tree — Gap Analysis & Consolidation (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 2-4). Authority: ADR S13
(Discovery Engine), ADR S14 (Semantic Tree), AD-6 (Knowledge owns
NodeState, Progress emits-only), AD-9 (DiscoveryItemCreated), 01 S4.5
(Discovery), 01 S4.3 (Knowledge), 03 S4.2 (Gap rows owned by Progress).

## 1. The Gap Analysis Pipeline (structured, NOT text comparison)

```
+-------------------------------+
|   Corpus Universitaire        |
|   (Cours BA / RDM / Hydraul.) |
+---------------+---------------+
                |
                v
+-------------------------------+      Identification
|   Arbre Semantique            +--------------------+
|   (Savoir reel de Horeb)     |  de l'ecart        |
+---------------+---------------+  technique         |
                |                                     |
                v                                     v
+-------------------------------+          +-------------------------+
|   Discovery Multi-Source      |          |  Matrice d'Ecarts      |
|   (Normes / Pratiques /      +--------->|  (Gap objects)          |
|    Evolutions)               |          +-------------------------+
+-------------------------------+                   |
                                                    v
                                         +-------------------------+
                                         |  Plan d'ouverture       |
                                         |  (Learning + Practice)  |
                                         +-------------------------+
```

### 1.1 Ingestion Multi-Source (background, AD-8 jobs)

The Discovery Engine queries ResearchProvider (Exa, Tavily, You.com)
on reference deposits:
- Bureaux d'etudes (engineering firms: method docs, reports)
- Rapports de chantiers (site reports, case studies)
- Evolutions normatives (new Eurocode revisions, BAEL updates,
  local Benin construction standards)
- International excellence (FEMA, ASCE, institutional best practices)
- Local practices (BEN context: materials available, climate,
  construction methods specific to West Africa)

**Not a passive feed.** The Discovery Engine runs on a schedule
(Automation, Cron -> jobs, AD-8) AND on-demand (agent trigger:
"what's new in my domain?"). Results are typed:
FACT / TREND / ANALYSIS / SCENARIO / UNCERTAINTY (ADR S13.7).

### 1.2 Semantic Confrontation (the core mechanism)

The system compares Discovery results against Horeb's current
position in the Semantic Tree:

```
Tree position: "Je maitrise: flexion simple BA (BAEL)"
Discovery:     "Eurocode 2 6.2 (2004) est la norme actuelle;
                BAEL est en cours de retirement en France;
                les bureaux d'etudes utilisent EF (ANSYS, Abaqus)
                pour valider les calculs manuels"
  |
  -> GAP DETECTED:
     "Modele par elements finis" (FEM)
     NOT in the tree (no node)
     BUT required by: professional practice (bureaux d'etudes)
     AND by: normative convergence (Eurocode)
  |
  -> Gap object created:
     { concept: "FEM validation",
       urgency: 'medium' (not exam-critical yet, but career-critical),
       source: [Eurocode 2, 3 bureau reports],
       treePosition: "racine: structures -> branche: methodes numeriques"
       (new branch to create),
       evidence: [DiscoveryItem refs] }
```

**The Gap is NOT an alert. It is a durable object** (ADR S13.8):
it has its own row (Progress-owned, 03 S4.2), its own SourceRefs,
its own urgency score, and its own link to the Learning module
(what to study to close it).

### 1.3 The Gap Object (durable, Progress-owned)

```ts
interface Gap {
  id: string;
  userId: string;
  concept: string;            // "FEM validation"
  discipline: string;        // "structures"
  urgency: 'critical' | 'high' | 'medium' | 'low';
  source: 'exam' | 'career' | 'normative' | 'discovery' | 'progress';
  evidence: SourceRef[];     // what backs this gap
  treePosition: {            // where in the Semantic Tree
    branch: string;          // "methodes_numeriques"
    prerequisite: string;    // "RDM.flexion_simple"
    status: 'missing' | 'weak' | 'known_not_practiced';
  };
  remediation?: {            // what closes this gap
    learningItems: string[]; // QCM, flashcards, exercises
    focusTime: number;       // estimated minutes
    deadline?: string;       // exam date / career deadline
  };
  status: 'open' | 'in_progress' | 'closed' | 'deferred';
  createdAt: string;
  closedAt?: string;
}
```

## 2. Semantic Tree Consolidation (3 strict concepts)

### 2A. Mathematical Invariance Principle

**Rule: the same formula = the same node. NEVER create a duplicate.**

When a new resource is ingested (course, Discovery result, user note):

```
New resource: "M = sigma * W = F * L / 4 (simply supported, midspan)"
  |
  -> LaTeX signature extraction: "M = F L / 4"
  -> Compare to existing nodes:
     Node: "rdm.beam.max_moment_point_load"
     Formula: "M_max = P L / 4"
  |
  -> SIGNATURE MATCH (algebraically equivalent, variable rename P->F)
  |
  -> DO NOT create a new node
  -> ENRICH existing node: add SourceRef (new document, page, author)
  -> Node.sourceRefs += [newRef]
  -> Node.confidence: up (more sources = more reliable)
```

**The signature is the algebraic form, not the string.**
`M = PL/4` and `M = F*L/4` are the same formula (variable rename).
The system uses a normalized LaTeX form (sorted variables,
standard operators) for comparison. This is a deterministic
string-match on the normalized form, NOT an LLM judgment.

### 2B. Phased Layering (readability rule, ADR S14)

**The tree is a HIERARCHY, not a web.**

```
Vertical (primary, always visible):
  Root: "Structures"
    Branch: "RDM"
      Node: "Flexion simple"
        Node: "Poutre simplement appuie"
          Node: "Charge ponctuelle"
            Node: "M_max = PL/4"
    Branch: "Beton Arme"
      Node: "Dimensionnement flexion"
        Node: "Couple interne (BAEL)"
        Node: "Couple interne (Eurocode 2)"
    Branch: "Methodes Numeriques" (NEW, from Gap)
      Node: "EF (elements finis)"

Horizontal (secondary = SemanticBridge, NOT shown by default):
  Bridge: "RDM.flexion_simple" <-> "MethodesNumeriques.EF"
  Label: "EF valide le calcul manuel de flexion"
  Visibility: ONLY when the user explicitly activates
    "cross-domain view" (UI toggle, not default)
```

**Rule: the default view is a tree. Cross-domain connections
are bridges that the user reveals on demand.** This is the
ADR S14 readability rule: "ne pas transformer l'arbre en carte
mentale gigantesque."

### 2C. Progression Backlink (EvidenceRef, AD-6)

```
Tree Node: "rdm.beam.max_moment_point_load"
  |
  | node_state (Knowledge-owned, AD-6):
  |   status: 'mastered' | 'fragile' | 'unknown' | 'not_started'
  |   confidence: 0.0-1.0
  |   last_evidence: ProgressEvidence id
  |
  v
ProgressEvidence (Progress-owned, sole producer F-07):
  "Horeb solved 5/5 QCM on this topic, 2 weeks ago"
  |
  -> Node state: 'mastered' (confidence 0.9)
  -> Aurora Coach: "Next concept to explore: 'Flexion avec
     enfoncement' (the prerequisite for the next branch)"
  -> Discovery: "Check if 'FEM validation of flexion' is
     relevant now that basic flexion is mastered"
```

**The tree node state is NOT stored in the tree table.**
It is in `NodeState` (Knowledge-owned, AD-6) which is UPDATED
by Progress via the `ProgressEvidenceCreated` event (AD-9).
The tree renderer reads `NodeState` for coloring (green = mastered,
yellow = fragile, gray = unknown, red = not started).

## 3. The Systemic Synergy Loop (5 steps, autonomous)

```
Step 1: DISCOVERY detects a gap
  "FEM validation is missing from the tree; required by career"
  -> Gap object created (Progress-owned)
  -> DiscoveryItemCreated event (AD-9)

Step 2: KNOWLEDGE inserts the gap into the tree
  New branch: "Methodes Numeriques" (if not exists)
  New node: "EF (elements finis)" (status: 'not_started')
  Bridge: "RDM.flexion" <-> "MethodesNumeriques.EF"
  -> semantic_tree_version++ (Knowledge-owned, AD-6)

Step 3: LEARNING proposes targeted visual explanation
  "Here is a 5-min AntV infographic: what is FEM, how it
   validates your manual flexion calc, when to use it"
  -> Artifact (infographic, AntV + KaTeX)
  -> Learning item created (explanatory, NOT a QCM yet)

Step 4: PRACTICE generates a concrete problem
  "Validate your manual M_max = PL/4 with a simple FEM model
   (3 elements, 2 DOF). Compare results."
  -> Scientific Engine: deterministic solver (3-element beam)
  -> Verification: |M_fem - M_manual| / M_manual < 5%?
  -> Result: "Agreement at 2.3%. FEM confirms your manual calc."

Step 5: PROGRESS captures the evidence
  "Horeb validated flexion by FEM (method: 3-element beam,
   agreement 2.3%)"
  -> ProgressEvidenceCreated (F-07, Progress sole producer)
  -> NodeState: "EF" goes from 'not_started' to 'mastered'
  -> Self-Improvement: "FEM validation is now a reliable
     practice pattern for this user (Expert Skill confidence up)"
  -> Discovery: next gap in the "Methodes Numeriques" branch
    (e.g., "non-linear FEM for reinforced concrete")
```

**The loop is AUTONOMOUS.** No user interaction needed between
steps 1-5 (the Agent runs them as background jobs, AD-8).
The user sees the RESULT: a new branch in the tree, a visual
explanation, a practice problem, and updated progress. The
intermediate steps are invisible.

## 4. SQLite Relational Model (Semantic Tree, local mirror)

The tree is stored in Postgres (server) and mirrored locally
(SQLite via PowerSync, 03 S4.2). The local mirror enables
instant offline queries.

```sql
-- semantic_nodes (Knowledge-owned, AD-6)
CREATE TABLE semantic_nodes (
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL,
  label       TEXT NOT NULL,
  parent_id   UUID REFERENCES semantic_nodes(id),  -- vertical (tree)
  branch_path TEXT NOT NULL,  -- materialized path: "structures/rdm/flexion/simple"
  level       INT NOT NULL,   -- depth (0=root, 1=branch, 2=node, 3=sub-node)
  node_type   TEXT NOT NULL,  -- 'root' | 'branch' | 'concept' | 'formula' | 'method'
  formula_latex TEXT,         -- for formula nodes (invariant signature)
  status      TEXT NOT NULL DEFAULT 'not_started'
    CHECK (status IN ('not_started','fragile','mastered','unknown')),
  confidence  REAL DEFAULT 0.0,
  version     TEXT NOT NULL,  -- semantic_tree_version (AD-6)
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);
-- INDEX for instant local queries:
CREATE INDEX idx_nodes_user_path ON semantic_nodes(user_id, branch_path);
CREATE INDEX idx_nodes_user_parent ON semantic_nodes(user_id, parent_id);
CREATE INDEX idx_nodes_user_type ON semantic_nodes(user_id, node_type);

-- semantic_bridges (secondary, cross-domain, NOT in default view)
CREATE TABLE semantic_bridges (
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL,
  from_node   UUID NOT NULL REFERENCES semantic_nodes(id),
  to_node     UUID NOT NULL REFERENCES semantic_nodes(id),
  label       TEXT NOT NULL,       -- "EF valide le calcul manuel"
  bridge_type TEXT NOT NULL,      -- 'application' | 'prerequisite' | 'extension'
  visibility  TEXT NOT NULL DEFAULT 'hidden'
    CHECK (visibility IN ('hidden','explicit','always')),
  -- 'hidden' = only in cross-domain view (ADR S14 readability)
  -- 'explicit' = user activated it
  -- 'always'   = critical bridge (e.g., prerequisite chain)
  created_at  TIMESTAMPTZ
);

-- source_refs (provenance, AD-11)
CREATE TABLE source_refs (
  id          UUID PRIMARY KEY,
  user_id     UUID NOT NULL,
  node_id     UUID NOT NULL REFERENCES semantic_nodes(id),
  source_type TEXT NOT NULL,  -- 'course' | 'norm' | 'discovery' | 'user_note' | 'reference'
  source_ref  TEXT NOT NULL,  -- R2 key, URL, or document id
  page        TEXT,
  confidence  REAL DEFAULT 1.0,
  created_at  TIMESTAMPTZ
);
-- A node can have MULTIPLE source_refs (invariance: enrich, don't duplicate)
```

**Local query performance (offline, SQLite):**
- "Show me the tree for 'Structures'" = `WHERE user_id=? AND branch_path LIKE 'structures/%'`
  -> uses `idx_nodes_user_path` -> instant (materialized path, no recursive CTE)
- "Show bridges from this node" = `WHERE from_node=? OR to_node=?`
  -> uses node index
- "Which formulas are fragile?" = `WHERE node_type='formula' AND status='fragile'`
  -> uses `idx_nodes_user_type`
- **No cross-module joins** (AD-2): NodeState is in a separate table
  (Knowledge-owned); Progress reads it via public view + events

## 5. Discovery Filtering Policy (Benin context)

**The agent does NOT evaluate "is this relevant to Horeb?" by LLM
guess.** It uses a structured policy:

```
Discovery result: "New FEM software XYZ, $5000/year license"
  |
  -> Relevance filter (structured, data-driven):
     1. DOMAIN MATCH: is it in Horeb's active disciplines?
        (UserContext.disciplines = ['structures', 'concrete', 'hydraulics'])
        YES -> proceed. NO -> discard.
     2. INFRASTRUCTURE REALITY (Benin context, UserContext.region):
        - Internet connectivity: can the tool run locally?
        - Hardware: is the required PC available?
        - Cost: is $5000/year accessible? (UserContext.budget)
        - Local norms: does the tool support BAEL / Eurocode /
          Benin local standards?
     3. CAREER RELEVANCE (UserContext.goal):
        - Does it close a known Gap?
        - Is it required by the target profession (bureau d'etudes)?
        - Is it a "nice to have" or "must have"?
  |
  -> Result:
     If relevant: DiscoveryItem (FACT/TREND) + Gap update
     If not: "Noted but not actionable in current context"
       (stored, NOT deleted; may become relevant later)
     If uncertain: status = 'UNCERTAINTY' (ADR S13.7)
       "The agent cannot determine relevance without more info"
```

**The filtering is DATA-DRIVEN, not LLM-judgment.** The agent
reads UserContext (disciplines, region, budget, goals) and applies
deterministic rules. The LLM only handles the NOVEL case
("This discovery doesn't match any existing filter category")
where it flags `UNCERTAINTY` and asks the user.

**Benin-specific parameters (in UserContext, NOT hardcoded):**
- `region: 'benin'` -> infrastructure: limited fiber,
  mobile data common, power reliability varies
- `disciplines: ['genie_civil', 'structures', 'hydraulics']`
- `professional_target: 'bureau_etudes'` -> norms: Eurocode +
  local practices + BAEL (transition period)
- `budget_constraint: 'student'` -> tools: free/open-source
  preferred (EPANET free, OpenSees free, ANSYS student free)
- `examination_period: true/false` -> discovery cadence:
  reduced during exams (ADR S13: user-controlled cadence)

**Rule: no `if user === Horeb` in code.** All of the above is
UserContext data. The filtering engine is generic.

## 6. What this does NOT change

- AD-6: Knowledge owns `semantic_nodes` + `NodeState`; Progress
  owns `Gap` rows + `ProgressEvidenceCreated` (sole producer, F-07)
- AD-9: `DiscoveryItemCreated` event (existing, 9-event vocabulary)
- AD-8: Discovery = heavy job (Cron + on-demand), persisted
- AD-12: Agent is server-side; the Discovery Engine runs on the
  server (fn-discovery job), not on the device
- ADR S14: tree = hierarchy, not web. Bridges = secondary.
  Readability rule enforced (Phased Layering, 2B)
- ADR S13.7: FACT/TREND/ANALYSIS/SCENARIO/UNCERTAINTY separation
  maintained on every DiscoveryItem

## 7. Tests (wave 2+)

- Gap detection: Discovery result + tree position -> Gap created
  (not duplicated if same concept already has a Gap)
- Invariance: 2 documents with the same formula (variable rename)
  -> 1 node, 2 SourceRefs (NOT 2 nodes)
- Phased layering: bridge default = 'hidden'; cross-domain view
  shows it; vertical tree does not
- Progress backlink: QCM success -> NodeState mastered ->
  tree renders green; Coach suggests next concept
- Benin filtering: "FEM software $5000/year" + UserContext
  (student, Benin) -> status = 'not_actionable_currently'
  (stored, not discarded); "OpenSees (free, open-source)" ->
  'actionable'
- Offline: tree query on materialized path (no recursive CTE,
  instant on SQLite)
- Discovery cadence: exam period = reduced cadence (UserContext)
