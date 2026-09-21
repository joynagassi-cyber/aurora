# Scientific Engine — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (waves 2–3). Authority: ADR §15/§17, spine AD-10
family (engines behind contracts), `01-backend` §3.2 (`ScientificEngine` port),
`packages/scientific-engine` (SPEC wave-0 list).

1. **Purpose** — a **generic, swappable** math/units layer usable by the agent,
   exercises, sheets, documents and technical projects (ADR §15). LaTeX is the
   *representation* format; the engine is the computation layer.
2. **Responsibilities** — deterministic numeric computation with units &
   conversions; symbolic ops (simplification, factorization, differentiation,
   integration, solving where the equation allows); linear algebra (vectors,
   matrices, systems); equation/system solving with substitution + result checking;
   common scientific & statistical functions; **automatic verification** (units,
   dimensions, basic bounds, step coherence, final result); **calculation
   traceability** (initial expression, steps, assumptions, units, result, ADR §15);
   swappable specialized engines behind `ScientificEngine` without coupling the domain
   to any specific library (ADR §15 last paragraph: civil-engineering specialties are
   NOT a collection of per-subject calculators — the agent mobilizes the generic
   engine + corpus knowledge).
3. **Non-responsibilities** — LLM numeric answers are **never trusted blindly**:
   critical science results flow `Knowledge/source → method → ScientificEngine →
   result → verification → LLM explanation` (mission §5, ADR v1.7 §14 CRITIQUE level);
   knowledge content (Knowledge module); unit *knowledge* (corpus; the engine
   computes).
4. **User flows** — formula editing in notes/sheets (LaTeX + `MathRenderer`);
   exercise solving (engine + verification); sheet formula blocks (variable meanings,
   units, conditions, particular cases, useful transformations, application example —
   ADR §17); agent-verified scientific claims.
5. **Architecture** — `packages/scientific-engine` implements the `ScientificEngine`
   port; heavy computations = persisted jobs (AD-8, kind `scientific`); engine
   backends swappable (implementation detail of the Scientific team — engine choice
   is NOT a frozen architecture decision, see coverage-matrix row).
6. **Domain model** — LaTeX expressions (representation), unit/value value objects,
   calculation trace (expression, steps, assumptions, units, result, verification
   status).
7. **Application services** — evaluate/convert/verify use-cases consumed by Learning,
   Knowledge (formula nodes) and the Agent (critical verification, 01 §5.6).
8. **Ports / interfaces** — `ScientificEngine` (01 §3.2 "other contracts" list, ADR
   §8), `MathRenderer` (AD-10: KaTeX behind the contract, 02 §5.4/05 §3.6.8).
9. **Adapters** — engine backends (swappable), KaTeX renderer in `packages/ui`,
   scientific job workers.
10. **Data model** — formula content lives in Knowledge/Learning content; engine is
    stateless (no table of its own in V1 design).
11. **API** — server jobs for heavy compute; in-app calls for light deterministic
    ops (latency budget 02 §9).
12. **Events** — none produced (consumes `DiscoveryItemCreated` scenario checks via
    Agent).
13. **Jobs** — `scientific` kind (idempotent, observable, 01 §5.3).
14. **Permissions** — none.
15. **Security** — inputs validated (LaTeX injection-safe rendering via `MathRenderer`
    `onError` → styled raw source, 02 §5.4); no network needed.
16. **Offline behavior** — deterministic light ops work offline (local engine);
    heavy jobs queue.
17. **Error handling** — numeric errors = typed results (domain, dimensions, bounds
    failures surfaced, never silent); LaTeX invalid → raw source + `onError`
    (graceful, AD-10 rule).
18. **Recovery** — stateless engine: no recovery; jobs retry.
19. **Observability** — job SLOs (`scientific` kind), verification-failure rates.
20. **Tests** — unit tests for determinism (golden values), unit/dimension checks,
    symbolic ops, verification pipeline (01 §7 job tests family), `MathRenderer`
    crash-safety test (02 §11).
21. **Known limitations** — symbolic solving "where the equation s'y prête" (ADR
    §15 wording: not a general theorem prover); engine backend perf on mobile for
    light ops = perf-budget item (02 §9.1 ≤300 Ko / TTI).
22. **Dependencies** — Knowledge (formulas/sources), Learning (exercises), Agent
    (verification), `MathRenderer` (presentation).
23. **Future evolution** — additional specialized backends; Phase 2 desktop may
    enable heavier local compute.
