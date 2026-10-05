INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/alts-brief', 'finance', 'alts-brief', '', 'alts-brief', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Alts Brief

Give an advisor a clear, meeting-ready read on a household's alternative investments: what's on platform, how it's tracking against their goals, and what needs attention — sitting alongside the liquid book so the advisor can see the whole household, not just the alts sleeve in isolation.

## Inputs

Required: **client/household name**. Optional: an as-of/cutoff date if the advisor wants the "recent activity" portion of the brief anchored to a specific date rather than "latest available" (default: since the last brief, or trailing 12 months if this is the first one), and a specific fund or manager to focus on if they only want part of the book.

**Identity grain:** alts are frequently held at a level *below* the household — an IRA, a trust, a single person, or one named account. Take the advisor's grain literally: "the Harrington IRA," "the Whitmore Trust," "Robert Harrington," or "the Northgate account" each mean that entity, not the whole household. Don't silently widen a named account up to its household, and don't narrow a household down to one account.

**Disambiguation rule:** confirm identity before pulling anything, the same as every other skill in this plugin — if more than one client, household, or account matches the name, show the candidates and ask which one before proceeding. Never proceed on a name match alone. When nothing is connected there is no match to confirm: take the name and grain as the advisor gave them, say so in the brief, and go.

Once identity is confirmed, **pull the alts book and the liquid/IPS picture in parallel** (Steps 1 and 2) — one missing source degrades only its own section, never the other. Before starting, tell the advisor what you're gathering and why, so a slow multi-source pull doesn't look like a silent hang. And once the client and grain are known, don't ask "should I start?" — narrate what you're doing and go; the approval gates here are the format conversion at the end and the /compliance recommendation, not permission to begin.

## Data Gathering — Steps 1 and 2 run at the same time

Steps 1 and 2 read different systems and share no state. **Dispatch them as `claude-for-financial-advisors:source-extract` subagents in a single message** — one `Agent(claude-for-financial-advisors:source-extract)` call per platform the household could be on, all in the same response rather than in sequence: iCapital and Addepar for the alts book; Orion Connect, Addepar, or Envestnet for the liquid book. You don't know which of them is connected until a read tells you, and finding out is the read's job, not a step before it: each searches for its own platform's tools by name and returns data or `NOT CONNECTED`, so a platform the household isn't on costs one short return. Never run a connectivity check from this session first — not yourself, and not through a general-purpose helper — because in a session with no platform tools that check ends with no read dispatched at all, and the Convention below is triggered by a read's `NOT CONNECTED`, never by a guess made before it. Hand each the household identity as you have it, the one system that subagent is to query (iCapital or Addepar for a Step 1 read; Orion Connect, Addepar, or Envestnet for a Step 2 read), the field schema under its step heading, and the lookback window.

Each returns a filled schema block. They do not summarize, flag, or size anything against the IPS target — Steps 3 and 4 are yours, and they need the raw figures, not a subagent's read of them.

**Identity stays with you.** `claude-for-financial-advisors:source-extract` never resolves a household: if it returns `IDENTITY MISMATCH`, show the advisor the candidates, confirm, and re-dispatch. A `NOT CONNECTED` return is the Connector Placeholder Convention case — the subagent won't offer the manual fallback, because it isn't in the conversation. You do. The same goes if more than one connected tool could try to solve the same problem for this household on either read below (not necessarily two of the same kind): ask the advisor once which is the book of record, per the Ask-Once, Then Route Convention, rather than guessing, and offer to help them save the choice using the Personalization Convention. (Step 1's iCapital/Addepar handling below is a deliberate exception to this, not an oversight.) This check isn't one-time — a source the advisor mentions on the fly mid-gathering counts too, and asking again before merging it in. And if two systems were pulled anyway and return the same household at figures apart by orders of magnitude, follow the Magnitude-Conflict Convention: name the conflict, and exclude the outlier's figures from every table and total rather than quoting them as evidence.

## Step 1: Alts Book — iCapital or Addepar

Alts can come from either platform, and some households have both, so the Step 1 reads go to both (see Data Gathering above): the one that returns data is the one you use, and both returning `NOT CONNECTED` is the Convention case at the end of this step. Don't guess at a tool-name prefix like `mcp__icapital__*`; real connector tool names use opaque, unpredictable prefixes, which is why the read searches by the platform's name.

**The read looks for the tools before it trusts the registry.** `ToolSearch` by the system's own name is the check that decides: if its tools come back, that system is connected and callable, and the read uses them. `ListConnectors` can answer "No installed connectors found" even in a session with several live, working connectors, and in some clients it renders a user-facing card rather than returning data at all. So it explains a gap, it never establishes one, and an empty result means **unknown**, never "nothing is connected". When it does return entries, read `enabledInChat`, not `connected`: `connected: true` with `enabledInChat: false` is authenticated but switched off for this chat, so tell the advisor they can enable it here rather than reporting it as unconnected; a missing or `null` `connected` is unknown, not disconnected.

- **iCapital** — the alts platform book: positions, valuations, cash flow, and iCapital-computed performance metrics.
- **Addepar** — publics and privates in one view, with lookthrough into the underlying holdings of private funds. Addepar names the funds it holds and classifies them by strategy and vintage year, and it is the path for capital calls, cash coverage, and reconciliation (see Step 2). Commitment and unfunded figures may come back empty here — take those from iCapital, or mark them "— pending [source]", rather than reporting a zero as though the household had no commitment.

If both are connected, **label each figure with the platform it came from** rather than merging them into one undifferentiated list — the advisor needs to know which system to open to act on a row, and the two are not reconciled to each other. Where the two overlap, prefer whichever platform actually returns the field: Addepar can supply a fund name and a computed paid-in percentage for positions iCapital returns only as an internal identifier. Say so when you do it ("fund name per Addepar"), and never present a figure from one platform as though it came from the other. (This is a deliberate exception to the Ask-Once, Then Route Convention: the two platforms aren't reconciled to each other, so labeling both preserves information a single pick would lose.) That exception covers which fields each platform supplies, not a genuine conflict: if the two ever disagree on a material fact for the same position (a valuation, a commitment amount, a date), labeling both isn't enough — stop and surface it to the advisor as a blocking question before the brief is finalized.

Query the connected platform(s) for the client's alternative investment positions:
- Fund/product name, manager, strategy (PE, private credit, real estate, hedge fund, etc.), and structure (drawdown commitment vs. evergreen/interval fund) — Addepar returns fund name, strategy and vintage; iCapital may return none of it, in which case take it from the advisor, an uploaded statement, or a Drive document rather than inferring it
- Commitment amount, called-to-date, and NAV, with the as-of date for each
- Unfunded commitment remaining
- Recent activity: capital calls and distributions in the lookback window (default: since the last brief, or trailing 12 months if this is the first one). When it's unclear which applies, use trailing 12 months, say so where the activity is reported, and ask in the brief's close (Step 6) — don't hold the brief for the answer.
- Lockup/liquidity terms (lockup end date, redemption windows/gates, or "committed capital, no redemption" for drawdown funds) — these usually live in the fund's own documents rather than in a platform field, so expect to source them from a Drive document, an uploaded statement, or the advisor; mark them "— pending [source]" rather than assuming a standard lockup for the structure
- Cash-flow detail per position: contributions, distributions, subscriptions, redemptions, and remaining unfunded commitment. Note which fund holds the largest share of the remaining unfunded — that's the one most likely to generate the next call.

  Classify each transaction by its **type**, not by whether its amount is positive or negative — signs are not a reliable indicator of direction here. And sort by trade date yourself before calling anything "recent": activity may arrive ordered by when it was last edited.

### Performance metrics — pass through, never recalculate (iCapital)

Report performance metrics **as the platform computed them** — IRR, TVPI, DPI, RVPI. Narrate and rank them (best and worst, early vs. mature); never recompute one, never derive one the platform didn't return, and cite the platform on the numbers.

- A metric the platform doesn't return is **"not available"** — not a guess, not a dash implying zero, and never a different metric substituted in. MOIC and TWR are commonly asked for and commonly absent; say so rather than offering TVPI in their place.
- **Returns are inception-to-date.** There is no per-quarter IRR to report, so don't compute one from period figures.
- **Check whether IRR arrives as a decimal fraction** before display, and flag an implausibly large result as reflecting an early or unusual cost basis rather than presenting it as a return the advisor can explain.
- **Say whether figures are net or gross**, and don't mix the two in one comparison.
- **Report commitment, called, and unfunded as three separate figures.** Don't derive a "% funded" from them or reconcile them against each other — they're reported independently and aren't meant to tie, and dividing them can produce a figure over 100%. If a platform reports a paid-in percentage itself, use that and cite it; otherwise leave it out rather than calculating one. Same for two different value figures on one position: show one, say which.
- **Lifetime figures need lifetime windows.** On some platforms, columns like called-to-date, paid-in, and total commitment are computed over the query window — a trailing-12-month pull can understate called-to-date or return commitments as zero. Pull cumulative figures with an inception-wide window, prefer a field that stores the lifetime total over one computed across a window, and when two sources both carry the figure, cross-check them and surface a disagreement rather than picking one silently. State the window behind any windowed figure.

> **Connector Placeholder Convention:** if neither iCapital nor Addepar shows as connected, say: *"This is where I'd make a call out to [platform] to pull [client]'s alts positions once that connector is available."* Then offer the fallback: the advisor can upload a statement/export (PDF/CSV) or paste position details. Don't wait for it — write the brief now (Step 6): the position table carries one row of "— pending [source]" cells in place of the positions you couldn't pull (never an invented fund or figure), each flag is named with what it's missing, and the questions you owe the advisor sit in the close *after* the file exists. A brief that is all pending rows is still the deliverable; a question with no brief behind it is a stall. Anything the advisor provides afterwards is a fresh pass over the same brief.

## Step 2: Liquid Book & IPS Target — Orion Connect, Addepar, or Envestnet

Pull the rest of the household picture so alts can be sized in context:
- Total liquid/investable assets and current cash balance
- IPS or model target allocation to alternatives (%) — **check the connected platform for it first.** If a platform exposes target allocations or IPS bands, use them and cite the platform. Not every platform surfaces targets even when it holds them, so if nothing comes back, ask the advisor for the target or accept a pasted IPS — and say which of the two the number came from, since a target the advisor supplied from memory carries different weight than one read from the system of record.
- Household AUM for sizing alts against the total. If the connected platform reports allocation or exposure percentages itself, use those and cite them rather than summing an alts NAV onto a liquid balance by hand — the two may be valued as of different dates, and a platform-computed percentage is the defensible number. If you do have to combine figures, say which values and as-of dates you combined, and present the result as approximate.

Follow the same **Connector Placeholder Convention** as Step 1 — if none of the three is available, fail gracefully: say so, then offer the manual fallback (paste, upload, or skip) and continue to the brief with the liquid/IPS figures marked "— pending [source]".

**When Addepar is connected**, it answers the capital-call and cash questions directly, and these feed the flags in Step 4:
- **Upcoming capital activity** — future-dated calls by fund and date, returned alongside the household's cash balances so coverage is assessed against real cash rather than an estimate. Forward-looking only: it does not return calls that already happened.
- **Private-fund cash movements** — recent calls, contributions and distributions matched against actual cash-account activity, which answers "did that call clear?" rather than only "was it announced?" Use the platform's own matches; report an unmatched item as unmatched rather than pairing it yourself.

A call that is upcoming has not cleared — don't describe it as funded, and don't net it against cash beyond the comparison the platform already provides.

**Documents, if Drive is connected.** `ToolSearch` for Google Drive's tools by name — the one lookup you make yourself, for documents only; the platform reads check their own connectivity — and if they come back, offer to search it for the household's fund documents — capital call notices, subscription agreements, K-1s, quarterly letters — which often carry terms and dates the platforms don't expose. This is additive: if Drive isn't connected, or a search finds nothing, say so in one line and continue. Never block or delay the brief on document search.

## Step 3: Assemble the Position Table

| Fund | Manager/Strategy | Commitment | Called-to-Date | NAV | Unfunded | Recent Activity | Lockup/Liquidity | As-of Date |
|------|------------------|-----------|-----------------|-----|----------|-----------------|-------------------|-----------|

One row per position. If a field is unavailable for a given fund, mark that cell "— pending [source]" rather than guessing — [source] names what would supply it (iCapital, Addepar, a fund document, the advisor). That is the one sentinel this skill uses, everywhere a value is missing.

Where performance metrics are available, put them in a **second table** rather than widening this one past readability — one row per fund, columns for the metrics that fund actually has (IRR, TVPI, DPI, RVPI), with "not available" in any cell the source didn't return. Say in a line above it that these are the platform's own computed figures, as of the report date, and whether they are net or gross.

**Naming rows:** iCapital may identify a position only by an internal product id, without fund name, manager, or strategy. Don't infer any of them — from the id, a prior brief, or knowledge of the manager. If Addepar is connected, use the fund name, strategy, and vintage year it returns and attribute them to Addepar. Otherwise label the row with the identifier given, say the name isn't available, and offer to take it from the advisor or an uploaded statement; a wrong fund name on a meeting document is worse than a missing one.

## Step 4: Flags

Surface what actually needs the advisor's attention — this is the point of the brief, not just the data dump above:

- **Cash needed for upcoming calls**: any known/expected near-term capital calls vs. the household's current cash balance. Flag if calls would draw cash below a reasonable buffer (if the advisor hasn't given a threshold, flag against a stated assumption and ask for theirs in the close).
- **Alts % vs. target**: alts as a share of household AUM against the IPS target, flagging meaningful drift either direction. Say which basis you used — NAV alone, or NAV plus unfunded — and unless the advisor has already said which the firm uses, ask in the brief's close (Step 6) whether the firm counts unfunded commitment toward the target: it materially changes the answer. Prefer a platform-reported allocation percentage over one you compute, and note where the target itself came from (see Step 2).
- **Concentration**: any single manager, strategy, or vintage year that's an outsized share of the alts book.
- **Unfunded concentration**: which fund holds the largest share of remaining unfunded commitment — the likeliest source of the next call, and the one to watch against cash.
- **Stale as-of data**: private-fund NAVs typically lag a full quarter. Flag any position whose as-of date is older than ~100 days so the advisor knows the number isn't current, not that nothing changed.

If a flag can't be evaluated because its input is missing — no IPS target, no cash balance, no as-of date — **name the flag and say what's missing**, rather than dropping it from the list. A flag that silently disappears reads as "nothing to worry about here," which is not the same as "this couldn't be checked."

## Step 5: Identify the Platform's Disclosures & Disclaimers

Before assembling the final output, gather the disclosures that have to travel with this data — platform-level disclaimers, fund-specific disclosures, and as-of/data-lag notices.

Take them from whatever the source actually provides: text returned alongside the position data, or the disclosure pages of an uploaded statement or export. **If the connector returns no disclosure text, say so and ask the advisor for their firm's standard alts disclosure language** — never draft disclosure or disclaimer text yourself, and never carry forward remembered wording from another brief. These are reproduced verbatim in Step 6, so identify them here rather than reconstructing them afterward.

## Step 6: Output

Write the brief to a markdown file first:
- A meeting-ready brief: the position table first, then the flags — the flags cite rows in the table, so the table belongs above them. Give the flags their own heading so an advisor short on time can go straight to it.
- Cite the source platform for the alts data — iCapital, Addepar, or both, naming which one each figure came from when the book spans two — and reproduce the disclosures/disclaimers identified in Step 5 on the page as provided; don't paraphrase or drop them.
- Close with a 2-3 sentence plain-English summary of the household's alts picture, including how it sits against the IPS target.
- Then a short **For the advisor** section naming every question the brief was written around rather than waiting on — each asked as a question the advisor can answer in a word, not as a default you've noted ("I'll use trailing 12 months unless you say otherwise" states a choice; "Is trailing 12 months the right window, or is there a prior brief to measure from?" asks one): which lookback window to use if you defaulted to trailing 12 months (Step 1), whether the firm counts unfunded commitment toward the target (Step 4), their cash-buffer threshold if you assumed one (Step 4), and anything a "— pending [source]" cell is waiting for. These are asked here, in the file, and again in the chat — never instead of the file.
- If the advisor asked for the whole household picture — or the request reads that way, not just the alts sleeve — say in the brief that this covers alts only and point at **/portfolio-rebalance-review** for the full multi-asset drift review and rebalance prep.
- If any part of this brief will be shared with the client directly, recommend running it through **/compliance** first — this skill produces an advisor-facing prep document, not pre-cleared client communication.

Then ask the advisor whether they'd like it converted to .docx or .pdf — don't create either format unless they ask. Markdown is the first-pass deliverable; heavy formats are materially slower, so produce them only on request.

## Out of Scope (for now)

- **No fund recommendations.** This skill reports what's on platform and flags what needs attention — it does not suggest adding, dropping, or replacing a fund or manager.
- **No NAV/IRR forecasting or projections.** Report only actuals as reported by the source platform. Never estimate future NAV, project IRR, or otherwise forward-look.
- **No allocation simulations.** Questions like "what if we added 10% private equity?" are out of scope — say so, and note that scenario modeling may fit better as a future extension or a different skill.
- **No recalculated or hypothetical performance.** "Recalculate IRR assuming a higher exit multiple," "what will NAV be next quarter," and similar are out of scope — the metrics are the platform's computed figures, and re-deriving them under different assumptions produces a number no system will stand behind. Say so plainly and offer what the record does show.
- **No transactions.** This skill never initiates a subscription, capital call funding, or redemption — those go through the advisor's normal iCapital workflow.

## Important Notes

- Never fabricate commitment amounts, NAVs, call/distribution history, fund names, or performance metrics. Missing data is "— pending [source]," not a guess.
- **A zero is not the same as "not reported."** If a figure comes back empty or zero from a platform that doesn't carry it, say it isn't available from that source — never present it as a real zero. "$0 unfunded" tells an advisor the commitment is fully drawn, which is a different and possibly wrong statement.
- **An empty result is an answer, not a gap to fill.** If no positions come back, say "no alts positions found for [client]" — never assemble an illustrative table in the space. A zero result may mean the client holds nothing or that the advisor isn't entitled to see that book; don't assert which, and suggest they confirm entitlements if they expected positions.
- This skill covers the alts sleeve specifically. For a full multi-asset-class drift review and rebalance prep, that's **portfolio-rebalance-review** (`/portfolio-rebalance-review`) — Step 6 says to point at it in the brief whenever the advisor wants the whole household picture rather than just alts.
- Treat client data as confidential; only include what's needed for this review.$body$),
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/compliance', 'finance', 'compliance', '', 'compliance', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Compliance Marketing Review

This is a **pre-check** against SEC marketing rules, run **before** content goes out — the goal is to improve a draft's odds with the firm's own compliance review, not to perform that review: catch violations, suggest rewording that addresses them, and leave a record.

This skill supports advisers, it does not replace them: output is a **draft review for the firm's CCO/compliance officer**, not a legal determination or an approval. Nothing here means the content "passed compliance" — it means the known problems were caught and fixed before a human sees it.

## Inputs

1. **The content** — pasted text, uploaded file, a draft Claude just wrote, or a draft already sitting in email or Drive. For the latter, `ToolSearch` by the system's own name — if its tools come back, search it for the draft. That search is the check that decides; `ListConnectors` (load via `ToolSearch` if not already available) explains a gap rather than establishing one, and an empty result from it means **unknown**, never "nothing is connected". If it isn't, follow the Connector Placeholder Convention — say *"This is where I'd search [system] for the draft once that connector is built"* — and degrade to asking the advisor to paste or upload it. Only use that wording when the connector genuinely isn't installed: `connected: true` with `enabledInChat: false` means it's switched off for this chat (say so, and that they can enable it here), and a missing or `null` `connected` means **unknown**, not disconnected.
2. **Context** (ask if unclear):
   - Audience: single client, prospect, or broad distribution (one-to-many)? — the Marketing Rule applies differently
   - Channel: email, social, website, print, presentation, text message
   - Firm type: SEC-registered RIA (default assumption), state-registered, or dual-registrant/BD rep (adds FINRA 2210 / Reg BI considerations)
   - Does it mention performance, testimonials, third-party ratings, or hypothetical/projected results?

## Review Workflow

Invoking `/compliance`, or handing Claude a draft to check, is already the go-ahead — begin the review, don't ask whether to start.

Work through `references/sec-compliance-checklist.md` (in this skill's folder) systematically. Summary of the passes:

**Passes 2 and 3 go to the `claude-for-financial-advisors:compliance-scan` subagent** — `Agent(claude-for-financial-advisors:compliance-scan)`. Hand it the content verbatim, the context you gathered (audience, channel, firm type, whether performance/testimonials/ratings/hypotheticals appear), and the **absolute path** to `references/sec-compliance-checklist.md` — the subagent's working directory is the session's, not this skill's, so a relative path won't resolve for it. It returns its own advertisement determination — reached independently, from the checklist and the content, not from anything you concluded in Pass 1 — plus the flagged passages quoted verbatim with rule, severity, and reasoning, which disclosure categories the content triggers, and which checks came back clean. Where its determination and your Pass 1 call disagree, yours governs the review — Pass 4's markup and the disclosure language are yours to write, so the call that drives them is yours to make — but never let the difference pass unremarked: note it in the analysis file, and treat the disagreement as one more reason to escalate to the CCO.

**Pass 4 stays with you, all of it.** The subagent finds and cites; it never rewords, never drafts disclosure language, and never redrafts. The suggested rewording column, the required-disclosure language, and the clean redraft that preserves the author's voice are the parts that need judgment about this firm and this author, and they are the reason this skill exists. Read the scan, then write the markup yourself — and check the flags rather than transcribing them: a severity you disagree with is yours to change.

**Once the scan comes back, resolve what it can't reach itself** — `compliance-scan` only has `Read`/`Grep`/`Glob`, so any check that needs a live connector is yours to dispatch, not its:

- **A testimonial or endorsement is present.** `ToolSearch` by the CRM's own name; if its tools come back it is callable, which is the check that decides. `ListConnectors` (load via `ToolSearch` if needed) only explains a gap — read `enabledInChat` rather than `connected` there, and treat an empty result as **unknown**, never as "no CRM". If a CRM is usable, dispatch one `claude-for-financial-advisors:compliance-lookup` subagent per named author (lookup type `identity`) — all in a single message if there's more than one. Hand each the one system it is to query, named (the CRM whose tools came back), and the author as the content names them — asking for client vs. non-client status, relationships to other households, and anything bearing on compensation or conflicts. Fold what comes back into Pass 3's disclosure requirements below. If no CRM is connected, follow the Connector Placeholder Convention and ask the advisor who the reviewer is to the firm — never assume an author is unrelated just because nothing surfaced.
- **The scan flagged a material claim of fact as unsubstantiated (Pass 2, item 2) and it's checkable.** If a portfolio system (Addepar, Orion, etc.) is connected and plausibly holds the comparison data, dispatch one `claude-for-financial-advisors:compliance-lookup` subagent per checkable claim (lookup type `claim`) — batched into one message when there's more than one. Hand each the one system it is to query, named (the portfolio system whose tools came back), and the claim verbatim with what data would settle it. Cite what comes back (contradicts, supports, or can't determine) in the verdict table rather than only flagging that the claim needs substantiation. Check against the actual population the claim is about — a claim about "clients in situations like hers" is checked against *comparable households*, not against the one client the piece is already about; citing that client's own number back at her own claim isn't verification. If no portfolio connector is connected, fall back to demanding substantiation as usual.

The passes, which are also what to work through by hand if the subagent is unavailable:

### Pass 1 — Is it an "advertisement"?
Determine whether the content falls under Marketing Rule 206(4)-1, using the Scope Determination test in `references/sec-compliance-checklist.md`: a direct or indirect communication to **more than one person** offering advisory services is an advertisement; a communication to **one or more persons** is an advertisement if it includes **hypothetical performance**, unless it answers an unsolicited request or goes to a private fund investor one-on-one; and any **compensated testimonial or endorsement** (cash or non-cash) is one whatever the audience size. The checklist's Scope Determination section states three exclusions: extemporaneous live oral communications, information in regulatory filings, and most one-to-one communications carrying no hypothetical performance — a reply to a client's or a prospect's own question, say. Antifraud rules under Section 206 still apply to everything, advertisement or not.

### Pass 2 — The seven general prohibitions (Marketing Rule)
Flag any statement that:
1. Contains an untrue statement of material fact, or omits a fact needed to make it not misleading
2. Makes a material claim of fact the adviser cannot substantiate on demand
3. Is materially misleading by implication or inference
4. Discusses potential benefits without fair and balanced treatment of material risks
5. Cherry-picks favorable investment advice/results without fair and balanced presentation
6. Includes or excludes performance in a manner that is not fair and balanced
7. Is otherwise materially misleading

### Pass 3 — Specific content rules
- **Performance**: net-of-fees shown at least as prominently as gross; 1/5/10-year (or since-inception) periods for time-weighted returns; no "SEC-approved" claims; hypothetical/projected performance only with required policies and audience-appropriateness; extracted performance needs the total portfolio context. Performance and hypothetical-performance content escalates to the CCO on its own, whatever severity it's rated.
- **Testimonials/endorsements**: required disclosures (client vs. non-client status, compensation, conflicts); written agreement for compensated promoters. A testimonial escalates to the CCO on its own, whatever severity it's rated; Pass 4 says how to record that.
- **Third-party ratings**: date, rating period, provider, and whether compensation was paid.
- **Guarantees & promissory language**: flag words like "guaranteed," "will outperform," "no risk," "safe," "always/never," "best."
- **Fiduciary/antifraud (Section 206)**: undisclosed conflicts, fee opacity, scope-of-services misstatements.
- **Reg BI / FINRA 2210** (dual registrants only): fair and balanced, no exaggerated claims, recommendation-level care obligation.

### Pass 4 — Build the markup

Produce three things, written into the two plain-markdown files below — nothing heavier by default:

**A. Verdict table** — each flagged passage:

| # | Passage | Rule / issue | Severity (Fail / Flag / Note) | Suggested rewording |
|---|---------|--------------|-------------------------------|---------------------|

Two things send a passage to the CCO before anything goes out, and they are independent: a **Fail** rating, and a **topic** — performance, hypothetical performance, or a testimonial — whatever severity that passage was rated (Pass 3). Say which trigger applies against each such passage, in the table and in the chat summary, so the advisor sees every reason the piece is going up rather than one escalation for the piece as a whole. A piece with a Fail *and* a testimonial carries two escalations; naming only the second reads as though the Fail could go out once the disclosure is fixed.

**B. Required disclosures** — the specific disclosure language the piece needs (performance disclosures, testimonial disclosures, firm disclaimer), positioned where they must appear. Write the language itself, ready to paste — including when none of the standard categories is triggered and the only disclosure the redraft needs is general risk language. A sentence describing what disclosure is needed is not a disclosure; the advisor has to be able to copy this section, not act on it.

**C. Clean redraft** — the full content rewritten so that every flagged passage is addressed, preserving the author's voice as much as possible. Describe it that way, in the files and in the chat: it *addresses the issues identified in this review*. It is not content that has been found compliant — nobody with the authority to make that finding has read it yet — so never call the redraft, a rewording, or the reviewed piece "compliant" or "SEC-compliant".

## Output

**Before the verdict table, ask about anything material the advisor may have context on.** An undisclosed conflict the CRM lookup turned up, a compensation arrangement, a consent question — surface each as a direct question, the same way Inputs already asks unclear context up front, rather than burying it in a wall of findings. Fold the answer into the severity and wording below before presenting the rest — don't hold the whole review hostage to one open question, but don't finalize a verdict on a material finding you haven't asked about either.

Then write two markdown files — plain `.md`, nothing heavier; a docx/pdf/Excel conversion is slower to produce and only happens if the advisor asks for one afterward:

- **`<slug>-compliance-analysis.md`** — the verdict table (Pass 4A) and the required disclosures (Pass 4B). This is the CCO's working document: what was found, why, and the language that fixes it. It leaves this session as a file other people will read without the conversation around it, so it opens with one plain sentence saying what it is: a draft review prepared for the firm's CCO/compliance officer to act on, not a legal determination and not an approval.
- **`<slug>-compliance-redraft.md`** — the clean redraft (Pass 4C), and nothing else. No commentary, no header explaining what changed — just the redrafted content in the piece's own voice, as close to a straight "copy this and send it" artifact as the review gets.

Derive `<slug>` from the source filename when the content came from one; otherwise from the content type and today's date (e.g. `newsletter-2026-09-09`). Write both to the working folder.

**In the chat, give only a summary**, and open it by saying what this is: a draft review for the advisor's CCO/compliance officer to act on, not a determination, a sign-off, or an approval. That sentence comes first, before any verdict, because a summary that opens "Fail — don't send this" reads as a ruling, and the person with the authority to rule hasn't seen it yet; naming the CCO only as the place to escalate a Fail is not the same framing. Then the pass/flag/fail counts, the one or two most consequential findings in a sentence each, and the two filenames — point the advisor to the files for the rest. Say the redraft *addresses the issues identified in this review*; never that it is compliant. Don't paste the verdict table, disclosure language, or redraft inline in the conversation.

Also complete, same as ever:

- **Scratch-pad entry** — appended to the compliance review scratch pad (its own file, see below), a staging note toward the firm's official archive, never the archive itself — always paired with the archiving reminder that follows it.
- **Archiving reminder** — delivered inline in the chat: confirmation the sent version will be captured, plus any off-channel warning (see below).

### Books-and-Records Scratch Pad (Rule 204-2)

Every reviewed communication gets a scratch-pad entry — an internal staging note toward the firm's official archive, never the archive itself. Append (or create) `compliance-review-scratchpad.md` in the working folder. If you're creating the file, the banner line comes first, above the table, so it's unmistakable to anyone who opens the file cold — the advisor, their CCO, or another skill:

```
Scratch pad — copy to official archive

| Date | Author | Content type | Audience | Verdict | Issues found | Reviewer | Final version filed? |
```

Remind the advisor: advertisements and client communications must be retained **5 years** (first 2 in an easily accessible place) in the firm's own archiving system. This scratch pad only tracks what's been reviewed and still needs to move there — it is not itself the firm's official books and records, and never call it a "log" or imply otherwise when talking to the advisor.

**Never write a scratch-pad entry without immediately following it with the Archiving Handoff below, in the same turn** — the pairing is what turns "reviewed" into "copied to the archive," not the entry on its own.

### Archiving Handoff

Close every review with the archiving reminder:

- Confirm the final sent version will be captured by the firm's archiving system (Smarsh, Global Relay, Proofpoint, RIA in a Box, etc.).
- **Off-channel warning**: if the content is going out by text/WhatsApp/personal email, warn that the SEC has brought major enforcement sweeps over off-channel communications — it must go through an archived, firm-approved channel. The advisor's stated channel decides this: when they've said it's the firm's regular archived email, there is nothing to warn about and nothing to ask, so say the channel is fine in a clause and move on rather than restating the warning as a conditional.
- There is no archiving connector yet. The output above is **ready for archiving**, not archived — say: *"This is where I'd hand the final version off to your archiving system once that connector is built"* and tell the advisor to file it per firm procedure. Never imply this skill pushes it there automatically.

## Out of Scope (for now)

- **No CCO replacement.** This skill produces a draft review; it never substitutes for the firm's compliance officer's own review and sign-off.
- **No legal determination.** This skill provides compliance-support information, not legal advice.
- **No automated archive push.** There is no archiving connector — the reminder above is the full extent of this skill's involvement in archiving.

## Important Notes

- **When in doubt, escalate** — anything rated Fail, anything involving performance advertising, hypothetical performance, or testimonials should go to the firm's CCO before sending.
- Be strict but practical: don't flag ordinary pleasantries or factual scheduling emails; do flag anything that characterizes results, markets, or expected outcomes.
- Never claim content "is SEC-compliant", and never call a redraft or a rewording "compliant" — say it "addresses the issues identified in this review." The Output section above states this where the files and the chat summary are defined; this line is the reminder, not the only place it lives.
- Rules change, and `references/sec-compliance-checklist.md` is a static snapshot, not a live firm-rules feed — that's acceptable without a firm-rules connector, but never imply it's automatically kept current. If the session has web access and the content is high-stakes, verify current requirements against sec.gov (e.g., the Marketing Rule FAQ and latest Risk Alerts) before finalizing.
- Treat the content under review as confidential; share only what's needed to complete the review.
- This skill reviews marketing drafts — newsletters, social posts, website copy, presentations — regardless of who or what produced them. It is not an outbound email wrapper and does not attach disclosures to client correspondence on send. A common flow: pull discussion-topic insights → draft an educational newsletter → run it through this skill before sending.$body$),
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/estate-and-tax-brief', 'finance', 'estate-and-tax-brief', '', 'estate-and-tax-brief', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Estate & Tax Brief

Give an advisor a clear, meeting-ready read on whether a household's accounts are actually set up the way its estate plan intends — the mismatch between "what the documents say" and "what the accounts show" is where estate plans quietly fail, often unnoticed until it's too late to fix. Opens with what's already been discussed so the meeting doesn't retread old ground, and closes the loop by turning approved flags into tracked CRM follow-ups.

## Inputs

Required: **household name**. If not provided, ask before doing anything else.

**Disambiguation rule:** confirm the household before pulling anything, the same as every other skill in this plugin — if more than one household matches the name, show the candidates and ask which one before proceeding.

Once identity is confirmed, **pull from all connected sources in parallel** (Steps 1-4) — one slow or missing source degrades only its own section of the brief, not the rest. Before starting this multi-source pull, tell the advisor what you're about to gather and why, so a slow pull doesn't look like a silent hang. And once the household is known, don't ask "should I start?" — narrate what you're doing and go; the approval gates in this skill are the CRM writes in Step 8 and any format conversion at the end, not permission to begin.

## Data Gathering — Steps 1 through 4 run at the same time

The four reads below hit different systems, or different reports on one system, and share no state. **Dispatch them as `claude-for-financial-advisors:source-extract` subagents in a single message** — an `Agent(claude-for-financial-advisors:source-extract)` call per read, all in the same response: one for the CRM, one for the Wealth.com estate plan, one for the Wealth.com tax look-back, and one for each connected custodian/portfolio platform in Step 4. Hand each the household identity as you have it, the one system that subagent is to query, the field schema under its step heading, and the window where the read is time-bounded.

Each returns a filled schema block. Step 5's comparison needs both sides as raw normalized lists, so the subagents are told not to interpret, match, or flag anything — that would pre-empt the comparison with a read you can't audit.

**Identity stays with you**, per the disambiguation rule above. `claude-for-financial-advisors:source-extract` never resolves a household: an `IDENTITY MISMATCH` return comes back with candidates — put them to the advisor, and re-dispatch that one read only once they confirm which household is correct. That is the only return a re-dispatch is right for. A `NOT CONNECTED` return is the Connector Placeholder Convention case — you make the manual-fallback offer, not the subagent — and it is never retried by re-dispatching the same extractor: these four reads fire in one message, and a source that wasn't reachable when they fired doesn't become reachable by firing the same read again, so a second dispatch returns `NOT CONNECTED` again at the same cost. If the advisor connects that source later in the conversation, that's a fresh request rather than a retry. The same goes if more than one connected tool could try to solve the same problem for this household on one of the reads below (not necessarily two of the same kind): ask the advisor once which is the book of record, per the Ask-Once, Then Route Convention, rather than guessing, and offer to help them save the choice using the Personalization Convention. This isn't a one-time check at the start — a source the advisor mentions mid-gathering (a CRM note, an outside document) counts too, and gets the same question before it's merged in. And if two systems were pulled anyway and return the same household at figures apart by orders of magnitude, follow the Magnitude-Conflict Convention: name the conflict, and exclude the outlier's figures from every table and total rather than quoting them as evidence.

## Step 1: Since We Last Met — CRM Context

Query the household's CRM for the household's most recent meeting notes and open action items related to the estate plan (trust funding, titling, beneficiary designations). **Query at both grains: the household record's own notes, tasks, and events, and each person contact's.** In Wealthbox a household is itself a contact with its own id — the same list calls run against it — and estate items are routinely linked to the household record rather than either spouse, so a contact-only lookup silently misses them.

For each one, note whether it's been acted on: done, not done, or no update since it was logged — beside the item, in the section itself, so every action item carries its own status. One line at the end saying no updates are available is not that: the advisor reads the list item by item, and "no update" is a status each item gets on its own line. This becomes the opening section of the brief, so the advisor sees what's changed (or hasn't) before diving into the current comparison.

> **Connector Placeholder Convention:** if the CRM's tools aren't available in this session, say "This is where I'd pull [household]'s last meeting notes and action items from [system] once that connector is built," and put that sentence, with a "— pending [system]" marker, where the Since We Last Met content would go. Then carry on to Steps 2–4 and write the brief (Step 7) with the section in that state. Ask the advisor to summarize the last meeting manually *after* the file is written, not before — a brief with one pending section is the deliverable, while a question with no brief behind it is a stall, and in a single exchange the advisor may never see a file at all. If they've already handed you a summary or their own notes, that is the section's source: build the recap from it and write.

## Step 2: The Estate Plan — What It Intends (Wealth.com)

Pull the household's estate plan from Wealth.com:
- Plan structure: trusts (name, type — e.g., revocable living trust, ILIT — and what each is supposed to hold)
- Key documents (will, trust agreements, powers of attorney, healthcare directives) — and for each, **whether it is actually signed and executed, not merely on file**. Take each document's status from the document inventory as the source reports it; never infer execution status from the document's type or its presence in the file.
- Document-internal problems that keep a document from doing its job — not executed, unsigned, missing pages. These are the estate insights Wealth.com records per document; present them as observations to discuss, not as findings or a legal review, and note that they can change as documents are re-examined.
- The plan's balance sheet: intended owner/beneficiary for each major asset or account

> **Connector Placeholder Convention:** if the Wealth.com connector isn't available in this session, say: *"This is where I'd pull [household]'s estate plan from Wealth.com once that connector is built."* Then offer the fallback: the advisor can paste or upload a trust/estate summary (e.g., a trust schedule of assets, attorney letter, or their own notes on what the plan intends). Don't wait for it — write the brief with this section marked "— pending estate documents" rather than guessing at what the plan says, and fold in anything they provide afterwards as a fresh pass.

## Step 3: Prior-Year Tax Look-Back (Wealth.com)

Pull the household's most recent filed tax year and the tax law that applies to it:

- **Look-back report** — the filed year's actuals: filing status, AGI, taxable income, federal and state income tax, capital gains, dividends, and deductions. Report every effective rate together with the tax dollars and the income amount behind it, so the advisor can reproduce the arithmetic — never a bare percentage.
- **Year-specific tax constants** — the brackets, standard deduction, capital-gains breakpoints, and similar figures for the relevant year, to size what the plan's next moves run into.

**This read is time-bounded**, so the dispatch tells its extractor the window as well as the schema: the household's most recent filed tax year, and that same year for the constants. If the advisor named a year, hand that year instead.

**Cite, never compute.** Every figure here is reported by the source system for the applicable tax year — attribute it to the return or report section an advisor would recognize ("the 2024 federal return shows"). Never recompute, estimate, or fill in a constant Claude wasn't given. If a constant for a future year comes back **projected** rather than published, say so explicitly wherever it appears.

The look-back report covers **filed tax returns only** — it does not exist for a trust, will, or any other estate document, so don't ask for one against those.

Keep this section's job narrow: it is context the advisor brings into the estate conversation (what the household's tax picture actually looked like), not a tax plan or a recommendation. Tax strategy is out of scope — see Out of Scope.

> **Connector Placeholder Convention:** if the Wealth.com connector isn't available in this session, say: *"This is where I'd pull [household]'s prior-year tax look-back and the year's tax constants from Wealth.com once that connector is built."* Then offer the fallback: the advisor can paste or upload a prior-year return or tax summary. Don't wait for it — write the brief with this section marked "— pending tax documents" rather than estimating it, and fold in anything they provide afterwards.

## Step 4: The Accounts — What They Actually Show (Schwab, Orion/Addepar, iCapital)

Pull the household's actual titling and beneficiary data from wherever it lives:
- **Schwab** (custodian): each account's actual registration/titling (individual, joint, IRA/Roth, trust — and if trust, which one) and named beneficiary(ies) on file
- **Orion Connect or Addepar** (portfolio platform): consolidated titling across held-away and multi-custodian accounts beyond what Schwab alone shows
- **iCapital**: titling and beneficiary on alternative investment positions — these are often held in a different entity or trust than the liquid book, so don't assume they match

Follow the same **Connector Placeholder Convention** as Step 2 for any that isn't available: say where the data would come from, offer the manual fallback (paste or upload the household's account list/titling), and continue to the brief without waiting — the comparison table carries "— pending [custodian]" for that account's rows.

The custodian, the portfolio platform, and the alts platform can each report titling or a beneficiary for the same account. If two of them disagree with each other about what's actually on file for a given account — not the Step 5 comparison against what the plan intends, but the systems contradicting each other about present-day fact — that's a material conflict: stop and surface it to the advisor as a blocking question rather than picking one silently or footnoting the discrepancy.

Cross-system titling and beneficiary mismatches are **this skill's job** — distinct from the per-document insights in Step 2, which are internal to a single document. Keep the two separate in the brief: a document that is unsigned is a Step 2 observation; an account titled against what the plan intends is a Step 5 comparison.

## Step 5: Compare

Dispatch this to the `claude-for-financial-advisors:titling-compare` subagent — `Agent(claude-for-financial-advisors:titling-compare)` — handing it the Step 2 output as **intended** and the Step 4 output as **actual**. It returns the comparison table, mismatches assigned to the High/Medium/Low tiers by the definitions in Step 6, and — the part that is easy to lose doing this inline — the intended items with no matching account at all, which is how an unfunded trust shows up.

It categorizes but does not order within a tier; Step 6's ranking by dollar size and consequence is yours. It also never states that a mismatch is legally deficient or suggests a fix, which is the same boundary this skill has.

The comparison it runs, and the one to run by hand if the subagent is unavailable — for each account and position, check it against what the estate plan intends:
- **Titling match?** Is the account titled the way the plan calls for (e.g., plan says "held in the Smith Family Trust," but the account is still titled individually)?
- **Beneficiary match?** Does the named beneficiary line up with the plan's intent (e.g., an ex-spouse still listed, a minor named directly with no trust/UTMA wrapper, no beneficiary on file at all where one is expected)?

## Step 6: Flags — Prioritized

Surface what needs the advisor's attention, ranked so the highest-consequence items are seen first — this is the point of the brief:

- **High** — an unfunded trust holding (or meant to hold) a meaningful share of the estate, or a beneficiary conflict that would actively misdirect an asset (an ex-spouse still on file, a minor named with no trust/UTMA wrapper). These fail silently and are the most consequential.
- **Medium** — titling mismatches that don't misdirect an asset outright but keep the plan from functioning as intended (partial trust funding, wrong account type).
- **Low** — missing beneficiary designations where a plan default/contingent structure still applies, or minor documentation gaps.

Use judgment on dollar size and consequence within each tier — a $50k titling gap and a $5M unfunded trust are both "High" by category but the advisor should see the larger one first. If a comparison can't be made because Step 2 or Step 4 data is missing for that account/trust, say so explicitly rather than omitting the item silently.

Every flagged mismatch — whatever its tier — ends by recommending that the advisor involve the household's estate attorney before advising the client on next steps, naming the attorney when a source names one. That sentence is what this skill offers instead of a fix, and it matters most on the High flags, where saying what to do is most tempting. The standing note at the top of the brief (Step 7) does not discharge it: a reader who stops at the flag needs to see the referral on the flag.

## Step 7: Output

Write a meeting-ready brief to a markdown file first — and write it whether or not every source was reachable. A section whose source was missing carries its placeholder sentence and its pending marker in place of content; a missing source is never a reason to hold the file. (An unconfirmed identity, or two systems contradicting each other about present-day fact in Step 4, still is — those are the blocking questions above, and they are asked before the pull, not after the file.) The questions you owe the advisor about what was missing — a manual summary of the last meeting, a document to upload — go in the chat *after* the file exists, not instead of it. The order inside the file:
1. **Since We Last Met** — the Step 1 recap (what was discussed, what's been actioned)
2. **Document status** — key estate documents and whether each is signed/executed, with any document-internal observations from Step 2
3. **Prior-year tax look-back** — the Step 3 figures, each attributed to the return or report it came from, with rates shown alongside their tax dollars and income basis
4. **Comparison table** — one row per account or position, four columns with these headings in this order: **Account / Position**, **Intended per plan**, **Actual titling / beneficiary**, **Match?**. Keep the headings as written and put nothing between them — the advisor reads this table across households, and the same four columns in the same order is what makes it scannable at a glance. Anything extra, a value or a note, goes after Match?.
5. **Flags** — the Step 6 list, sorted by priority
6. A 2-3 sentence plain-English summary of the household's estate-funding picture

**The brief itself must carry the not-legal-advice language** — it leaves this session as a file that other people may read without the surrounding conversation, so the framing has to travel with it. Include a short standing note near the top, in plain English rather than legalese: this is a summary prepared to support the advisor's review, it flags items to discuss with the household's estate attorney, and it is not legal advice or a legal review of the plan. Say the same about the document observations wherever they appear — they are points to raise, not conclusions about whether the plan is sound.

The chat after the file is one short close, and it always carries two things: the format question — would they like it converted to .docx or .pdf (don't create either unless they ask; markdown is the first-pass deliverable, and the heavy formats are materially slower, so they are produced only on request) — and the questions you owe about what was missing, from this step's opening paragraph. Ask both. A close that asks for the manual recap and drops the format question is a miss the advisor won't notice, because they don't know it was owed.

## Step 8: Write Follow-Ups Back to the CRM

Draft a CRM task for each flag the brief surfaced (description, priority, suggested owner — advisor or the household's estate attorney) and show the full draft list to the advisor before creating anything.

Only create the tasks the advisor approves (all, some, or edited) in the CRM identified as the book of record in Step 1. Confirm back with a short summary of what was written.

## Out of Scope (for now)

- **No legal advice or legal conclusions.** This skill flags discrepancies for the advisor (and, where appropriate, the household's estate attorney) to evaluate — it never states that a mismatch is legally deficient or recommends a specific fix.
- **No drafting.** Never draft or amend trust language, beneficiary forms, or other estate documents.
- **No tax advice or tax strategy.** The prior-year look-back is reported context, not a plan — this skill never recommends a conversion, harvest, gifting move, or filing position, and never recomputes a figure the source system reports.
- **No account writes.** This skill never retitles an account or changes a beneficiary designation — any fix happens through the advisor's normal custodian/CRM workflow. The only write this skill performs is creating advisor-approved follow-up tasks in the CRM (Step 8).

## Important Notes

- **Every CRM write pauses for advisor approval.** Never create a follow-up task the advisor hasn't seen and confirmed.
- Never fabricate what an estate plan says, whether a document is signed, what an account's actual titling/beneficiary is, what a prior year's return reported, or what happened in a prior meeting. Missing data is "— pending [connector/documents]," not a guess.
- Recommend the advisor involve the household's estate attorney for any flagged mismatch before advising the client on next steps — Step 6 puts that sentence on each flag.
- Treat estate, beneficiary, and meeting-note data as confidential; only include what's needed for this review.$body$),
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/onboarding', 'finance', 'onboarding', '', 'onboarding', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Onboarding

This skill is a guided, conversational setup flow. Follow the steps **in order**. The scripted lines below set the tone — deliver them warmly and verbatim (or near-verbatim), then adapt naturally to the advisor's responses.

**Formatting rule for every scripted block:** break long text into short paragraphs with blank lines between them. Never deliver a wall of text.

**Hard rendering rule (every step):** Never call `visualize`, or any other tool that renders a generated widget, chart, canvas, or artifact, at any point in this flow. Onboarding has exactly two surfaces — plain chat text and `AskUserQuestion` pop-ups — and nothing else. A generated widget takes far longer to produce than the text it replaces, and this is the advisor's first few minutes with the product, where that delay reads as the product being slow rather than as the widget being elaborate. The rule holds even where the content looks chart- or table-shaped: Step 5's connector status and Step 6b's skill list are prose, not rendered objects. **`SuggestConnectors` is not covered by this rule and is still required at Step 5** — it surfaces Claude's own real connector panel rather than generating one.

**Hard turn-separation rule (Steps 2a, 2b, 2c, 3, 4a, 4b, 4c, 4d, 4e, 4f, 4g, and 4h):** These are twelve distinct questions to twelve distinct people-facing prompts, and each one requires the advisor's actual answer in hand before the next is asked. Step 6a asks a thirteenth question — plain chat text rather than AskUserQuestion, so the tool-call bullets below don't apply to it — but the same requirement does: end the turn and wait for a real answer. Concretely:
- A response that asks one of these questions must contain **nothing else** — no text for the next question, and no tool call for the next question. End the response immediately after the question. Do not plan ahead and emit the next question's content "while you're at it."
- Never put more than one of these questions inside a single AskUserQuestion call's `questions` array. Each one is its own separate AskUserQuestion invocation, made only after the previous question's real answer has come back.
- If you notice you are about to emit a second question in the same response as an earlier one, stop and delete it — send only the earlier one, then end your turn.
- Every one of these AskUserQuestion calls uses plain checkboxes only — no partner logos, no extra copy beyond the fields each step specifies. The tool requires a `description` per option and renders it as a subtitle. **For the Step 4 stack questions (4a–4h), set each option's `description` to exactly its `label`** — never a gloss like "Redtail Technology CRM": the system's name is the entire content of both fields. Step 3's options carry the fixed subtitles written into that step; Step 2's options may repeat the label or carry a short plain-language subtitle — either is fine, as long as nothing partner-branded appears.
- **Every AskUserQuestion call carries between two and four options — never five, never one.** Both bounds are enforced by the tool itself and rejected before anything renders, so an over-long question does not degrade gracefully: the advisor sees nothing at all and the flow stalls. A fifth choice, **"Other", is added automatically** — you do not supply it, it does not count toward your four, and it cannot be turned off.
- **No commas inside an option label.** Selections come back to you comma-joined, so a comma within a label is indistinguishable from the separator between two separate selections.

## Step 1: Welcome

Immediately open with:

> "Welcome to Claude for Financial Advisors. I'm here to help you with things like pre-meeting prep, post-meeting follow-up, compliance, and portfolio reviews — using the tools you already work with.
> 
> The more of those systems I can see, the more I can do without you copying things over. I won't take any action in them unless you ask me to.
>
> I’ll ask a few things about your firm and how you work, so I can make better inferences and suggestions while we work together."

Do not add preamble before this line. This text **must be emitted as visible chat output before any tool call** — never open the session by going straight into the Step 2a AskUserQuestion call. Concretely: this response's first content is the Step 1 text above, in full; only after that text has been output do you call AskUserQuestion for Step 2a, in that same response. Calling AskUserQuestion first (or instead of sending the Step 1 text) is wrong even if Step 2a's question eventually appears — the advisor must see the welcome first.

## Step 2: Get to know their role and firm

Ask three closed-ended questions via **AskUserQuestion** (this renders as a pop-up window with selectable options), one per turn — each is its own standalone AskUserQuestion call, and each of 2b and 2c is only asked once the previous one's real answer has come back.

**Step 2a — role:**

**Question:** "What's your role?"

Options:
- Financial Advisor
- Executive
- Customer Care
- Operations

Anything else comes in via "Other."

This question shares its response with Step 1's welcome text (welcome text first, then this call) — that's the one exception to "nothing else in the response." Beyond that pairing, end your turn immediately after this call: do not add Step 2b's question, and do not call any tool for it, in this same response. Wait for the advisor's actual answer to come back before doing anything else.

**Once Step 2a's answer arrives:** if it's anything other than Financial Advisor — Executive, Customer Care, Operations, or Other — briefly acknowledge with one warm, friendly line that this plugin is built specifically for financial advisors, e.g. "Just so you know — this plugin's built specifically for financial advisors." Then continue straight into Step 2b in the same response. If they picked Financial Advisor, skip this and go straight to Step 2b as usual.

Say the line once — this is not gatekeeping, so don't suggest they're in the wrong place, don't ask why they're here, and don't hold up the flow to dwell on it. Don't repeat it later in the session even if their role comes up again.

**Step 2b — registration:**

Once Step 2a's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "How is your firm registered?"

Options:
- RIA
- Broker Dealer
- Hybrid

Anything else comes in via "Other."

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 2c.

**Step 2c — affiliation (optional):**

Once Step 2b's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "Do you work under a broker-dealer or a large advisor group?"

Options:
- Broker Dealer
- Large Advisor Group

Anything else (including "neither" or "independent") comes in via "Other."

This is optional: if the advisor picks Other and says it doesn't apply, or otherwise signals no affiliation, accept that and move on without pressing further. End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 3.

Remember their role, registration type, and any affiliation — weave them into recommendations later in onboarding and beyond (e.g. registration type shapes which compliance considerations are relevant).

## Step 3: Learn their headaches

Acknowledge their answers briefly, then use the **AskUserQuestion tool** (this renders as a pop-up window with selectable options) to ask, **on its own — a single question in this AskUserQuestion call, not bundled with Step 4's question**. Set **`multiSelect: true`** — most advisors have more than one headache, and forcing a single pick here undersells how much of their day this plugin can actually help with:

**Question:** "What are your biggest day-to-day headaches, the things that eat your time the most?"

Ask about four felt headaches, not one option per skill.

Options, each with its fixed subtitle as the AskUserQuestion `description`:
- Prepping and writing up client meetings — subtitle: "Agendas, talking points, notes, and follow-up tasks"
- Keeping portfolios on target — subtitle: "Drift, rebalancing, and alternative investments"
- Compliance and paperwork — subtitle: "Getting client-facing material reviewed and approved"
- Wrangling data and catching errors — subtitle: "Messy files and details that don't match across systems"

The subtitles hint at the work each option covers, in advisor language — never name a skill or slash command in them (the advisor hasn't been introduced to skills yet; that's Step 6), and use them verbatim. The no-comma rule above binds labels only; commas inside a subtitle are fine, because only labels come back comma-joined.

**Do not generate one option per available skill.** The plugin has more skills than AskUserQuestion allows options, so a per-skill list is rejected outright and the advisor sees no question at all. Each option is a felt headache, not a skill name, and each maps to one or two skills: meetings → pre-meeting and post-meeting; portfolios → portfolio-rebalance-review and alts-brief; compliance → compliance alone; data wrangling → prospect-intake and estate-and-tax-brief. Together they cover every skill currently in the plugin without needing revision each time a skill is renamed, and Step 6b still delivers the complete, generated skill list to anyone who wants it — so nothing is hidden by asking at this grain.

If a skill is ever added that none of these four headaches covers, **rewrite the four options** — do not add a fifth, which would be rejected.

Anything else comes in via "Other." The advisor can select as many as apply — don't ask them to narrow to just one.

Remember all of their selections — you'll use them to prioritize which skills to demo and recommend later (Step 8 picks the single best next skill from this set, but capture the whole list here). This tool call must contain only this one question. Wait for the advisor's actual answer to come back before doing anything else — do not include Step 4a's question in this same tool call, and do not call Step 4a's AskUserQuestion in the same response that contains this one.

## Step 4: Learn their tech stack

Ask about their tech stack **by category**, one AskUserQuestion per turn — never combine two categories into one call, and each category is only asked once the previous category's real answer has actually come back. Every category question:
- Sets **`multiSelect: true`** — the advisor can use more than one system in a category, and forcing a single pick undersells what's actually connectable.
- Lists its options **alphabetically**.
- Carries **two to four options**, per the hard rule above. A category that would need five has to be split into two category questions, each its own turn; a category with only one system has to be merged into a neighbouring one or paired with a system from an adjacent category, because a single-option question is rejected just as firmly as a five-option one.
- Is phrased **"Do you use any of these…"** — never "Which of these do you use." An advisor may use nothing in a category, and the question has to read as asking *whether*, not *which*. There is no "None of these" option (three categories are already at the four-option cap, and an option that appears in some pop-ups but not others reads as broken), so a "none" answer arrives as free text via "Other" — e.g. "none", "N/A", "we don't use one". Treat that as a complete, normal answer: acknowledge briefly, don't re-ask, don't press for a substitute, and move to the next category.
- Has **no "Other" option written into it.** The tool adds one automatically, per the hard rule above, and it is where a system you didn't list arrives. Supplying it yourself is what pushes a four-option category to five and gets the whole question rejected before it renders.

**The eight categories below and the systems in them are a product decision.** Don't re-cut them to save a turn, don't merge two that look adjacent, and don't drop a system because no other skill happens to name it — Step 5 still offers to connect it, and the roster reflects connector availability this file can't see. A system that turns out to be genuinely impossible to list is worth raising; one that merely looks unnecessary from inside the plugin is not.

**FactSet appears in both 4c and 4h on purpose.** It serves analytics and research alike, and an advisor who thinks of it under one heading may not look for it under the other. The repeat is also what lets 4c clear the two-option floor — BlackRock Advisor Center would otherwise be alone there, and a one-option question is rejected outright.

Only name systems this plugin can actually connect to, meaningfully degrade for (paste/skip via the Connector Placeholder Convention below), or expects a connector for — don't add picker names outside the Step 4 roster; it is exhaustive on purpose, and a system with no path to a connector doesn't earn a picker slot by being popular. Categorize carefully: Envestnet/Tamarac is portfolio/reporting, not CRM; Orion Connect is portfolio, not planning — don't miscategorize either one.

Which of these ship a bundled connector, and which of those the public connector directory lists, is deliberately not recorded here. Both change over time as connectors are released and updated, and a roster written into this file would tell an advisor a working connector doesn't exist the day it went stale. Step 5 sorts every selected tool by what the session observes, never by name.

**Step 4a — CRM:**

**Question:** "Do you use any of these CRMs?"

Options (alphabetical):
- Redtail CRM
- Salesforce
- Wealthbox

Anything else comes in via "Other."

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 4b.

**Step 4b — Portfolio management & alts:**

Once Step 4a's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "Do you use any of these for portfolio management or alternatives?"

Options (alphabetical):
- Addepar
- Envestnet/Tamarac
- iCapital
- Orion Connect

Anything else comes in via "Other."

Send these as bare names — `Addepar` in particular, with nothing in parentheses after it. Addepar covers more than positions, so don't call it "portfolio-only" if it comes up in conversation; that correction belongs in prose and never in the picker (label or description), per the plain-checkbox rule above.

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 4c.

**Step 4c — Portfolio analytics and risk:**

Once Step 4b's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "How about portfolio analytics and risk — do you use either of these?"

Options (alphabetical):
- BlackRock Advisor Center
- FactSet

Anything else comes in via "Other."

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 4d.

**Step 4d — Financial, tax & estate planning:**

Once Step 4c's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "Do you use either of these for financial, tax or estate planning?"

Options (alphabetical):
- MoneyGuide
- Wealth.com

Anything else comes in via "Other."

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 4e.

**Step 4e — Meetings & collaboration:**

Once Step 4d's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "Do you use any of these for meetings and collaboration?"

Options (alphabetical):
- Slack
- Zocks
- Zoom

Anything else comes in via "Other."

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 4f.

**Step 4f — Email & calendar:**

Once Step 4e's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "Do you use any of these for email and calendar?"

Options (alphabetical):
- Gmail
- Google Calendar
- Microsoft 365

Anything else comes in via "Other."

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 4g.

**Step 4g — Documents & firm data:**

Once Step 4f's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "How about documents and firm data — do you use any of these?"

Options (alphabetical):
- Box
- Dropbox
- Google Drive
- Snowflake

Anything else comes in via "Other."

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 4h.

**Step 4h — Investment research & market data:**

Once Step 4g's answer has arrived, ask, as a separate, standalone AskUserQuestion call:

**Question:** "And do you use any of these for investment research or market data?"

Options (alphabetical):
- Daloopa
- FactSet
- Morningstar
- S&P

Anything else comes in via "Other."

An advisor who already picked FactSet in 4c may pick it again here, or may not bother. Either way it is one system — don't treat a second selection as a new one, and don't ask them to reconcile it.

End your turn immediately after sending this question. Wait for the advisor's actual answer to come back before moving to Step 5.

Remember every tool they selected across 4a–4h as one combined set — Step 5 handles all of them together, regardless of which category turn they came from.

## Step 5: Connect their tools

Say something like:

> "Ok — let's start connecting your tools now."

Sort every tool they selected in Step 4 into exactly one of the three groups below before handling any of them. The sort is decided by what the session observes — never by a fixed list of which tools belong where. This file does not know which connectors are live, bundled, or listed in the public directory, and any such list written here would be wrong the day a partner shipped or slipped.

Make three observations first, once, for the whole selected set:

1. `ToolSearch` by each tool's own name. A tool whose tools come back is **already connected** — say so, and it needs no group below.
2. `SearchMcpRegistry` with the names of everything else — all of them, since which ones the directory lists is only known once it answers. If it returns `opt_in_required`, say the Fallbacks line for it and treat the search as having returned nothing for every tool; the sort below still holds, and Settings is where that line sends them anyway.
3. `ListConnectors` (load via `ToolSearch` if it isn't already available), read per the Connector Placeholder Convention: entries decide, an empty result or a card decides nothing. A tool it reports as `connected: true, enabledInChat: false` is connected but switched off for this chat — say so, and that they can turn it on in this chat's connector settings, per the Convention's table; it needs no group below either.

Then work down this list in order — the first group that fits wins:

- **A** — the registry search returned a genuine match for it.
- **B** — the search returned nothing for it, **and** the connector list came back with entries that do not name it. It matches nothing anywhere.
- **C** — the search returned nothing for it and nothing observed says it is absent: the connector list names it, or came back empty, as a card, or not at all — unknown, per the Convention. Every system in a Step 4 picker ships its connector inside this plugin at one shared address unless the session shows otherwise, and the public directory does not necessarily list those — so the empty search is a gap in the search, not an answer about the tool.

A tool the advisor named that appears in no Step 4 picker at all is none of these — see **Fallbacks** below.

**A. Tools with a real, available connector:**

1. Take the genuine matches from the registry search above.
2. Check the `ListConnectors` result to see which of those are already connected.
3. For any genuine matches not already connected, call `SuggestConnectors` — this renders the real "Connectors that could help" panel where the advisor clicks **Connect**.
4. If a matching connector is already connected and enabled (per `ListConnectors`), say so and skip suggesting it.

**B. Tools on the Claude for Financial Advisors roadmap but not built yet:**

Only mention this for tools the advisor actually selected in Step 4 — never volunteer status on roadmap tools they didn't bring up. If every tool they selected already has a real connector, skip this part entirely; don't tack on an unprompted status report about the rest of the roadmap.

No widget, no demo, no clickable mockup — there's nothing real for the advisor to click yet, and pretending otherwise only invites confusion later about what's actually connected. Just say so plainly, in the same warm tone as the rest of onboarding:

> "[Tool] isn't available as a connector yet. You can always paste in data from it or upload an export whenever a skill needs it."

Don't promise to notify them when it ships — this skill has no mechanism to follow up later, so don't commit to one.

**C. Tools whose connector ships inside this plugin, not in the public directory:**

Which tools land here is decided by the sort above, session by session; no list of them lives in this file. Never route one of these to Part B's "not built yet" line, and never let Part A's empty search result stand as the answer — either would tell the advisor a working connector doesn't exist, which is false.

Tell them it ships with the plugin and say exactly where to go. Name it as their connector list does, or as the Step 4 picker does if the list couldn't be read.

> "[Tool]'s connector ships with this plugin, so there's nothing to install. You'll find it in your connector list — open the Connectors page in Settings, click **Connect** next to [Tool], and sign in with your [Tool] account. Once that's done I can pull from it directly whenever a skill needs it."

This holds when the session could not make the observations at all — no registry, no connector list, nothing found by name. That is the unknown case by definition, the whole selected set lands here, and the line above is still said as written, not hedged into "check whether it shows up" or "if it ships with the plugin you'd find it". The Convention's unknown row ("say you couldn't confirm its status") is written for a skill that needs the data mid-task; at this step nothing has been connected yet, so there was never a status to confirm, and a hedge sends the advisor to Settings unsure what they are looking for. Saying it ships with the plugin is not a guess about this session — the plugin registers it — and the case where it isn't in their list has its own line below.

If they come back and it isn't in their list, that is the observation the session was missing: say plainly that it isn't showing up, and offer the manual fallback per the Connector Placeholder Convention. Never improvise a URL for it — the plugin's own registration is what puts it there.

**Fallbacks:**
- If registry search returns `opt_in_required`, tell the advisor: "To let me suggest connectors, enable connector suggestions in your Claude settings — or you can connect tools directly from the Connectors page in Settings." Then continue the flow.
- If the advisor names a tool that has no connector anywhere and isn't part of the Claude for Financial Advisors lineup at all — a genuinely unlisted or custom in-house tool, not one of the tools handled by A–C above — mention briefly: they can tell their account manager at that vendor to begin creating an MCP, or set up a custom MCP themselves (MCP is an open standard that lets Claude securely talk to other software — https://modelcontextprotocol.io). If asked, give a plain-English explanation of MCP and walk them through setting up a custom one.

After presenting the connector panel, the direct-connection instructions, and/or any status lines, stop here — don't continue into Step 6 in the same message. Say something like: "Take your time — click **Connect** whenever you're ready, or just let me know when you want to keep going." Then wait for the advisor's next message before moving on. Rendering the panel is not the same as the advisor being done with it.

## Step 6: About the plugin

Once the advisor confirms they're ready to move on (they've clicked Connect, said they're done, or asked to continue) — not simply once Claude has finished describing their tools — check `ListConnectors` again to see what's actually connected now. Don't just assume based on having called `SuggestConnectors` earlier — the advisor may not have finished, or may have only connected some of what was suggested. Then deliver this script. Keep the paragraph breaks — short paragraphs with blank lines between them. The second paragraph depends on what that check shows:

Read that check on `enabledInChat` and `connected` per the Connector Placeholder Convention below, and pick **one** of these three. The third exists because the advisor was just told to click **Connect** — a flow they can leave part-way through, which is an ordinary thing to do and leaves a connector reporting neither connected nor absent.

- If at least one tool is now genuinely connected: "Thanks for connecting your tech stack — I can now see into [name the connected tools]. I won't take any action there unless you tell me to."
- **If a tool's status came back unknown, or it's connected but not enabled in this chat** — the signature of a connect flow that was started and not finished: name it and offer the next step, don't count it as unconnected. "It looks like [tool] didn't quite finish connecting — want to give that another go? I can wait." If they'd rather move on, say so warmly and continue; never make this a gate.
- If nothing is connected yet (none of the selected tools came back connected, whatever the reason): "Thanks for walking me through your tech stack — once your tools are connected, I'll be able to see into them and pull real data automatically."

**Step 6a — what a skill is, then ask:**

> "Now let me explain a bit about myself.
>
> I come pre-installed with a set of "skills." A skill is how you can have me complete entire workflows for you.
>
> For example, my pre-meeting skill builds a complete quarterly-review prep doc for any client you name — pulling together their history, holdings, and recent activity from your connected systems into a client snapshot, performance tables, planning opportunities, a time-boxed agenda, talking points, and draft action items. Something you can read in 10 minutes and walk into the meeting confident.
>
> Skills are also flexible — if you ever want one to work differently for you, just say so and I'll walk you through personalizing it.
>
> Want me to explain the [X] other skills in this plugin?"

Keep that example's sources generic on purpose — "their history, holdings, and recent activity from your connected systems," never "their CRM record, portfolio performance, and recent correspondence." Naming specific systems reads as a claim about *this advisor's* setup, and Step 5 may have just told them those very systems aren't connected yet. "Your connected systems" describes how the skill works rather than what this advisor happens to have, so it stays true either way and needs no connected/not-connected branch here. Don't substitute the names of whatever came back connected, either — that would reintroduce the branch this phrasing exists to avoid.

Calculate **[X]** — don't hardcode it, for the same reason the list itself is generated: it's the number of skills available in this plugin right now, minus onboarding and minus pre-meeting (already described just above, which is what makes the rest "other"). Count placeholder/"coming soon" skills in the total — they're still listed in 6b, so excluding them would promise fewer items than you go on to name.

End your turn here and wait for a real answer. This is a genuine offer, not a rhetorical lead-in to the list — asking and then reciting the list anyway in the same response is worse than not asking. Ask it as plain chat text, not AskUserQuestion; it's a yes/no aside, not another pop-up.

**Step 6b — the list, only if they said yes:**

- **If they say yes** (or otherwise signal interest): deliver the list per the rules below, then go to Step 7.
- **If they say no** (or "later," or "let's just get going"): skip the list entirely — don't summarize it, don't name a few highlights as a consolation — and go straight to Step 7. Don't treat the decline as something to talk them out of or circle back to.

If they said yes, open with:

> "Here is a full list of the skills in this plugin:"

Don't hardcode this list — generate it from the skills actually available to you in this plugin right now, so it stays accurate as skills get added, renamed, or removed. For each one:
- Name it as a slash command (`/<skill-name>`).
- Summarize what it does in one short, warm, benefit-focused sentence, in your own words — don't paste the skill's frontmatter `description` verbatim. That field is written dense and keyword-heavy for triggering purposes, not for a first-time advisor to read.
- If a skill's description flags it as a placeholder (e.g. starts with "PLACEHOLDER" or otherwise says it isn't built yet), list it as "coming soon" instead of describing capability it doesn't have.
- List pre-meeting first regardless of discovery order — it's the one you demo next in Step 7, so it should lead naturally into the invitation below.

If the advisor left any Step 4 tools unconnected (still on the roadmap, or connectable but not yet clicked), you may tease it here in one line — e.g., "Once the rest of your stack is connected, I'll be able to pull that data live instead of using examples." Keep it to a single sentence, don't repeat Step 5's status report, and skip this entirely if everything they selected is already connected.

Then hand off into Step 7 without waiting again, using the line that matches the branch you took:

- **If you delivered the list:** "Now that we have that covered, here's where I'd start..."
- **If they declined it:** "No problem — you can always ask me for the full list later. Here's where I'd start..."

Don't use the "now that we have that covered" line on the decline branch — nothing was covered, and it reads as though you recited the list anyway.

## Step 7: Live demo — pre-meeting

Offer the demo:

> "Give me a client name and we can do a quick meeting prep — or if you'd rather not use real client data on the first run, I can use a fictional sample client, **Jordan & Casey Miller**."

The answer decides the path — and the real-versus-fictional split below is a guardrail, not a formality:

- **A real client name → execute the `pre-meeting` skill end to end** so they see a real deliverable against their own data. Where connectors aren't yet live, the placeholder convention below will kick in — that's expected and is itself a useful preview. (If the advisor typed /pre-meeting with a client name, that skill handles it.)
- **The fictional Millers → the demo stays entirely inside this skill.** Never invoke `pre-meeting` — or any other skill — with a fictional client, and never query any connected system for the Millers. Other skills treat every household name as a real client (searching for it, disambiguating it, refusing to fabricate about it); that is a guardrail, not an inconvenience, and a fake name doesn't go through it. Don't search connected systems for the Millers, and never offer a real household as a substitute — the advisor chose the fictional client precisely to keep real client data out of the first run. Instead, present the sample prep document at `references/miller-demo.md` (in this skill's folder) as the deliverable, walking through it in the same voice `pre-meeting` would use. Where the advisor connected systems in Step 5, you may note in-line "on a real client, this section pulls live from [system]" — but read nothing from those systems for this demo.
- **Not interested in a demo → skip straight to Step 8, politely.** One warm line ("No problem."), no talking them out of it, no consolation demo.

## Step 8: Closing recommendation

Based on their Step 3 headaches (and what you learned about their RIA in Step 2), suggest the single next skill most likely to save them time this week (e.g., if they picked "Compliance and paperwork," suggest trying /compliance on a real draft email).

Three of Step 3's options map to a pair of skills, so pick the one within the pair that best fits what you learned in Step 2 and what they actually connected in Step 5: meetings → `/pre-meeting` vs. `/post-meeting` on which side of the meeting they described; portfolios → `/portfolio-rebalance-review` vs. `/alts-brief` on whether an alts platform came up in Step 4b; data wrangling → `/prospect-intake` vs. `/estate-and-tax-brief` on growth signals from Step 2 vs. a planning tool in Step 4d. Don't name the option back to them, and don't offer two.

## Connector Placeholder Convention (applies to every Claude for Financial Advisors skill)

The canonical list of systems this plugin supports (or is building toward) lives in onboarding's Step 4 — that's the actual source of truth, not this section. Some of those connectors are still being built. In any Claude for Financial Advisors skill, when a step calls for data from one of those systems:

1. **Look for the tools first — that is the check that decides.** Use `ToolSearch` with the system's own name (Orion, Gmail, Wealthbox). If its tools come back, the system is connected and callable: use them and move on. Don't guess at a tool-name prefix like `mcp__orion__*`; real connector tool names use opaque, unpredictable prefixes, not clean names based on the system, which is why searching by name is the only reliable way to find them.

   **This ordering is deliberate.** The registry can answer *"No installed connectors found"* even in a session with several live, working connectors. Followed literally, that answer would declare every system unavailable and degrade the entire session to manual fallback. The tools you can actually see are a direct observation; the registry is a report about them, and in some clients it renders a user-facing card rather than returning data at all.

2. **`ListConnectors` explains a gap; it never establishes one.** Once you know from the search above that a system's tools are missing, call `ListConnectors` (load via `ToolSearch` if it isn't already available) to find out *why*, so the advisor gets a useful sentence instead of a shrug.

   **An empty result means unknown, never "nothing is connected."** So does a result that renders a card instead of returning data. Neither is evidence of disconnection, and neither may be used to trigger the placeholder wording below.

   **When it does return entries, read them on two fields, not one.** `ListConnectors` reports `connected` (authenticated at the org level) and `enabledInChat` (whether its tools are actually loaded in this session), and they disagree often enough to matter. There are three outcomes, and each has a different thing to say:

   | What comes back | What it means | What to do |
   |---|---|---|
   | `enabledInChat: true` | Its tools are loaded and callable now. | Nothing to explain — step 1's search should already have found them. If it did not, search again by the system's name. |
   | `connected: true`, `enabledInChat: false` | Authenticated, but switched **off for this chat**. Its tools are not loaded, so a `ToolSearch` will find nothing. | Tell the advisor it's connected but not enabled here, and that they can turn it on in this chat's connector settings. **Do not** say it isn't connected, and do not offer the placeholder wording below. |
   | `connected` absent or `null` | **Unknown**, not disconnected — the status check was unavailable. | Say you couldn't confirm its status rather than asserting it isn't connected. Then offer the manual fallback in step 3. |

   Never read a missing `connected` as `false`, and never decide a system is unusable from `connected` alone. `enabledInChat` is what governs whether you can call anything.

3. **If the connector genuinely isn't there** — not installed, or a system this plugin is still building toward — say so transparently, in-line at that step:
   > "This is where I'd make a call out to [the system] to pull [the specific data] once that connector is built."

   Only use that wording when it's true. For a connector that exists but is switched off, or whose status is unknown, it misdescribes the advisor's own setup and sends them looking for a feature that already shipped.
4. Then **offer the manual fallback**: the advisor can paste the data, upload an export (CSV/PDF/screenshot), or skip the section. Continue the workflow with whatever they provide — never dead-end.

## Ask-Once, Then Route Convention (applies to every Claude for Financial Advisors skill)

Sometimes two connected tools can try to solve the same problem for the advisor. That overlap isn't defined by the tools being the same kind — two CRMs, two portfolio platforms, two alts platforms are the common case in this plugin today, but a CRM and a portfolio platform (or any other pairing) can overlap just as easily if both happen to hold the same fact. What matters is whether they'd give the advisor different answers to the same problem, not what category each tool falls in. When that happens, every skill follows the same rule:

1. **Resolve the household first**, per that skill's own Disambiguation Rule. This convention starts only once the household itself is disambiguated — an unresolved household is never a reason to skip the book-of-record question once it does resolve, and never a license to query every candidate system while waiting on one.
2. **If exactly one of the relevant systems is connected, use it** — there's nothing to ask.
3. **If more than one is connected, ask the advisor once, before pulling or merging anything, which is the book of record for this household.** Never guess, never default to whichever answers first, and never silently merge two systems' answers into one undifferentiated view. Name the systems in the question ("Orion or Addepar — which is the book of record for the Harrington household?").
4. **Route there for the rest of the session**, for this household, once they answer.
5. **Offer to help the advisor save the choice using the Personalization Convention** (the standing-preference paste below) so they aren't asked again next session for the same household.

This is a per-household choice, not a firm-wide setting, so the question belongs in-skill, at the first step that hits the overlap — **never during onboarding**: at that point neither which households have overlapping data nor which connectors the advisor will finish connecting is known yet.

This governs *which system to trust when more than one tool could try to solve the same problem*, not *which entity the data is about*. A skill that shows the same figure from two systems side by side, each labeled with its source, because the two aren't expected to agree, is answering a different question and is not an exception to this rule.

**The overlap can surface at any point, not just at the start of a step.** Treat any source that could hold the same kind of information as one already in play as an overlap — including a source the advisor mentions on the fly ("I also have notes in X"), not just a second system already named in this skill. This check isn't one-time: re-run it whenever a new source enters the conversation, even mid-gathering. Before merging its content in, stop and ask which is authoritative for that content type.

### Material conflicts block the output

Separately: if two sources are pulled anyway — an exception like alts-brief's label-both handling, or an overlap that wasn't caught in time — and they disagree on a material fact (a dollar figure, an allocation target, a date), do not resolve it narratively or present both as a footnote. Stop and surface the conflict to the advisor as a blocking question before the document is finalized, the same way the Disambiguation Rule blocks on a name collision.

### Standing-preference paste

Once the advisor answers, offer to save it the same way the Personalization Convention below saves any other preference — tell them where to go and write the exact text to paste:

> Want me to remember that for [household] so I don't ask again? Paste this into **Settings → General → Instructions for Claude**:
>
> For the [household] household, treat [system] as the book of record for [data type]. Don't ask me to choose again for this household.

Never write to those settings on the advisor's behalf — Claude has no ability to.

## Magnitude-Conflict Convention (applies to every Claude for Financial Advisors skill)

Ask-Once decides *where to read*; this rule governs *what may be quoted*. When two connected systems return the same household or account at figures that disagree by orders of magnitude, the outlier is a data conflict, not evidence:

- **Name the conflict in the deliverable** — both figures, both sources, one line saying they cannot both be right.
- **Exclude the outlier's figures from every table and total.** A number flagged as wildly inconsistent doesn't earn a row by being flagged; quoted-with-a-caveat still reads as evidence.
- **Confirm with the advisor which record is real** before any follow-up relies on either.

The common cause is a placeholder or sample household — a near-empty book under a real client's name in a system the advisor didn't name as book of record. Those stubs are nobody's data: never source a figure from a household the advisor hasn't confirmed as theirs, even when a name search returns it first.

## Personalization Convention (applies to every Claude for Financial Advisors skill)

Claude cannot write to the advisor's settings — when an advisor asks to personalize how a skill behaves (e.g., "always skip the executive summary," "use tables instead of bullet points," "never suggest alts for accounts under $1M"), walk them through doing it themselves:

1. Tell them exactly where to go: **Settings → General → Instructions for Claude.**
2. Write the exact markdown for them to paste — scoped to the specific skill(s) and behavior they asked to change, short (a bullet or two, not a paragraph). These instructions persist across every conversation, not just this plugin, so don't write anything broader than what they actually asked for.
3. Never claim to have made the change yourself, and never write to those settings on their behalf — Claude has no ability to.

## Important Notes

- Keep the tone warm and unhurried — this is likely the advisor's first experience with Claude doing real work.
- Break every long scripted block into small paragraphs with blank lines between them — no walls of text.
- Never ask for client PII during onboarding beyond what the advisor volunteers.
- If the advisor wants to skip ahead at any point, let them — onboarding is a guide, not a gate.
- Anything the advisor shares about their clients or their firm during onboarding is confidential — treat it that way.
- Never fabricate connector status, skill capabilities, or demo data. If a connector isn't connected, say so and offer paste/skip (see Connector Placeholder Convention); if a skill can't do something, say so plainly instead of describing capability it doesn't have.
- Don't ask "should I start?" once the advisor has invoked onboarding — narrate and go. (Writes and sends still need the advisor's approval — this is about not stalling on unnecessary permission-to-begin questions, not about skipping real approval steps.)$body$),
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/portfolio-rebalance-review', 'finance', 'portfolio-rebalance-review', '', 'portfolio-rebalance-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Portfolio Rebalance Review

Review a client portfolio end to end: performance → drift → model mapping → rebalance prep → rebalance rationale memo.

## Inputs

Required: **client/household name**. Optional: which accounts to include, the model portfolio or IPS targets (if not on file), and whether the advisor wants analysis only or a full rebalance prep.

## Step 1: Pull Performance & Holdings

**Disambiguation rule:** confirm which household before pulling anything, the same as every other skill in this plugin — if a name search returns more than one match, show the advisor the candidates and ask which one before proceeding. Never proceed on a name match alone.

Query the household's connected portfolio-data system for:
- Accounts with registrations (taxable, IRA, Roth, 401k, trust) and market values
- Holdings with quantity, market value, cost basis, and unrealized gain/loss
- Performance: QTD/YTD/1yr/3yr vs. assigned benchmark, net of fees
- Assigned model/target allocation and cash balances
- Recent flows (contributions, distributions, RMD status)

**Which system to query:** this data can live in Orion, Addepar, or Envestnet/Tamarac depending on the firm. Check `ListConnectors` (load via `ToolSearch` if not already available) to see which is actually connected — don't guess at tool-name prefixes, use `ToolSearch` by system name once you know which is live.

**Look for the tools before you trust the registry.** `ToolSearch` by the system's own name is the check that decides: if its tools come back, that system is connected and callable — use them. `ListConnectors` can answer "No installed connectors found" even in a session with several live, working connectors, and in some clients it renders a user-facing card rather than returning data at all. So it explains a gap, it never establishes one, and an empty result means **unknown**, never "nothing is connected". When it does return entries, read `enabledInChat`, not `connected`: `connected: true` with `enabledInChat: false` is authenticated but switched off for this chat, so tell the advisor they can enable it here rather than reporting it as unconnected; a missing or `null` `connected` is unknown, not disconnected.
- **If none is connected**: follow the Connector Placeholder Convention — say *"This is where I'd make a call out to [system] to pull [holdings/performance] once that connector is built,"* then offer the fallback. Before asking for a manual upload, offer to search Google Drive (if connected) for an existing export or statement. If nothing turns up there either, ask the advisor to upload an export (CSV/PDF), a custodian statement, or paste holdings. Continue with whatever's provided, and mark anything still missing "— pending [connector]" rather than leaving it blank — a missing source degrades only the section that depends on it, not the whole review.
- **If more than one connected tool could try to solve this for the household**, ask the advisor once which is the book of record — per the Ask-Once, Then Route Convention — rather than guessing or merging both, and use that system for the rest of this review. This applies even when the household name hasn't resolved against either system yet: ask before searching further, not after finding out neither recognizes the name — an unresolved household is not an exception to this rule. Offer to help the advisor save the choice using the Personalization Convention so they aren't asked again next session. This check runs for the rest of the review, not just once up front — if the advisor brings up another source mid-review, ask before pulling from it too. And if a second system's figures get pulled anyway and disagree with the routed one on a material fact (a balance, a drift percentage), that's a blocking question for the advisor, not a note in the output.

**Held-away accounts:** ask the advisor whether the household has accounts held away from this system (a spouse's 401k, assets at another custodian) relevant to wash-sale coordination or the overall allocation picture. If yes, request those holdings manually — there's no connector for outside accounts.

**Addepar specifics:** call `get_portfolio_data` with `lookthrough=false` for drift purposes. Lookthrough decomposition (fund → underlying constituents) is a separate risk-review lens — an IPS names sleeves at the fund-commitment level, and lookthrough silently returns an incompatible set of buckets with no warning. Group by `direct_owner`, not `account` — the latter is not a valid grouping key and errors. For tax-lot detail, pass a tax-lot value in `groupings` only if the live tool schema actually documents one — cost basis and lot-level fields are not confirmed to exist on every Addepar deployment. If the schema doesn't support it or the returned columns don't include cost basis, say so explicitly rather than presenting fabricated lot data; this feeds the same "Completeness" gate below.

**Orion specifics:** Orion Connect's tools (household search, report catalog, report parameters, `oc_generate_report`) are identity and report-catalog/generation only — they do not return structured holdings, cost basis, or tax lots. Generating a report yields a **link to the finished report**, not its contents — hand it to the advisor and say it **expires after 24 hours** (a unique per-run URL; regenerate rather than troubleshoot an expired one); don't fetch it to scrape a holdings table out of, and don't treat having produced a link as having read the data. If Orion is the only connected system, holdings/cost-basis data has to come from the advisor (upload/paste) rather than being inferred from a report. If Orion later ships a structured holdings or cost-basis tool, wire it into this same Step 1 data shape alongside Addepar.

**Before generating an Orion report:** confirm with the advisor first — `oc_generate_report` runs a job in Orion Connect rather than reading from it. No confirmation is needed for household search, the report catalog, or report-parameter lookups; those are identity/catalog calls, not report generation.

**Data-sanity gate — run before Step 2, don't skip.** Dispatch this to the `claude-for-financial-advisors:holdings-sanity` subagent — `Agent(claude-for-financial-advisors:holdings-sanity)` — rather than working through it inline: hand it the holdings data, the reported portfolio/household value, and the sleeve structure from the IPS or model if one is on file. It returns a flag table with a `Contaminates` column naming which downstream figure each problem feeds, plus an explicit list of the checks that passed.

Act on what comes back before touching Step 2. A `BLOCKING` verdict means a flag would corrupt the drift table itself — resolve it with the advisor first. `FLAGS` means the review continues with the caveats carried into the output. The subagent never repairs data, drops a position, or estimates a missing field, so anything it raises is still yours to decide about.

The seven checks it runs, which are also the checks to run by hand if the subagent is unavailable:
- **Temporal:** flag any position whose valuation date precedes its first funding/contribution transaction.
- **Magnitude:** flag any position whose gain looks implausible for the asset type and time held (e.g. a private fund up several multiples within months of being funded) and confirm the mark with the advisor before using it.
- **Aggregation:** flag any sleeve or household-level return that's materially inconsistent with the sum of its parts (one position driving the whole household return while everything else is flat/negative is a signal, not a fact).
- **Reconciliation:** reconcile the holdings total against the reported portfolio value.
- **Completeness:** flag any position missing a field a later step depends on — cost basis, quantity, or an asset-class/sleeve tag — rather than silently excluding it from drift or tax calculations.
- **Staleness:** flag when a mark's as-of date is materially older than the rest of the portfolio it's being compared against (common for private/illiquid holdings priced less often than public ones) — note the mismatch rather than treating all "Current %" figures as equally current.
- **Duplication:** flag if the same underlying exposure may be represented more than once — e.g. a fund-level position and its lookthrough decomposition both pulled into the same table, or a held-away account that turns out to already be visible through the primary connector.
- If anything trips, say so explicitly and state which downstream conclusions (drift %, performance %) depend on the suspect figure — never let a bad mark flow silently into the drift table.

## Step 2: Drift Analysis

Compare current allocation to the IPS targets / assigned model. **Sourcing the target:**

- **IPS on file — the IPS governs.** Prefer pulling it from the connected system of record if one exposes it as structured data; today no connected system does (Addepar has IPS/target bands in-product but doesn't expose them over MCP yet), so ask the advisor for target bands or accept a pasted IPS — this instruction upgrades automatically once a connector exposes IPS data. A BlackRock model is comparison material for Step 3 here, never a substitute target.
- **Household managed to an assigned model** (per Step 1's pull or the advisor naming one): if BlackRock Advisor Center is connected (Step 3's connection check) and the assignment matches its lineup (`list_models` — which also carries the firm's entitled third-party models), hydrate the target from `get_model`: roll its holdings up by their `asset_class` tags into sleeve targets and carry the model's `as_of` date into the drift table. The model supplies point targets only, never bands — bands stay firm/IPS policy; ask if unknown.
- **No target on file:** if Advisor Center is connected, offer its lineup rather than improvising — show candidate families and risk profiles and let the advisor pick; never select a model or a risk profile for them. Label the drift table and every figure derived from it *"vs. advisor-selected illustrative model [name] — not a client IPS"*, and carry that label into the memo and the client-facing summary. If they decline, or it isn't connected, ask for target bands as above.

Source sleeve names, targets, and bands from whatever IPS/model you end up with — don't assume a fixed set of asset classes. Fall back to the table below only when no IPS/model sleeve structure is on file:

| Asset Class | Target % | Current % | Drift | $ Over/Under |
|------------|----------|-----------|-------|-------------|
| US Large Cap Equity | | | | |
| US Small/Mid Cap | | | | |
| International Developed | | | | |
| Emerging Markets | | | | |
| Investment Grade Bonds | | | | |
| High Yield / Credit | | | | |
| Alternatives | | | | |
| Cash | | | | |

Flag positions exceeding the rebalancing band (default ±5% absolute or the firm's stated band — ask if unknown). **Bands may differ by liquidity tier** — illiquid sleeves (private equity, venture, real assets) typically carry a wider band than liquid ones; use what the IPS specifies, ask if it doesn't distinguish. A breach in an illiquid sleeve is a commitment-pacing signal, not a trade instruction — it can't be traded back — so surface it as context rather than generating a change against it.

Also flag: concentrated single positions (>10% of household), cash drag, and style drift within an asset class.

**IPS review cadence:** check the IPS's own "last reviewed" date against the firm's stated review cadence. If none is on file, default to flagging anything not reviewed in the last 12 months (a common industry norm for fiduciary accounts) and ask the advisor for the firm's actual policy — same pattern as the band default above. Note staleness alongside the drift table; don't block the rebalance on it.

**Analysis-only path:** if the advisor asked for analysis only (see Inputs), stop here — output the drift analysis and the plain-English summary from Step 6, and skip Steps 3–5.

## Step 3: Model-Portfolio Mapping

**Which model source:** check for BlackRock Advisor Center the same way Step 1
checks for a portfolio-data system — `ToolSearch` by name first (never guess
an `mcp__blackrock__*` prefix), `ListConnectors` only to explain a gap, and
read `enabledInChat` rather than `connected`. If it's connected, source the
model lineup from `list_models` and the chosen model's holdings from
`get_model`. If it isn't, work from the model definition the advisor supplies
— and if none is supplied, say so and skip the mapping rather than scoring
against an assumed model. **A BlackRock model is not automatically the drift
target** — when the household has its own IPS, models feed only this step's
mapping. When Step 2 sourced the target from an assigned or advisor-selected
model, score against that same model here, never a different one.

**Advisor Center's MCP doesn't expose synced client accounts today:** its
"households" are proposal groupings, and accounts imported or synced from the
book of business aren't readable over MCP yet — so don't look a client
household up there; this instruction upgrades automatically once the MCP
exposes synced accounts. Independent of that: never offer to create or update
anything there — `create_portfolio` and every other Advisor Center write is
out of scope for this skill.

**Terms gate:** a `[terms_not_acknowledged]` or `[terms_unavailable]` refusal
from any BlackRock call means the advisor hasn't accepted (or needs to
re-accept) Advisor Center's terms. Call `show_terms` and present the terms
text in full — never summarized or paraphrased. Once the advisor explicitly
accepts, call `acknowledge_terms` with `displayed_hash` set to `show_terms`'s
`content_hash`, then retry the original call. Never call `show_terms` or
`acknowledge_terms` on your own initiative or as a routine check — only on an
actual refusal, or if the advisor asks about terms directly.

- If the household is assigned a model, score current holdings against it: matched positions, close substitutes, and orphan positions.
- If no model is assigned, propose the best-fit model — from BlackRock's lineup when connected, otherwise ask the advisor for the firm's lineup or use standard risk-based sleeves: Conservative 30/70 → Aggressive 90/10 — and show the gap analysis. Present any BlackRock-sourced model or fund suggestion as an option Advisor Center is offering, not as Claude's own recommendation.
- Output a mapping table: current holding → model position → action (hold / substitute / sell).

## Step 4: Rebalance Prep

Identify the adjustments that would bring the household back to target, tax-aware:
- Rebalance in tax-advantaged accounts first (no tax consequences). If the household has none, say so explicitly in the options list and memo rather than silently skipping this.
- In taxable accounts: avoid realizing large short-term gains; harvest available losses while rebalancing; watch wash sales (30-day window, across every household account whose holdings and transaction history you **actually gathered** — being connected is not the same as being gathered: a held-away account the advisor confirmed exists but never supplied holdings for sits outside that check, and so does a connected account whose feed returned no cost basis or tax-lot detail, the gap Step 1's Addepar note and Completeness check already record). Where the check couldn't reach the whole household, say so plainly: name the accounts it covered and the ones it didn't, and carry that same scope into the memo's wash-sale line rather than a bare "yes".
- Check RMD status before an IRA sell appears in the options — don't create a distribution shortfall, and prefer using an already-required RMD as the funding source for a needed sale over an unrelated one.
- For a concentrated position with a large embedded gain, weigh trimming against the client's likely holding horizon: selling now forfeits any step-up in basis at death. For an elderly or terminally-ill client this is a real tradeoff to reason through and document, not a default "trim because it's outside the band."
- Prefer directing pending contributions/cash to underweights over selling
- Respect client restrictions (ESG screens, concentrated/legacy stock, lockups)

**Cash locked for capital calls (alts path):** if Addepar is the connected system, call its upcoming private-fund capital-activity tool before treating cash balances as available — net out committed-but-uncalled capital-call obligations from what counts as deployable cash, same as an illiquid-sleeve band breach is a pacing signal rather than a trade instruction. Surface any near-term call as a flag/context line next to the cash figures it affects, don't silently consume it into the options list. No connected system currently supplies forward-looking call dates for Orion/Envestnet-only households — note that gap rather than guessing.

**Zocks AI results as a rebalance-rationale input:** if Zocks is connected, pull its AI results/insights for the household and check whether the potential changes line up with what the client has actually expressed — stated risk tolerance, life events — and with the IPS on file. Flag a mismatch inline against the specific change it bears on (e.g. a risky change against an explicitly stated low risk tolerance, or a life event suggesting the IPS itself may be stale), not as a general blurb at the top of the output. Zocks is a sentiment/context source, never a portfolio book of record.

**Execution feasibility check** before finalizing the options list — flag, don't silently assume:
- Odd lots: if a computed share count isn't a round lot, note it and suggest rounding to the nearest round lot or a dollar-based order.
- Mutual funds: flag that the order is subject to the fund's minimum and daily NAV cutoff — tell the advisor to confirm both with the custodian/fund company, don't assume a number.
- Less-liquid ETFs (international, high-yield, muni): flag that premium/discount to NAV should be checked at time of trade.
- Trading the same security across many households at once (block trading) is out of scope for this skill's single-household design — note it as a known limitation, don't attempt to aggregate.

**Rebalancing options:**

| Account | Action | Security | Shares/$ | Reason | Est. Tax Impact |
|---------|--------|----------|----------|--------|-----------------|

Include totals: estimated realized gains/losses, transaction costs, and before/after drift.

**Execution note:** this skill *lays out rebalancing options*; it never executes anything. Once custodian connectors (e.g., Schwab) support order staging, offer to stage the order file — until then say: *"This is where I'd stage these orders to [Schwab/custodian] once that connector is built"* and output the options list in the custodian's upload format if known.

## Step 5: Rebalance Rationale Memo

Every rebalance gets a memo for the compliance file. Use `templates/rebalance-rationale-memo.md` in this skill's folder. It must state: client objective/IPS reference, what drifted and why, what is being changed and why each adjustment serves the client's interest, tax impact considered, and alternatives considered. Leave the template's Approval table empty — nothing in this review establishes who approved a change, and the advisor and any reviewer the firm requires sign for themselves. Never fill in a name or a date there, and never describe the memo as approved.

## Step 6: Output

Write everything to a markdown file first:
- Drift analysis table + before/after allocation comparison
- Rebalancing options with tax impact summary
- Model mapping table (if Step 3 ran)
- Rebalance rationale memo (using `templates/rebalance-rationale-memo.md`)
- 3-sentence plain-English summary the advisor could relay to the client

Then ask the advisor whether they'd like the options list exported to Excel and/or the rationale memo converted to Word/PDF — don't create those formats unless they ask.

## Out of Scope (for now)

- **No trade execution.** This skill prepares options for advisor review; it never places an order.
- **No fabricating holdings, lots, or cost basis.** When a connected source doesn't confirm a figure, say so — never fill the gap with an invented number.
- **No suitability or legal determination.** This skill surfaces drift, tax impact, and rationale for the advisor to weigh — it never states that a portfolio is or isn't suitable.

## Important Notes

- This review can take a few minutes once portfolio data starts flowing across steps — say so up front rather than asking whether to proceed; invoking the skill is already the go-ahead.
- Don't rebalance for rebalancing's sake — drift within bands is fine; tax costs can exceed the benefit. Show the breakeven when it's close.
- Check pending cash flows (contributions, withdrawals, RMDs) before a sell appears in the options.
- All buy/sell output is **a draft for advisor review — options laid out for the advisor to weigh, not advice** — the advisor owns suitability and best execution.
- Document everything: the rationale memo is a books-and-records item; run any client-facing summary through **/compliance**.
- Coordinate wash sales across every household account whose holdings and tax-lot detail you actually gathered — a held-away account once the advisor supplies its holdings, a connected account once its feed actually returns cost basis — and say so when the check couldn't cover them all.
- Treat client portfolio and account data as confidential; only include what's needed for this review.$body$),
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/post-meeting', 'finance', 'post-meeting', '', 'post-meeting', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Post Meeting

Turn a client meeting into a CRM note plus a confirmed set of follow-ups and opportunities — the write-up, to-do chasing, and opportunity-spotting advisors would otherwise do by hand, done for them, with the advisor approving every write before it happens. This is next-best-action: doing the follow-up, not drafting an email for the advisor to send. If the advisor wants something sent to the client, that goes through `/compliance` — this skill's default path is the CRM, not a client-facing message.

## Inputs

Required: **the meeting itself** — identified by household/client name, or by whatever meeting metadata a connected source supplies. Pull the meeting's content in this order, stopping at the first that's available:

1. **Zocks AI results** — the meeting's AI-generated summary and extracted items, if Zocks is connected. Fall back to the raw transcript (also from Zocks) for direct quotes when the summary is ambiguous about wording.
2. **Wealthbox meeting summary** — when Zocks isn't connected, Wealthbox's notetaker exposes a summary of the meeting (not a raw transcript). Use it as-is.
3. **Pasted transcript** — if neither connector is available, ask the advisor to paste the transcript.

Zoom is not a supported source yet — do not offer it or imply it's coming.

Infer the household and the meeting date rather than asking by default: from the transcript itself, from Zocks meeting metadata (date and meeting ID, when present), or from the advisor's connected calendar. Only ask the advisor to identify the household or supply a date if none of those resolve it — never show a date picker as a first resort. Once you've inferred a date, put it on the note preview in Step 2 so the advisor can correct it if it's wrong.

Once the household and meeting are identified, don't ask "should I start?" — pull the meeting content per the waterfall above and go. The approval gate in this skill is on the write batch in Step 4, not on starting the work.

## Workflow

### 1. Identify the household

Query the household's CRM by the client/household name. **If more than one connected tool could try to solve this for the household**, ask the advisor once which is the book of record — per the Ask-Once, Then Route Convention — rather than guessing, and use that one for the rest of this workflow, including the Step 5 write. Offer to help the advisor save the choice using the Personalization Convention so they aren't asked again next session. If the advisor mentions a second CRM or notes source later in the workflow, that's the same question again before anything from it gets merged in — and if two sources ever disagree on a material fact, stop and ask rather than writing a footnoted or averaged version back to the CRM.

**Disambiguation rule:** never proceed on a name match alone. If more than one household matches, show the advisor the candidates (name + household + masked email or last-activity date) and ask which one is correct before touching any record — logging a meeting against the wrong household is a privacy incident, not a minor mistake. Confirm identity even on a single match if anything about the context (household, recent activity) doesn't line up with what the advisor said.

Follow the **Connector Placeholder Convention**: if the CRM's tools aren't available in this session, say "This is where I'd search [system] for this household once that connector is built," then ask the advisor to confirm the household manually and continue.

Whatever the CRM record turns up here — prior notes, open tasks, past meetings — is auxiliary context for identifying the household and spotting duplicates in Step 3. It is never the source of *this* meeting's content; that always comes from the waterfall in Inputs above, with Zocks AI results as the primary source when connected.

### 2. Draft the meeting note

Draft the note (the meeting content pulled via the Inputs waterfall, plus the inferred meeting date/type) and show the advisor what will be written, with the inferred date called out so it's easy to correct. Getting this right before writing matters more here than for most writes — CRM notes are never edited in place, only replaced by deleting and recreating them.

### 3. Identify action items and opportunities

Read the meeting content for two distinct things and list them back to the advisor separately:

- **Action items** — commitments the advisor made or next steps that were agreed to (e.g., "I'll send the updated plan," "let's set up a call about the 529").
- **Opportunities** — things mentioned in passing that could grow or protect the relationship (e.g., "a CD maturing next month," "mentioned an inheritance," "unhappy with a held-away account"). These are signals from *this meeting only*, not a full CRM opportunity review — call out that a deeper look (a dedicated opportunity-review pass) is a separate step if the advisor wants one.

Only include things actually said in the meeting content — never infer a commitment or opportunity that isn't there, and label anything uncertain as a possibility rather than a fact.

**Dup-check before proposing writes:** Zocks (the product, separately from its MCP) may already export its own summaries, tasks, and opportunities into the CRM. Check the CRM for tasks/opportunities already logged against this household around the meeting date — **at both grains, the household record's own items and each person contact's** (household-linked items are invisible to contact-only lookups) — before drafting new ones, and drop anything that's already there rather than proposing a duplicate.

### 4. Show the batch for approval

Present everything from Steps 2–3 as **one schema-shaped table**, not prose, and ask for a single confirmation on the whole batch rather than approving items one by one:

| Type | What | When | Who | Notes |
|---|---|---|---|---|
| Note | (note preview, with inferred date) | meeting date | household | — |
| Task | action item text | due/target date if known | owner (usually the advisor) | — |
| Opportunity | opportunity description | — | — | any metadata the connected CRM exposes (e.g. estimated size, stage) |

The advisor can approve all, some, or edited versions of any row.

### 5. Write what's approved

For whichever rows the advisor approves, create the corresponding CRM record using that CRM's own entities — Wealthbox's Note/Task/Opportunity objects, or Redtail's note/activity/opportunity calls — rather than assuming a generic mapping (e.g. Salesforce custom fields) that may not exist for the connected system. Confirm back with a short summary of what was logged.

### 6. Offer to file the record in Drive

After the CRM writes are done, if Drive is connected, offer to file the meeting record (as markdown) there too. If Drive isn't connected, skip this step silently — never hold up the CRM writes on it.

## Output

- The meeting note, action items, and opportunities are written directly to the CRM per the approved batch — that's this skill's primary output, not a document.
- If filing the record to Drive, file it as markdown. Don't create a `.docx`/`.pdf`/`.xlsx` version unless the advisor asks for one.

## Out of Scope (for now)

- **Creating a new household/contact** when no match is found — flag it to the advisor instead.
- **Editing any existing contact field** (name, address, etc.) noticed in the meeting content — flag it instead.
- **A full opportunity-analysis pass** against existing CRM records — this skill only surfaces what's in this meeting.
- **Sending anything to the client.** If the advisor wants to send a follow-up message, route it through `/compliance` — this skill's default path is the CRM, not a client email.
- **Trade execution.**

## Important Notes

- **Every write pauses for advisor approval**, gated through the single batch in Step 4. Never create anything the advisor hasn't seen and confirmed.
- **Never fabricate** meeting content, action items, opportunities, or client details. If the meeting content is ambiguous about whether something was a firm commitment or a real opportunity, ask rather than assume.
- **Treat the meeting content as confidential client data** — it may contain financial, health, or family details beyond the meeting's stated purpose.$body$),
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/pre-meeting', 'finance', 'pre-meeting', '', 'pre-meeting', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Pre Meeting

Build a financial review prep document an advisor can read in 10 minutes and walk into the meeting confident.

## Inputs

Required: **household name and/or email address**, and the **timeframe** the review covers (quarterly, annual, or ad hoc). If either is missing, ask for both before doing anything else — default the timeframe to quarterly if the advisor doesn't care which.

Optional (ask only if ambiguous): meeting date/time, anything specific the advisor wants to cover.

## Data Gathering

Follow the **Connector Placeholder Convention**: before assuming a system below isn't connected, check `ListConnectors` (load via `ToolSearch` if it isn't already available) — don't guess at a tool-name prefix like `mcp__orion__*`, since real connector tool names use opaque prefixes. If it's connected, use `ToolSearch` (by system name) to find its actual tools. If it's not connected, say "This is where I'd make a call out to [system] to pull [data] once that connector is built," then offer the manual fallback (paste, upload an export, or skip) and keep going. Apply this to every source below, not just the first one that's missing — and if more than one connected tool could try to solve the same problem for this household (not necessarily two of the same kind), ask the advisor once which is the book of record, per the Ask-Once, Then Route Convention, rather than guessing, and offer to help them save the choice using the Personalization Convention. This gathering pass touches several systems in sequence, so the check isn't a one-time thing at the top: re-run it whenever a later source could answer something an earlier one already did, and if two sources you did pull disagree on a material fact, stop and surface it to the advisor as a blocking question before the brief is finalized rather than presenting both. If the disagreement is by orders of magnitude for the same household, follow the Magnitude-Conflict Convention: name the conflict, and exclude the outlier's figures from every table and total rather than quoting them as evidence.

**Look for the tools before you trust the registry.** `ToolSearch` by the system's own name is the check that decides: if its tools come back, that system is connected and callable — use them. `ListConnectors` can answer "No installed connectors found" even in a session with several live, working connectors, and in some clients it renders a user-facing card rather than returning data at all. So it explains a gap, it never establishes one, and an empty result means **unknown**, never "nothing is connected". When it does return entries, read `enabledInChat`, not `connected`: `connected: true` with `enabledInChat: false` is authenticated but switched off for this chat, so tell the advisor they can enable it here rather than reporting it as unconnected; a missing or `null` `connected` is unknown, not disconnected.

Once identity is confirmed, **pull from all connected sources in parallel** — one slow or missing source degrades only its own section of the doc, not the rest. Before starting this multi-source pull, tell the advisor what you're about to gather and why, so it doesn't look like a silent hang. And once the household and timeframe are known, don't ask "should I start?" — narrate what you're doing and go; approval gates in this skill apply only to format conversions and length changes at the end, not to starting the work.

**Dispatch the parallel pull as one `claude-for-financial-advisors:source-extract` subagent per source, all in a single message** — the Agent tool, `Agent(claude-for-financial-advisors:source-extract)`, one call per source in the same response so they run concurrently rather than one after another. Each dispatch hands over the household identity as you have it, the one system that subagent is to query, the field schema for that source (the bullet list under its heading below), and the window the timeframe implies — or, where a source reads current state and has no meaningful review window, a plain statement of that instead of a window. Each returns a filled schema block. Two reasons this is a subagent rather than a tool call you make yourself: the raw payloads — email threads, full holdings tables, an estate look-back — stay out of your context so you assemble the doc from six compact blocks instead of six raw dumps, and the extraction work for all six happens at once rather than sequentially in your own reasoning.

**You still own identity.** The subagents are instructed never to resolve it: a `claude-for-financial-advisors:source-extract` that finds several candidates or a mismatch returns `IDENTITY MISMATCH` with what it saw and stops. Handle that the way the disambiguation rule below says — show the advisor the candidates, confirm, re-dispatch. Verify the returned blocks agree on the household before assembling anything from them. Fanning the reads out does not move that responsibility; it stays with you.

A subagent that returns `NOT CONNECTED` is the Connector Placeholder Convention case. It won't offer the manual fallback itself — it isn't in the conversation with the advisor. You make that offer.

### 1. CRM — Salesforce (or Redtail/Wealthbox)
**Disambiguation rule:** query the CRM by name AND confirm identity before pulling anything. If multiple contacts match the name, show the advisor the candidates (name + masked email + account) and ask which household is theirs — common names will return coincidental matches, and pulling the wrong client's data into a prep doc is a privacy incident. Never proceed on a name match alone. When one candidate is a clearly better match (exact email match, most recent activity), pre-select it as the default choice in that prompt — the advisor still has to confirm it, never skip that step outright.

A recognizable or public-figure name that matches a connected CRM record is a household like any other — treat it accordingly and do not refuse, hedge, or ask for extra justification because the name is well-known. This is guidance for how you proceed, not content for the document: the prep doc itself should read exactly like any other household's, with no note, disclaimer, or aside about the name being recognizable.

Pull the household record:
- Notes/insight-type fields (freeform notes, comments) from the CRM record
- Household members, key dates (birthdays, RMD age, Medicare eligibility at 65, Social Security decision points)
- Open tasks/action items (structured task list) — **at both grains: the household record's own items and each person contact's.** A CRM household is often itself a record with its own id (Wealthbox's is a contact), and household-linked tasks are invisible to contact-only lookups
- Service history — recent requests, complaints, referrals given

### 2. Portfolio — Orion / Addepar / Envestnet-Tamarac
Pull household and per-account data: market values, performance vs. benchmark, allocation vs. target and drift, realized/unrealized gains, income and fees, cash balances and large flows for the review period.

**Orion Connect specifics:** its five newly-shipped tools (`oc_search_accounts`, `oc_get_current_value`, `oc_list_household_accounts`, `oc_get_household_address`, `oc_lookup_account_owner`) are read-only identity/AUM lookups only — household/account identity, current value, mailing address. They do **not** return holdings, performance vs. benchmark, allocation/drift, gains, fees, or flows; don't infer any of those from a current-value number. Use these five for household/account identity and AUM with no confirmation needed — they're fast reads, not report runs.

For holdings, performance, drift, gains, fees, or flows, fall back to Orion's existing report chain: `oc_search_households` → `oc_list_reports` → `oc_get_report_parameters` → `oc_generate_report`. That chain runs a job in Orion Connect rather than reading one, so confirm with the advisor before generating a report, say roughly what it will contain, and show progress/status copy while it runs rather than a silent wait. The generate step returns a **link to the finished report**, not the report's contents — hand the advisor the link, say what it is, and say it **expires after 24 hours** (a unique per-run URL); don't fetch it to extract figures from, and don't treat having produced a link as having read the data. If the advisor comes back to an expired link, regenerate the report (with the same confirm-first step) rather than troubleshooting the URL. If the report chain isn't live or doesn't return data for the period, degrade explicitly — state the AUM figure you do have and mark performance/drift/fees/flows "— pending Orion report," rather than presenting AUM as if it were the full portfolio picture.

Where the connector exposes reconciliation status (e.g. Envestnet/Tamarac's `getAccount` returning `reconciliationStatus` / `lastReconciliationDate`), pull and surface it — flag stale or unreconciled data before quoting balances built on it.

**Held-away alts check (lightweight):** if iCapital or Addepar is connected and isn't already this doc's portfolio source (Addepar-as-source already covers alts via lookthrough), run one cheap exposure check there — iCapital's `query_positions` by `account_name` resolves server-side but returns null account/fund names, so report a name-matched position count only, never a self-summed dollar total; Addepar's `search_entities` + one `get_exposure` by asset class returns platform-computed value/% per bucket — quote those rows as returned, don't re-aggregate them into an "alts total" of your own. Positions found → one line in the template, cited to the platform, pointing to `/alts-brief` for detail (no capital calls, lockups, or performance here). Alts are optional, so absence isn't a gap: no alts platform connected, or zero matches → **omit the line entirely, no "pending"**. The one line written without positions: platform connected but the check failed → "— alts coverage not checked; run /alts-brief if this household holds alternative investments".

### 3. Estate & Tax — Wealth.com
Pull an estate/tax look-back report: what changed since the last review (documents, titling, beneficiaries) and year-specific tax constants relevant to the household (contribution limits, RMD factors, and similar figures). Always cite these as reported by Wealth.com for the applicable tax year — never recompute or estimate a constant Claude wasn't given.

### 4. Meeting Notes — Zocks (or CRM notes as fallback)
There is no Zocks "prep" endpoint — Zocks' MCP only exposes atomized reads (contacts, meetings, per-meeting AI results, insights), not the finished brief its own product UI generates. Build the picture yourself:

- **Fan out, then dedupe.** Resolve the household's contacts, list their past meetings, then pull AI results/summaries per meeting. Per-meeting extractions repeat near-duplicate household/financial detail across meetings, and a long-standing household can return dozens of results and summaries — collapse those into one current picture instead of listing each copy.
- **Precedence, in order:** prefer Zocks' AI results/summaries over the raw transcript; use the transcript only when you need the client's own words verbatim (e.g., a direct quote), not as the default source; if Zocks isn't connected, or is connected but returns no contact/meetings for this household, fall back to whatever the CRM has logged from prior meetings — the common case is the latter, not a missing connector; only fall back further to a manual paste/upload if neither is available.
- **Default to summary-first.** Don't dump every `ai_results_*` payload for every meeting — pull summaries for the last 1-2 meetings by default. Treat a full extraction fan-out across more meetings as a deeper, slower pass and ask the advisor before spending that extra latency.
- **Household is a relationship, not a record.** Zocks has no household object — it's "the people who usually meet together." Treat the CRM's household record as the book of record and use Zocks only to color it; reconcile what a meeting extraction says against the CRM rather than treating any single meeting's extraction as authoritative.
- **One item, one row.** When a Zocks action item and a CRM task describe the same underlying thing (e.g. a Roth conversion analysis mentioned in a meeting and tracked as a CRM task), merge them into a single line using the CRM's status — never list it twice just because it showed up unresolved in Zocks and resolved in the CRM.
- **Cite the meeting**, by date (and meeting ID if the tool returns one), for anything sourced from Zocks — and never attribute a fact to a CRM or planning source that the Zocks MCP itself didn't return — its tools expose Zocks's own meeting data only, not the systems Zocks integrates with.
- **Layer firm-level Insights separately**, when the connector has an insights tool — firm-wide trending topics, sentiment, referral opportunities. That's distinct from "what changed for this household" and belongs in Talking Points (see below), not folded into Since We Last Met. A household-scoped insight or sentiment result from the same tool, tied to this client specifically, is a Relationship Signal, not a firm trend — route it there instead.
- **Relationship signals — source from insights and notes, not task fields.** Populate the Relationship Signals section from Zocks' AI results/summaries and insights (`insights_query_insights`, when the connector exposes it) first, then CRM freeform notes fields (meeting notes, "notes"/"comments" on the contact or household record) — never from CRM structured task/action-item fields. Task fields track what's due, not what's true about the relationship, and are used inconsistently across RIAs; a CRM with an empty task list can still have a rich notes field. This section should still populate from whichever of Zocks or CRM notes is available — it does not wait on both, and it never blocks on the task list being empty or unmaintained. If both Zocks and CRM notes are unavailable, mark the section "— pending Zocks / CRM connector" per the Connector Placeholder Convention rather than omitting it. Cite every signal the same way as above: date (and meeting ID if returned) for anything Zocks-sourced, the field name (e.g. "per CRM notes field") for anything CRM-sourced. A signal with no source behind it doesn't go in the doc.
- **This skill still writes the Proposed Agenda itself** from the gathered data — never call a Zocks-generated agenda/prep or its Default Prompts a substitute for that section.

### 5. Email — Gmail / Outlook (available today for most users)
Search correspondence with the household's email address over a window that follows the chosen timeframe — roughly the last 3-4 months for a quarterly review, ~12 months for an annual review, or whatever's appropriate for an ad hoc one. Extract:
- Open requests or questions the client is waiting on
- Commitments the advisor made ("I'll get you that Roth analysis")
- Life events mentioned (job change, new grandchild, home purchase, health, inheritance)
- Tone/sentiment — anything suggesting concern or dissatisfaction

### 6. Plan Snapshot — MoneyGuide
**This source has no review window.** It reads the household's plan as it stands right now, so the dispatch hands that fact over in the window's place — never a blank, and never the review timeframe, which would imply a lookback this source doesn't have.

**Identity stays inside this pull**, the same way every other source resolves its own system: the subagent searches MoneyGuide by surname — households are stored surname first and the search matches the start of the name — and returns `IDENTITY MISMATCH` with what it saw if several match or none do.

Pull:
- Net worth — total, assets, liabilities
- Probability of success — only when the household has a plan
- Each goal — name, initial expense, start year — only when the household has a plan
- The plan's last-updated date, which dates the plan without saying what changed in it

Quote every figure exactly as MoneyGuide returns it: the output is prose and already rounded, so never recompute, re-derive or re-round it, and never fill a gap with a figure of your own.

**No plan on file** is a normal, informative answer from a working connector, not a degraded read: net worth still comes back and still goes in the doc, while probability of success and goals are marked not applicable for this household rather than left blank. An absent probability of success is never rendered as zero and never dropped silently — and never marked pending either, which would send the advisor chasing a connector problem instead of reading the connector's honest answer.

## Assemble the Prep Doc

Use `templates/pre-meeting-template.md` in this skill's folder as the document skeleton. Fill every section; where data was unavailable, mark it "— pending [connector]" rather than leaving blanks silently.

The doc's sections, in order:
1. **Client Snapshot** — household, AUM, tenure, risk profile
2. **Relationship Signals** — client concerns/sentiment, life events, upcoming personal dates (birthdays, anniversaries, milestones), proactive talking points — each signal cited to its source
3. **Since We Last Met** — open action items from last meeting with assignee and status (mark "unknown — pending CRM" unless the CRM's own task list confirms done; never infer "done" from a meeting-notes source that doesn't report completion), notable correspondence
4. **Portfolio Review** — performance vs. benchmark table, top contributors/detractors, allocation drift table, cash position
5. **Planning Opportunities** — proactive items: rebalancing, tax-loss harvesting, Roth conversion window, RMD/QCD planning, 529 funding, beneficiary review, insurance gaps
6. **Proposed Agenda** — a 30-45 minute agenda with time boxes
7. **Talking Points & Anticipated Questions** — 3-5 talking points in plain English (portfolio/market-facing — personal talking points live in Relationship Signals); firm-level Insights/trends when available; likely client questions (especially about underperformance or markets) with suggested framing
8. **Action Items Draft** — pre-drafted next steps to confirm in the meeting

This skill never computes or invents a plan probability, funded status, or Monte Carlo result — MoneyGuide's own net worth, probability of success and goals go under Planning Opportunities as color, quoted exactly as they came back, never as a plan section of their own.

## Output

- Write the prep doc as a markdown file first. One page-ish summary up front, supporting tables behind it.
- Keep language client-friendly — the advisor may screen-share parts of it.
- After writing the markdown file, ask the advisor whether they'd like it converted to .docx or .pdf (via the docx skill) — don't create either format unless they ask. Also ask whether they'd like the doc longer or shorter, and revise if so.
- End the chat response with 2-3 sentence "if you only read one thing" summary of the client's situation.

## Out of Scope (for now)

- **No trade execution.** This skill never places, stages, or confirms a trade.
- **No sending to the client.** The prep doc is for the advisor; sharing it is the advisor's call, through their normal workflow.
- **No inventing plan probabilities or performance.** See "Assemble the Prep Doc" above.
- **No legal advice.** Estate/tax findings are flagged for the advisor (and the household's attorney/CPA where relevant) to evaluate, not acted on here.

## Important Notes

- **Underperformance goes first, not buried.** If the portfolio trailed its benchmark, put it in talking points with an honest explanation — advisors lose trust by dodging it.
- Never fabricate performance numbers, plan probabilities, or client details. If a source is unavailable and the advisor can't provide data, show the section as pending.
- Flag compliance-sensitive content: if the prep doc will be shared with the client, recommend running client-facing excerpts through **/compliance**.
- Watch for milestone triggers in the data: turning 50 (catch-up contributions), 59½ (penalty-free withdrawals), 62-70 (Social Security), 65 (Medicare), 73 (RMDs).
- Treat all client data as confidential; only include what's needed for this meeting.$body$),
('marketplace:claude-for-financial-advisors/claude-for-financial-advisors/skills/prospect-intake', 'finance', 'prospect-intake', '', 'prospect-intake', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-financial-advisors', '', $body$# Prospect Intake

Turn the pile of statements a prospect hands over into something usable — a clean summary they can read, a clean handoff the analyst team can build a full proposal from, and a warm note that keeps the prospect engaged while that happens.

This skill is the **intake step**, not the proposal itself. The full investment proposal (proposed allocation, expected outcomes, fees, transition plan) is built by the firm's analysts from the detailed handoff this skill produces — it is not generated here.

## Inputs

Required: the **prospect's name**. Their files are needed too — either found in a connected tool or uploaded — but a request that arrives without them is a normal starting point, not a reason to hold off: **Step 1: Find the Files** below is how they get found, and it is where this skill begins. Never invent holdings.

## Step 1: Find the Files

Ask the advisor a single question up front: *do you want me to look for [prospect]'s files in your connected tools, or would you rather upload them here?* Get the prospect's name either way — it's needed for both paths.

**A. Look in connected tools**

Check which systems are actually connected — call `ListConnectors` (load via `ToolSearch` if it isn't already available) — for a CRM (Redtail, Salesforce, Wealthbox), Google Drive, Gmail, and Microsoft 365. Don't guess at a tool-name prefix; for any system whose tools are loaded, use `ToolSearch` with that system's name to find its actual tools.

**Look for the tools before you trust the registry.** `ToolSearch` by the system's own name is the check that decides: if its tools come back, that system is connected and callable — use them. `ListConnectors` can answer "No installed connectors found" even in a session with several live, working connectors, and in some clients it renders a user-facing card rather than returning data at all. So it explains a gap, it never establishes one, and an empty result means **unknown**, never "nothing is connected". When it does return entries, read `enabledInChat`, not `connected`: `connected: true` with `enabledInChat: false` is authenticated but switched off for this chat, so tell the advisor they can enable it here rather than reporting it as unconnected; a missing or `null` `connected` is unknown, not disconnected.

Search all connected systems **in parallel** — one system coming back empty doesn't block reading the others. If this pull is likely to take a moment (several systems connected), say so up front; that's a heads-up, not another "should I start?" gate — the upload-vs-search question above is the only required input before proceeding.

Show the advisor what matched (file names, email subjects, CRM record) before reading any of it — confirm which items are actually the prospect's files before pulling content from them. **Disambiguate first:** if a CRM search turns up more than one matching contact or opportunity, don't pull from or attach to any of them until the advisor confirms which one is correct — same privacy bar as a household match in other skills: never proceed on a name match alone.

If Zocks is also connected, check it for a prior conversation with this prospect and pull whatever facts it already captured (goals, life details, account mentions). Reuse those instead of re-asking the advisor or the prospect for them, and cite them as coming from that conversation rather than treating them as missing in Step 2.

If none of CRM/Drive/Gmail/M365 are connected, say so plainly and fall back to upload.

**B. Upload here**

Wait for the advisor to provide files — PDF/CSV/screenshot, or pasted text. Don't proceed on a promise of files to come; wait for them to actually arrive. Never invent holdings to fill a gap while waiting.

## Step 2: Clean the Files

**Dispatch one `claude-for-financial-advisors:statement-extract` subagent per file, all in a single message so the pile is read concurrently** — one `Agent(claude-for-financial-advisors:statement-extract)` call per file, in the same response. Each gets one file path and the prospect's name, and returns that file's accounts as a normalized record with data-quality flags and its inferred-vs-read marking already done. Reading a stack of statements one after another is the slowest part of this skill, and it gets slower the bigger the pile — which is exactly when the advisor is waiting longest.

Consolidation stays with you: the subagents each see one file and cannot tell that an account in file 3 is the same account as one in file 7. Duplicate detection across the set, and the single consolidated view, are yours to assemble from their records.

The extraction schema each subagent works to, which is also what to do by hand if the subagent is unavailable — per account:
- Account type/registration (401(k), IRA, brokerage, etc.) and custodian/provider if shown
- Holdings: ticker/fund name, shares or units, current value, cost basis if present
- Fees visible on the statement
- Statement/export date
- Any restrictions noted (e.g., employer plan in-service withdrawal rules, vesting)

Normalize everything into one consolidated view across all files/accounts. Flag data-quality problems as you go rather than silently working around them:
- Illegible or partial scans
- Missing cost basis
- Stale statement dates
- Accounts that appear duplicated across files

Never fabricate a figure that isn't legible or present — mark it "— not shown on file provided," unless it's a fact Zocks already captured in a prior conversation (Step 1), in which case use that instead of flagging it missing.

## Step 3: The Three Outputs

Use the templates in this skill's `templates/` folder as the skeleton for each. Fill every field; where data wasn't shown on any file provided, mark it "— not shown on file provided" rather than leaving it blank silently.

**Inferred vs. Read applies to every figure in all three outputs**, not just the Analyst Handoff below — any number in the Prospect Summary or What-to-Expect memo that was computed or assumed rather than read directly off a file needs the same flag.

### A. Prospect Summary
Template: `templates/prospect-summary-template.md`. Plain-English, prospect-facing. Sections:
1. **Accounts in Scope** — account types/registrations reviewed (no account numbers, no custodian internals beyond what's needed to identify the account type)
2. **Holdings Snapshot** — a high-level view of what's held, by account
3. **Total Assets Under Review** — the sum across all accounts

**No asset mix/allocation commentary, no fees, no performance or return claims** — this confirms "here's what we received and understood," nothing more.

### B. Analyst Handoff
Template: `templates/analyst-handoff-template.md`. Internal, for the firm's analyst team — this one stays internal (see Step 4). Sections:
1. **Per-Account Line Items** — the full consolidated detail from Step 2: account type/custodian, each holding with shares/units, value, cost basis, fees, statement date, restrictions
2. **Data Quality Flags** — illegible/partial scans, missing cost basis, stale statement dates, duplicate accounts across files, called out per account/line item
3. **Inferred vs. Read** — for every figure that required inference (e.g., computed from other numbers, assumed from context) rather than being read directly off a file, mark it as inferred; everything else is read-off-file by default

### C. What-to-Expect Memo
Template: `templates/what-to-expect-template.md`. Brief, friendly, prospect-facing. Sections:
1. **What We Received** — the files/accounts reviewed
2. **What Happens Next** — the firm's analysts are building the full proposal from this intake
3. **Who You'll Hear From, and When** — ask the advisor for the actual next point of contact and timeline; never invent a turnaround time, a name, or promise a specific outcome. If the advisor hasn't given you these yet, ask before finalizing this section rather than leaving a guess in place.

## Step 4: Compliance

Run **/compliance** on outputs **A (Prospect Summary)** and **C (What-to-Expect Memo)** — both are prospect-facing and fall under the same marketing/antifraud rules as client communications.

**Finish the review before you hand anything back.** /compliance writes two files per document it reviews — `<slug>-compliance-analysis.md` and `<slug>-compliance-redraft.md`. Until both exist for **both** A and C, the review has not happened yet and the intake is not done. A clean review still writes a redraft, so "nothing needed changing" is not a reason for the file to be missing. Nothing here runs in the background: if you are waiting on a scan, it has already come back and the remaining markup is yours to write.

**From here on, A and C mean the redrafts.** When you hand the documents back, list them for attaching, or offer to send them, name `<slug>-compliance-redraft.md` — never the original draft. If you show the advisor a list of files, say which one goes to the prospect; an undifferentiated list with the original and the redraft side by side is how the pre-compliance draft gets sent by mistake.

**Output B (Analyst Handoff) stays internal and does not go through /compliance** — it's not prospect-facing.

## Step 5: CRM

After the three outputs are ready, show the advisor one summary of what you're about to do — attach A, B, and C to the existing contact/opportunity confirmed in Step 1, or create a new contact and attach them there — and get a single confirmation on that whole batch, not a separate approval per document. Only write after they say yes; never attach or create anything before that.

## Step 6: Email the What-to-Expect Memo

If Gmail is connected, offer to send the compliance-reviewed version of C to the prospect: draft the message (subject and body) and show the advisor the full draft before anything goes out. Only send after they explicitly approve it — never send automatically, and never send the pre-compliance draft.

If Gmail isn't connected, or the advisor would rather send it themselves, hand back the markdown file from Output instead — this step is optional, not required.

## Output

Write all three as markdown files first, clearly labeled: the prospect summary (A), the analyst handoff (B), and the what-to-expect memo (C). Remind the advisor that A and C need compliance review before going out (Step 4), that B stays internal, and that the full proposal itself is a separate next step the analyst team builds from B.

Then ask the advisor whether they'd like the prospect-facing pieces (A and C) converted to .docx or .pdf — don't create either format unless they ask. B stays internal and markdown is fine for it either way.

## Out of Scope (for now)

- **No proposed allocation, fee schedule, or expected-outcomes modeling** — that's the full proposal the analysts build from this skill's handoff.
- **No transition/ACAT paperwork.**
- **No performance projections or return assumptions.**

## Important Notes

- Never fabricate holdings, values, or cost basis from illegible or partial files — mark it as not shown rather than estimating.
- Treat the prospect's files as confidential, whether pulled from a connected tool or uploaded.
- The prospect isn't yet a client — don't create or modify any CRM record without the advisor's explicit go-ahead (see Step 5).
- Same rule for email: never send the Step 6 draft without the advisor's explicit approval. Claude drafts, the advisor decides.$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/ai-inventory', 'legal', 'ai-inventory', '', 'ai-inventory', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /ai-inventory

## When this runs

The user wants to manage their AI system inventory under the EU AI Act. The
core idea the skill exists to enforce: **role and tier are per-system, not
per-company.** A single organization can be a *provider* of System A, a
*deployer* of System B, and an *importer* of System C. Each combination
triggers a different set of obligations under the AI Act. The inventory
exists so those assessments are tracked where you can find them — the
obligations themselves are derived in conversation, not from a table.

## What to do

1. **Read the config.** Read
   `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.
   If it doesn't exist or still has `[PLACEHOLDER]` markers, direct the user
   to `/ai-governance-legal:cold-start-interview` first.

2. **Read the inventory.** Inventory lives at
   `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/ai-systems.yaml`.
   If it doesn't exist, create it with an empty `systems:` list when the
   first `add` runs.

3. **Dispatch on the argument:**

   - No argument, or `list` → show the inventory table (see **List** below).
   - `add` → run the **Add** flow.
   - `edit <id>` → show the current record, ask what to change, update one
     field, confirm, write.
   - `classify <id>` → run the **Classification walk-through** on an
     existing record, updating role, tier, role_basis, and tier_basis.
   - `show <id>` → show the full record.

4. **On list, offer the dashboard:**
   "Want the full dashboard? Filter by status / tier / EU nexus / owner.
   Say the word."

5. **Close every action with a hook into the lawyer's work.**
   After any write, say:
   > Recorded. When you're ready to walk through obligations for this
   > system, just ask — I'll do it in-conversation and flag where the AI
   > Act article mapping needs your verification. I don't derive
   > obligations from a table because the mapping is complex and changing.

## List format

Render as a compact table:

| ID | Name | Owner | Status | EU nexus | Role | Tier | Next review |
|----|------|-------|--------|----------|------|------|-------------|
| sys-001 | Resume screening | HR / Jamie | in_production | yes | deployer | high_risk | 2026-08-01 |
| sys-002 | Email drafting assistant | IT / Priya | in_production | no | deployer | limited | 2026-12-01 |

Under the table, show counts by tier and a line: "N systems flagged for
review within 30 days."

## Add flow (interview)

Ask, one field at a time (or accept a paste). The required fields are
`name`, `owner`, `description`, `status`, `eu_nexus`. The rest can be
deferred — say so explicitly: "you can come back to classification with
`/ai-governance-legal:ai-inventory classify <id>`."

1. **Name.** Short label for the system.
2. **Owner.** Person or team accountable for it day-to-day.
3. **Description.** One or two sentences. What does it do, and against
   what data?
4. **Status.** `planned | in_development | in_production | deprecated`.
5. **EU nexus.** Is the system deployed in the EU/EEA, offered to users in
   the EU/EEA, or used to produce outputs that affect people in the
   EU/EEA? If any of these are true, EU AI Act analysis applies.
6. **Proceed to classification?** Offer to run the walk-through now, or
   skip and come back later.

Assign an ID: `sys-NNN` where NNN is the next integer in the file.

## Classification walk-through

The walk-through produces `role`, `role_basis`, `tier`, `tier_basis`. Both
bases are tagged `[verify against current AI Act text]` — not because the
skill is hedging, but because the article mapping is complex and the AI
Act is still phasing in. The lawyer owns verification.

### Step 1: Role

> **Who does what to this system?**

Options, with the distinguishing test:

- **Provider** — you develop it (or have it developed) and place it on the
  EU market or put it into service under your own name or trademark.
- **Deployer** — you use it under your own authority, not for personal
  non-professional use. (Most common inside companies.)
- **Importer** — you bring an AI system into the EU from a provider
  established outside the EU.
- **Distributor** — you make an AI system available on the EU market
  without being the provider or importer.
- **Authorized representative** — you act on behalf of a non-EU provider
  and are established in the EU.
- **Product manufacturer** — you put a general-purpose AI system (or
  another AI system) into a product under your own name/trademark. Treated
  as provider for the product.

**Dual-role flag.** If the user substantially modifies a vendor system
(fine-tunes on their own data, changes the intended purpose, rebrands),
they may become a **provider** of the modified system even if they started
as a deployer. Call this out when they describe any modification beyond
configuration. `[verify against current AI Act text — Article 25, provider
obligations and substantial modification]`

Write the role. Write `role_basis` in one sentence.

### Step 2: Tier

> **What does the system do, and does the use case fall into a regulated
> category?**

Check in order:

**A. Article 5 prohibited practices.** `[verify against current AI Act
text — Article 5]`

Summaries, not definitive text:
- Subliminal or deceptive techniques materially distorting behavior
- Exploiting vulnerabilities (age, disability, socio-economic status) to
  materially distort behavior
- Social scoring by public authorities leading to detrimental treatment
- Real-time remote biometric ID in publicly accessible spaces for law
  enforcement (narrow exceptions)
- Biometric categorization inferring race, political opinions, union
  membership, religious or philosophical beliefs, sex life, or sexual
  orientation
- Emotion recognition in the workplace or education (medical and safety
  exceptions)
- Facial image database scraping from the internet or CCTV
- Predictive policing based solely on personality traits

If matched → tier is `prohibited`. Flag the use case as stop and route to
the governance team's prohibited-practice workflow.

**B. Annex III high-risk areas.** `[verify against current AI Act text —
Annex III]`

Summaries:
1. Biometric identification and categorization
2. Critical infrastructure (digital infrastructure, road traffic, supply of
   water / gas / heating / electricity)
3. Education and vocational training (access, evaluation, proctoring,
   monitoring prohibited behavior)
4. Employment, worker management, self-employment access — recruitment,
   selection, promotion, termination, task allocation, monitoring, performance
5. Essential private and public services (public benefits, credit scoring
   for individuals, risk assessment and pricing for life/health insurance,
   emergency dispatch)
6. Law enforcement (risk assessment, polygraphs, deepfake detection,
   reliability of evidence, profiling)
7. Migration, asylum, border control (risk assessment, travel document
   verification, examination of applications)
8. Administration of justice and democratic processes (research and
   interpretation, influencing elections)

If matched → tier is `high_risk`. Note the Annex III area and subsection.

**C. GPAI.** `[verify against current AI Act text — Article 51 and
surrounding]`

- **GPAI:** model trained on broad data at scale, designed for generality,
  capable of competently performing a wide range of distinct tasks.
- **GPAI + systemic risk:** cumulative compute > 10^25 FLOPs, or designated
  by the Commission.

**D. Limited risk.** Chatbots interacting with natural persons, deepfakes,
emotion recognition and biometric categorization systems outside Article 5
scope — transparency obligations apply.

**E. Minimal risk.** Everything else.

Write the tier. Write `tier_basis` in one sentence, citing the article or
Annex entry that matched, tagged `[verify against current AI Act text]`.

### Step 3: Recommendations

Offer three next steps:
1. "Want me to walk through obligations for this system? I'll do it in
   conversation — I don't derive them from a table."
2. "Want to run `/ai-governance-legal:aia-generation` to produce a full
   impact assessment?"
3. "Want to set a next review date? I'll add it to the inventory."

## Record format

```yaml
systems:
  - id: sys-001
    name: "Resume screening tool"
    owner: "HR / Jamie"
    description: "Filters inbound CVs against job criteria"
    status: in_production          # planned | in_development | in_production | deprecated
    eu_nexus: true                 # deployed, offered, or affects people in the EU/EEA
    role: deployer                 # provider | deployer | importer | distributor | authorized_rep | product_manufacturer
    role_basis: "We license from VendorX and deploy internally [verify against current AI Act text]"
    tier: high_risk                # prohibited | high_risk | limited | minimal | gpai | gpai_systemic
    tier_basis: "Annex III(4)(a) — employment, recruitment selection [verify against current AI Act text]"
    obligations_assessed: false
    obligations_note: "To assess: as deployer of a high-risk system — human oversight, input data quality, monitoring, record-keeping, informing workers, FRIA if public body/service — see Article 26 [verify against current AI Act text]"
    next_review: "2026-08-01"
    review_trigger: "on substantial modification or annually"
    created: "2026-05-11"
    updated: "2026-05-11"
```

## Why this skill does NOT auto-derive obligations

The inventory stores role, tier, and the basis for each. It does NOT
contain a hardcoded role × tier → obligations table.

When the user asks "what are my obligations for System X?", the skill
does the analysis **in conversation**, tagged `[verify]`, and routes to
`/ai-governance-legal:aia-generation` for the formal impact assessment
if needed.

This is deliberate:
- Article mapping is complex and the AI Act is phasing in through 2027.
- Confident-and-wrong on a compliance obligation ends up in a board memo.
- The inventory is a registry for the lawyer. The lawyer owns the
  obligation analysis.

## Guardrails

- **Never classify silently.** The classification walk-through must be
  visible; do not auto-classify from a system description.
- **`[verify]` tags stay.** They are not hedging — they are the point.
  Do not strip them in outputs.
- **Flag substantial modification.** Whenever a system is modified beyond
  configuration, prompt the user to re-run `/ai-inventory classify` —
  modification can change role.
- **Don't declare obligations from a table.** If asked, do the analysis
  in conversation and route to `/aia-generation` for anything that needs
  a formal record.$body$),
('marketplace:claude-for-legal/claude-for-legal/ai-governance-legal/skills/aia-generation', 'legal', 'aia-generation', '', 'aia-generation', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:claude-for-legal', '', $body$# /aia-generation

1. Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. Confirm impact assessment house style is populated.
2. Determine risk track (fast or full) from governance tier and use case characteristics, using the framework below.
3. Run intake — conversational, not a form.
4. Regulatory classification for each regime in the footprint — research tier, prohibited-practice exposure, and applicable obligations; cite primary sources.
5. Write assessment in house style (from seed doc, or default if none captured).
6. Policy diff against `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` AI policy commitments.
7. Output: assessment doc + conditions list + handoff flags (privacy PIA, vendor review if needed).

```
/ai-governance-legal:aia-generation "AI résumé screening for HR"
```

---

## Matter context

**Matter context.** Check `## Matter workspaces` in the practice-level CLAUDE.md. If `Enabled` is `✗` (the default for in-house users), skip the rest of this paragraph — skills use practice-level context and the matter machinery is invisible. If enabled and there is no active matter, ask: "Which matter is this for? Run `/ai-governance-legal:matter-workspace switch <slug>` or say `practice-level`." Load the active matter's `matter.md` for matter-specific context and overrides. Write outputs to the matter folder at `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/matters/<matter-slug>/`. Never read another matter's files unless `Cross-matter context` is `on`.

---

## Purpose

An AI impact assessment is a documented decision, not a form. It answers: what
does this AI system do, how does it reach its outputs, who's affected if it's
wrong, what's the oversight, and is it okay to deploy. This skill structures that
conversation and writes the output in this team's format — the one learned from the
seed impact assessment during cold-start.

An AI impact assessment is not the same as a PIA. A PIA asks whether personal data
is handled lawfully. An AIA asks whether the AI system is designed and deployed
responsibly. They often need to happen in parallel; they're not substitutes.

## Load house style

Read `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → `## Impact assessment house style`. That has:
- What triggers an impact assessment at this company
- The structure template extracted from the seed assessment
- Typical depth
- Who signs off

If the seed structure is in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`, **use it**. The point is that this assessment
looks like the other assessments this team produces.

**Jurisdictional scope.** This assessment applies the regulatory regimes listed in `## Regulatory footprint` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. AI legal rules, risk classifications, and deployment obligations vary materially by jurisdiction and are moving fast. If this system is (or will be) deployed outside that footprint, or if a choice-of-law question is in play, this analysis may not apply as written — re-run or expand the footprint.

---

## Step 0: Is an impact assessment needed?

Check the trigger criteria in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.

**Also check these regardless:**
- Does this AI make or materially influence a decision affecting a person (employment,
  credit, access, pricing, content moderation)?
- Does this AI process personal data about individuals?
- Is this a customer-facing AI system rather than purely internal?
- Does this AI use a third-party model where the company is the deployer?
- Is the use case in the elevated or high governance tier per `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`?

If none of the above and the house trigger isn't met:
> "Doesn't look like this needs a full impact assessment. Here's a one-paragraph
> record for the file explaining why — in case anyone asks later."

---

## Step 1: Risk track

Before intake, determine which track to run. The tier definitions and the fast-track criteria come from `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` (`## Use case registry` and `## Governance tiers`), not from any hardcoded regime-specific framework.

Research the applicable risk classification framework for each regime in the user's regulatory footprint. Many regimes distinguish by risk tier, affected population, and decision consequentiality — research the specific criteria. Note that most regimes treat employee data as personal data and employee monitoring as consequential; don't assume internal-only systems are out of scope.

> **No silent supplement.** If a research query to the configured legal research tool (Westlaw, EUR-Lex, regulator sites, or firm platform) returns few or no results for a regime's risk tiers or triggers, report what was found and stop. Do NOT fill the gap from web search or model knowledge without asking. Say: "The search returned [N] results from [tool]. Coverage appears thin for [regime / topic]. Options: (1) broaden the search query, (2) try a different research tool, (3) search the web — results will be tagged `[web search — verify]` and should be checked against the issuing authority before relying, or (4) flag as unverified and stop. Which would you like?" A lawyer decides whether to accept lower-confidence sources.
>
> **Source attribution tiering.** Tag every citation in the AIA — regulatory text, delegated acts, guidance, standards — with its source. For model-knowledge citations, use one of three tiers rather than a single blanket "verify" tag:
>
> - `[settled]` — stable, well-known statutory and regulatory references unlikely to have changed (e.g., GDPR Art. 22 as a concept, the existence of Regulation (EU) 2024/1689 as the EU AI Act). Still verify before certifying, but lower priority.
> - `[verify]` — model-knowledge citations that are real but should be verified: specific delegated / implementing acts, regulator guidance, NYC DCWP rules, Colorado AI Act provisions, harmonized standards, effective dates, EEOC guidance, and anything post-2023.
> - `[verify-pinpoint]` — pinpoint citations (specific EU AI Act article numbers, annex references, Colorado AI Act subsections, NYC LL 144 rule sections, sub-paragraph letters) carry the highest fabrication risk and should ALWAYS be verified against a primary source. EU AI Act article numbers in particular shifted during consolidation; every pinpoint cite to the Act should be verified against the Official Journal text.
>
> Tool-retrieved citations keep their source tag (`[Westlaw]`, `[EUR-Lex]`, `[regulator site]`, or the MCP tool name); web-search citations remain `[web search — verify]`; user-supplied citations remain `[user provided]`. The tiering surfaces the real verification work — a reader who verifies everything verifies nothing. Never strip or collapse the tags.
>
> **For non-lawyer users, uncertain dates go in a confirm-list, not inline.** A `[verify]` tag on "effective February 1, 2026" reads as "effective February 1, 2026" to a CISO who doesn't know what `[verify]` means. Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If Role is **Non-lawyer** and a date, deadline, phase-in, threshold, or effective-date assertion is uncertain (would carry `[verify]` or `[verify-pinpoint]` if inline), replace the inline assertion with "effective date: confirm with counsel" (or "threshold: confirm with counsel", etc.) and collect all uncertain assertions in a final AIA section titled:
>
> > **Things I'm not certain about — ask your attorney to confirm before relying on this:**
>
> List each uncertain item there with (1) what I said, (2) what I'm uncertain about, (3) why it matters to the assessment. This prevents a non-lawyer reader from mistaking a flagged best-guess for a checked fact. Lawyer-role users get the inline `[verify]` treatment — they know what the tag means.

**Fast track vs. full assessment:** `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` defines what qualifies for abbreviated treatment. If `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` doesn't define fast-track criteria, default to full assessment and ask the user what criteria they want captured for next time.

If in doubt, run the full assessment. A fast track that turns out to be wrong
is worse than a thorough assessment on something low-risk.

---

## Step 2: Intake

Before writing anything, get answers to these. Conversational is fine — this
is not a form to send them.

### The system

- What does the AI do? Describe it in plain language, not marketing copy.
- Which model or vendor is powering it? Fine-tuned or off-the-shelf?
- Where does it sit in the workflow — is it assistive (human reviews output),
  augmentative (human can override but usually doesn't), or automated (no human
  in the loop)?
- What's the output — generated text, a score, a classification, a recommendation,
  an action?

### Who's affected

- Who does the AI's output act on — employees, customers, third parties?
- If the AI produces an error (false positive, false negative, hallucination), who
  bears the harm and what's the worst realistic case?
- Are any vulnerable groups disproportionately in scope — minors, job applicants,
  people in financial distress, patients?

### Inputs and data

- What data does the AI take in?
- Does it take in personal data? Whose?
- Was the model trained on data from this company, or is it a foundation model
  with no company-specific training?
- Where does input data go — does it leave the perimeter to a third-party model
  API?

### Decisions and oversight

- Does the AI output trigger an action automatically, or does a human decide what
  to do with the output?
- If there's human review: how often does the human actually change the AI's output?
  (If the answer is "rarely" — the human isn't really reviewing; they're rubber-stamping.)
- Is there an appeals or correction process for people affected by the AI's outputs?
- Who is accountable for the AI system's outputs — is there a named owner?

### Accuracy and failure

- What's the known or estimated error rate? What testing has been done?
- What happens when the AI is wrong — is the error surfaced, logged, corrected?
- Has bias testing been done? Against what demographic groups?

### Deployment stage and scale

Ask:
- **Stage:** "Is this system (a) proposed and not yet built, (b) in pilot, (c) live in production, or (d) live and scaled?"
- **Scale:** "Roughly how many individuals are affected per [month/year]? How long has it been running?"
- **History:** "Has it been assessed before? Has it produced decisions that were challenged, appealed, or reversed?"

Stage changes the assessment: a proposed system gets a design review (can we build it safely?). A pilot gets a design review plus a "before you scale" gate. A live system gets a retrospective impact check (has it caused harm?) AND a go-forward review. A live-and-scaled system gets all of the above plus a remediation plan if issues are found, because you can't just turn it off.

---

## Step 3: Regulatory classification

**Step 3 pre-check — footprint freshness.** Before iterating over the captured `## Regulatory footprint`, compare the use case's affected population and decision type (from Step 2) against the footprint as written. The footprint was set at cold-start, based on the company's operating posture at that moment. If the use case introduces an affected population (e.g., children, employees in a new state, EU data subjects) or a decision type (e.g., hiring, creditworthiness, health diagnosis, law enforcement, critical infrastructure) that the footprint does not contemplate, **re-derive the applicable regimes rather than iterating over the stale list.**

Say to the user:

> "The practice profile's regulatory footprint was set for [affected populations / decision types captured at cold-start]. This use case affects **[new population or decision type — e.g., employees in Colorado, minors under 13, credit decisions, biometric identification]**, which is not in the captured footprint. I'm going to re-derive the applicable regimes from the company's operating jurisdictions ([list from `## Company profile`]) and this use case's decision type ([Y]), rather than use the stale footprint. If this use case is representative of work you expect to see more of, update `## Regulatory footprint` at the end of this run so the next AIA doesn't have to re-derive."

A common failure mode: the footprint lists EU AI Act + GDPR + NYC Local Law 144, and the use case is a hiring system being deployed into Illinois and Colorado. The footprint has no Illinois or Colorado entry, so iterating over it silently misses IL AIVIA, the new Colorado AI Act deployer obligations, and BIPA implications of any biometric component. Re-derive.

A second failure mode: the footprint was set before a regime that now matters existed (or took effect). If re-derivation surfaces a regime not in the footprint, flag it in the output's recommendation section, cite the authority, and recommend updating the footprint.

For each regime in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → `## Regulatory footprint` that applies to this system — **plus any regime surfaced by the re-derivation above** — research the currently operative risk classification framework and determine where the system lands.

Research tasks:
- What is the regime's own tier taxonomy (e.g., prohibited / high-risk / limited / minimal, or the regime's equivalent)?
- What are the criteria for each tier? Cite primary sources with pinpoint references.
- Which tier does this system fall into given its function, affected parties, and decision consequentiality?
- Are there prohibited practices the system might touch? Treat any possible match as critical — flag immediately.
- Are there transparency obligations that apply regardless of tier (disclosure that a user is interacting with AI, labeling of AI-generated content, notice to people subject to automated decisions)?
- If the company is a builder providing a general-purpose or foundation model, what provider-level obligations apply (technical documentation, training data transparency, copyright compliance, systemic-risk testing)?
- **Does any regime in the footprint require a separate fundamental-rights impact assessment (FRIA)?** EU AI Act Art. 27 requires a FRIA for certain deployers of high-risk AI systems (public bodies and private entities providing public services, plus certain creditworthiness and insurance-risk-assessment use cases). Check each regime for an equivalent fundamental-rights or human-rights impact assessment that is a distinct deliverable from this AIA. If a FRIA (or regime equivalent) is required, flag it as a separate deliverable in the recommendation and conditions — do not treat this AIA as a substitute.

Don't assume internal-only systems are out of scope — most regimes treat employee data as personal data and employee monitoring as consequential. Verify the specific rule.

**Provider-vs-deployer split (when `AI role: Both`).** If `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` → `## Company profile` → `AI role` is `Both` (the company is both a provider/builder and a deployer), Section 6 MUST include a provider-vs-deployer mapping table per regime. Most regimes impose materially different obligations on providers (or builders) versus deployers (or users) — collapsing them into one undifferentiated list misses obligations and conflates risks. Do not combine provider and deployer obligations into a single section. Produce, per regime:

| Obligation | As provider | As deployer |
|---|---|---|
| [specific obligation, pinpoint cite] | [what applies / does not apply / with what carve-outs] | [what applies / does not apply / with what carve-outs] |

**If a high-risk or equivalent classification applies:**
Flag in the assessment, citing the specific provision and regime. Note that this AIA documents the internal review but does not substitute for any formal conformity assessment the regime requires. Recommend external legal review before deployment in the affected jurisdiction.

Capture the classification and the cited authority in the assessment output.

---

## Step 4: Write the assessment

**Use the seed structure from `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.** If none was captured, use this default:

```markdown
[WORK-PRODUCT HEADER — per plugin config ## Outputs — differs by role; see `## Who's using this`]

# AI Impact Assessment: [System/Feature Name]

**Prepared by:** [name] | **Date:** [date] | **Status:** DRAFT / APPROVED
**System owner:** [name] | **AI governance reviewer:** [name]
**Governance tier:** [Standard / Elevated / High]
**Track:** [Fast track / Full assessment]

---

## Executive summary

[Two sentences: what this AI does and whether it's okay to deploy. E.g., "This
system uses a third-party LLM to draft initial responses to customer support tickets
before human agent review. Processing is consistent with the company's AI policy;
three conditions required before production deployment."]

**Overall risk:** 🟢 Low / 🟡 Medium / 🟠 High / 🔴 Very high

---

## 1. System description

**What it does:** [plain English — not marketing]
**Model / vendor:** [who's providing the AI]
**Deployment mode:** [Assistive / Augmentative / Automated]
**Output type:** [text / score / classification / recommendation / action]
**Status:** [Not started / Pilot / Production]

---

## 2. Affected parties

**Who it acts on:** [employees / customers / third parties]
**Scale:** [how many people, how often]
**Harm if wrong:** [most realistic worst case — specific, not generic]
**Vulnerable groups in scope:** [yes — [who] / no]

---

## 3. Data inputs

**Data categories used:** [specific fields, not "user data"]
**Personal data:** [yes — [whose] / no]
**Data leaves perimeter?** [yes — to [vendor] / no]
**Model training:** [company data used / foundation model / fine-tuned on [dataset]]

---

## 4. Decision-making and oversight

**Human in the loop:** [Always / Nominally (rubber-stamp risk) / No]
**Override mechanism:** [how a human can intervene or correct]
**Appeals / correction for affected parties:** [yes — [how] / no]
**Named owner:** [name or role]

---

## 5. Accuracy and bias

**Error rate:** [known / estimated / untested]
**Failure mode:** [what happens when it's wrong — surfaced? logged? corrected?]
**Bias testing:** [done — [results] / not done / not applicable]

---

## 6. Regulatory classification

*[One subsection per regime in the regulatory footprint that applies to this system.]*

**Regime:** [name]
**Classification under this regime:** [tier, with pinpoint citation to the controlling provision]
**Prohibited practices triggered:** [none identified / [specific provision and why]]
**Applicable obligations:** [researched list with citations — transparency, documentation, human oversight, testing, registration, etc.]
**Fundamental-rights impact assessment required?** [Yes — e.g., EU AI Act Art. 27 FRIA applies / regime equivalent / No / Not applicable. If yes, this is a separate deliverable, not subsumed by this AIA.]
**Effective / enforcement date:** [date(s)]
**Ambiguity or open interpretation:** [flag anything not yet settled]

**Provider-vs-deployer obligation split (required if `AI role: Both`):**

| Obligation | As provider | As deployer |
|---|---|---|
| [specific obligation + pinpoint cite] | [what applies / does not apply] | [what applies / does not apply] |

---

## 7. AI policy consistency

| Policy commitment | Consistent? | Notes |
|---|---|---|
| [commitment from `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md` AI policy section] | 🟢 / 🟡 / 🟠 / 🔴 | |

[If any item is 🟡 or worse: policy update needed before deployment, or design needs to change.
One of them has to change — not both flagged and left open.]

---

## 8. Risks and mitigations

| # | Risk | Likelihood | Impact | Mitigation | Status | Owner |
|---|---|---|---|---|---|---|
| 1 | [specific risk tied to this design — not "AI hallucination" generically] | L/M/H | L/M/H | [specific control] | Done / Planned / Gap | [name] |

**Residual risk after mitigations:** [assessment]

---

## 9. Recommendation

**[APPROVED / APPROVED WITH CONDITIONS / CHANGES REQUIRED / NOT APPROVED]**

**Conditions (if any):**
- [ ] [specific action before deployment — owner, deadline]

**Privacy review required?** [Yes — run `/privacy-legal:pia-generation`, if the plugin is installed /
No]

**Sign-off:** [name, date]

---

## Cite check

Regulatory citations in Section 6 (and anywhere else) were generated by an AI model and have not been verified against primary sources. Before the assessment is certified or relied on, run a verification pass against a legal research tool (Westlaw, EUR-Lex, or your firm's platform) for each cited provision — confirm the pinpoint, currency, and any delegated or implementing acts. The AI regulatory landscape shifts quickly; verify before advising. Source tags on each citation (e.g., `[EUR-Lex]`, `[web search — verify]`) show where it came from; `verify` tags carry higher fabrication risk and should be checked first.
```

**Before certifying the AIA (the Sign-off step, marking Status: APPROVED):** Read `## Who's using this` in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`. If the Role is Non-lawyer:

> Certifying this AIA has legal consequences — it becomes the record the company relies on if a regulator or affected party asks how this use case was assessed. Have you reviewed this with an attorney? If yes, proceed. If no, here's a brief to bring to them:
>
> [Generate a 1-page summary: the system, the regulatory classification, the risks identified, the mitigations in place, residual risk, open questions, what to ask the attorney before certifying.]
>
> If you need to find an attorney, solicitor, barrister, or other authorised legal professional: your professional regulator's referral service is the fastest starting point (state bar in the US, SRA/Bar Standards Board in England & Wales, Law Society in Scotland/NI/Ireland/Canada/Australia, or your jurisdiction's equivalent).

Do not proceed past this gate without an explicit yes. DRAFT assessments for attorney review do not require the gate — certification does.

---

## Risk quality standards

Same standard as the PIA skill — risks must be **specific and tied to the design**.

| Bad risk | Why bad | Better |
|---|---|---|
| "AI hallucination" | Applies to every LLM; says nothing | "Model may generate plausible but incorrect legal citations — support agents have no current verification step before sending to customers" |
| "Bias" | Too vague | "Résumé scoring model trained on historical hires; if historical cohort was demographically homogeneous, underrepresented candidates may be systematically scored lower" |
| "Vendor risk" | Circular | "OpenAI's terms permit training on API inputs by default; unless the opt-out is confirmed in the agreement, customer support messages may be used to train the model" |

Aim for 2-5 real risks, not 12 padded ones.

---

## AI policy diff

Every assessment should cross-check against the AI policy commitments in `~/.claude/plugins/config/claude-for-legal/ai-governance-legal/CLAUDE.md`.
Common drift:

- Policy prohibits AI use in [category] — this use case is that category. Stop.
- Policy requires human review — this deployment has no human step. Design needs to change.
- Policy requires disclosure to affected parties — disclosure mechanism hasn't been built.
- Approved vendor list exists — this vendor isn't on it. Procurement step required.

Flag every mismatch. One of them has to change before deployment.

---

## Handoffs

- **To product / engineering:** Conditions list with owners and deadlines. Not
  "add oversight" — "add a human review step before any automated email is sent,
  owner: [product lead], before launch."
- **To privacy:** If personal data is involved, flag: "Run `/privacy-legal:pia-generation [system name]` in parallel, if the plugin is installed — the AIA doesn't substitute for a PIA."
- **To vendor-ai-review:** If a new vendor is involved, flag: "If there's no AI addendum reviewed for [vendor], run `/ai-governance-legal:vendor-ai-review` before production."
- **To reg-gap-analysis:** If new regulatory obligations emerged (EU AI Act high-risk, new sector rule), that skill tracks the gap.

---

## Close with the next-steps decision tree

End with the next-steps decision tree per CLAUDE.md `## Outputs`. Customize the options to what this skill just produced — the five default branches (draft the X, escalate, get more facts, watch and wait, something else) are a starting point, not a lock-in. The tree is the output; the lawyer picks.

## What this skill does not do

- It doesn't approve the deployment. A human signs the assessment.
- It doesn't constitute any regulatory conformity assessment — where a regime (e.g., EU AI Act) requires a formal conformity assessment, that is a separate exercise requiring external legal review and technical documentation beyond what's here.
- It doesn't design the mitigations. It describes what needs mitigating; engineering
  designs the fix.
- It doesn't substitute for a PIA when personal data is involved. Run both.$body$)
ON CONFLICT (skill_key) DO NOTHING;
