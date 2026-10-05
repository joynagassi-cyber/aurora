INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:commerce-agents/commerce-agents/plugins/commerce-builder/skills/commerce-prompt-caching', 'business', 'commerce-prompt-caching', '', 'commerce-prompt-caching', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Cache-stable request assembly

`commerce_common/` is `commerce-common/commerce_common/`, `shopping_agent/` is `shopping-agent/core/shopping_agent/`, and
`merchant_agent/` is `merchant-agent/core/merchant_agent/`.

## The three breakpoints

A request's cacheable prefix runs `tools`, then `system`, then the messages; a breakpoint ends a span the next call reads
back. The reference agents place three, all from `commerce_common/prompt_assembly.py`:

1. **The last tool**: `with_tool_cache_control(tools)`.
2. **The static system text**: `build_system_blocks(static, context)` marks it and appends the context block unmarked.
3. **The newest persisted message**: `build_request_messages(messages, rolling_breakpoint=...)` marks the last persisted
   block on the outgoing request only; the next call then reads the earlier rounds, search payloads included, from cache.

Everything per request goes in the context block, which the role's `build_dynamic_context(...)` renders once per turn.
In the static block or the tool list, those bytes would break the system or tool span on every request; in the context block they cost
one re-read of the conversation on a turn whose cart, page, or facts moved, and the rolling marker holds from that turn's
next round. The clock renders to the hour (`context_clock`), so a new minute moves nothing.

## The split as implemented

- `build_static_system(config, skills)` in each role's `prompt.py` renders identity, the most-turns rules, the fence
  notice, and the skill index from the config and the installed skills: the same bytes for the life of a deployment.
- `build_dynamic_context(...)` in the same module renders the per-request material inside the role's data fence: shopping
  takes preferences, memory facts, the cart, the page, the account block, and the time; merchant takes the store context,
  memory facts, and the time. Backend context blocks have their own size cap.
- `ShoppingAgent.__init__` and `MerchantAgent.__init__` (each role's `runtime-messages-api` `orchestrator.py`) build
  `_static_system` and `_tools` once per process; `stream_turn` renders the context block per turn and calls
  `build_request_messages` per model call.
- `build_tools` in each role's `tools/registry.py` emits the built-ins in a fixed order (the merchant builder adds `run_analysis` after them when enabled), the `load_skill` enum sorted,
  then extensions in the order given, then `web_search` when enabled; every registered tool ships on every request, and
  the executor decides on arrival whether a call can be served.
- The Agent SDK runtimes pass the same static text (plus `SKILL_TOOL_ADAPTER`) and the same contracts, and the SDK caches
  them; the hosted manifests carry the text as `system.md`, which `scripts/check.py` compares with the builder.

## When the rolling marker is skipped

Two rounds carry no marker. A bare first call (one message): a one-shot session would pay the write without a read, and
the second call's marker covers the first message anyway. A round whose `tool_choice` is other than `auto` (the
grounding-forced first iteration and the forced-text last one): `tool_choice` keys the messages span, so an entry written
under a forced round is unreadable by the auto rounds after it; the system and tool spans still hit. Both live in
`build_request_messages` and the loops' `rolling_breakpoint=` argument; `rolling_conversation_cache` turns the marker off
for debugging.

## When the conversation is compacted

When a turn's last call was given `compact_history_above_tokens` or more (its usage says; the default is the platform's
own tool-result-clearing default, a tenth of the window), the turn ends with `compact_history` in
`commerce_common/turn.py`, which replaces the oldest tool results in the stored conversation with a one-line marker
until the conversation is half its previous size. The next turn's first round rewrites the messages span once and later
rounds read the shorter one; `turn_complete.results_cleared` tells a host that appends its transcript to rewrite it. The
system and tool spans, the messages, and the write gates are unaffected; provenance lives on the session state.

## Config fields that are prompt bytes

The fields marked `(prompt)` in `commerce_common/config.py` and the role configs, plus `enable_analysis` and
`max_items_per_change`, which the merchant tool builder reads, render into the static text or the tool list; changing one is a redeploy and a miss on the next request:

| Config | Fields |
|---|---|
| `BaseAgentConfig` (`commerce_common/config.py`) | `brand_name`, `assistant_name`, `brand_voice`, `enable_web_search` |
| `ShoppingAgentConfig` (`shopping_agent/config.py`) | `domain_search_notes`, `enable_disclosures`, and the system switches `enable_cart`, `enable_orders`, `enable_policies`, `enable_fulfillment` |
| `MerchantAgentConfig` (`merchant_agent/config.py`) | `enable_analysis`, `require_host_approval`, `approval_surface`, `stage_shows_preview`, and the system switches `enable_listing_edits`, `enable_inventory`, `enable_pricing`, `enable_campaigns`; `max_items_per_change` and `max_search_results` set `maxItems` and `maximum` on tool schemas |

Skills, presentation extensions, and delegates are prompt bytes too. Gate lexicons, guardrail limits, memory settings,
the latency knobs (`eager_tool_dispatch`, `rolling_conversation_cache`, `eager_partial_frames`,
`close_on_presentation`), cart caps, and `compact_history_above_tokens` are not; `tests/test_role_registries.py`
asserts it for each.

## What breaks a hit

- Anything per request in the static block or the tool list: a name, a cart count, a page, a clock, a request id. The
  context block takes the first four; a request id belongs nowhere.
- A set or dict iterated into prompt text or a schema without sorting.
- `tools[]` membership decided per request (a flag read per request instead of once at construction).
- Rebuilding the static text or the tool list inside the turn instead of in the constructor.
- Persisting the rolling marker into the stored conversation, which then gains one marker per turn.
- Toggling a `(prompt)` field, a skill, or an extension on a running deployment; each is a redeploy.
- A prompt variant chosen per request instead of per deployment.
- A prefix under the model's minimum cacheable length, which writes nothing.
- A forced `tool_choice` (grounding first, `none` last) misses the messages span only; the loops skip the marker there.

## How to verify

- `turn_complete` carries `usage` (`usage_totals` in `commerce_common/turn.py`, the turn's calls summed) and
  `elapsed_ms`; every call also logs one line with the same counters and its own time (`log_model_call`, on
  `shopping_agent_runtime.orchestrator` and `merchant_agent_runtime.orchestrator`). Zero cache reads on the second turn
  of a conversation means the prefix changed. The counters worth charting per config version are cache reads as a
  share of input, `elapsed_ms`, rounds per turn, and blocked `tool_result` events by gate.
- `tests/test_role_registries.py` builds each role's prompt and tools twice and compares bytes, checks the cache marks,
  and checks that non-prompt settings change nothing; `commerce-common/tests/test_prompt_assembly.py` covers the block
  builders, the context clock, the rolling marker, and the skip cases; `tests/test_turn_loop.py` pins both loops to the
  same blocks, marker, and clean history. A deployment's tests carry the same three checks.
- In a deployed environment, run one three-turn conversation and read the second and third turns' usage; a proxy or retry
  layer that rewrites requests shows up here and nowhere else.$body$),
('marketplace:commerce-agents/commerce-agents/plugins/commerce-builder/skills/commerce-trust-safety', 'business', 'commerce-trust-safety', '', 'commerce-trust-safety', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Trust and safety rules

`commerce_common/` is `commerce-common/commerce_common/`, `shopping_agent/` is `shopping-agent/core/shopping_agent/`, and
`merchant_agent/` is `merchant-agent/core/merchant_agent/`; `docs/safety.md` lists the same rules. A rule inside a tool
call holds on all three paths, which share one executor (commerce-architecture); rules 10 and 15 name the paths they run
on. Merchant staging, guardrails, approval, and marketplace posture are in commerce-merchant-operations.

## Fence third-party content

1. Every tool result from catalog, review, policy, order, metric, message, or web content goes through
   `Fence.fence_payload` (`commerce_common/fencing.py`): NFKC-normalized, invisible and control characters removed, fence
   markers, forged turn markers, and special tokens replaced, wrapped in the role's label, and cut at `max_fenced_chars`.
   The executor's `_fenced` applies it to every handler.
2. The label and the notice are per-role constants (`STOREFRONT_FENCE` in `shopping_agent/fencing.py`, `MERCHANT_FENCE` in
   `merchant_agent/fencing.py`); the notice appears once, in the static prompt, with nothing untrusted in it.
3. The per-request block (profile, cart, memory facts, page, store context) sits inside the same fence after the cache
   breakpoint (`build_dynamic_context` in each role's `prompt.py`); backend context blocks have their own cap.
4. A model-supplied result count is clamped to `max_search_results` (`clamp_limit` in `commerce_common/execution.py`).

## Gate writes on provenance and caps

5. A cart write accepts only ids in `ShoppingSessionState.seen_products`, filled by the session's catalog and order reads
   (`check_provenance` and `remember_order_items` in `shopping_agent/gates.py`); update and remove also accept a line
   already in the cart. Merchant staging accepts only ids in `seen_listings` and `read_listings`, apply and discard only
   ids in `seen_changes` (`merchant_agent/gates.py`; commerce-merchant-operations).
6. `max_quantity_per_item` caps the line after the write and `max_cart_lines` the cart, under a session lock
   (`gated_add_to_cart` in `shopping_agent/gates.py`; caps in `shopping_agent/config.py`). The lock is per process, so
   `StorefrontBackend` cart methods enforce them too; eligibility, pricing, and inventory are the backend's in both roles.
7. Nothing in either interface charges or places an order: `checkout` renders the cart (`enrich_checkout` in
   `shopping_agent/enrichment.py`) and the host completes it; post-purchase care is reads, with no cancel or refund tool.
8. Provenance lives on the session state (`ShoppingSessionState`, `MerchantSessionState`), saved with the session when
   the request or turn ends (`SessionStore` in `examples/demo_common/sessions.py`, a versioned state document beside the
   transcript), so a request on another process loads it. Each map keeps its newest `PROVENANCE_CAP` records (`remember`
   in `commerce_common/types.py`); a dropped id needs a fresh read.
9. A component is validated, its products, orders, metrics, or changes are joined from those records, and ids without
   provenance are dropped and reported (`run_presentation` in `commerce_common/presentation.py`; each role's
   `enrichment.py`; commerce-ui-tools).

## Ground the answers that are figures or terms

10. A terms question, an order question, or an unseen product id (`GROUNDING_RULES` in `shopping_agent/grounding.py`), or
    a performance question or an apply request with nothing staged (`merchant_agent/grounding.py`), starts from the
    matching read: `first_forced_tool` in `commerce_common/grounding.py` picks it, the Messages API runtimes force it with
    `tool_choice`, and the SDK runtimes prefetch it when the rule has a prefetch form (`ground` in
    `commerce_common/agent_sdk.py`; the terms rule has none); the hosted path has the prompt only.
11. The lexicons are config tuples (`policy_intent_terms`, `order_intent_terms`, `product_id_patterns`, `metrics_intent_terms`,
    and their cues); a deployment appends its own words, a gate flag turns a rule off, and neither changes prompt bytes.

## Hold identity on the server

12. Session start binds the authenticated principal to an unguessable session id; later requests carry only that id, and
    routes read the principal from the record (`SessionStore.start` and `session_dependency` in
    `examples/demo_common/sessions.py`). No request field or tool argument names a user, merchant, or operator; the MCP
    servers take the principal from their environment, a production server from its request.
13. Whether the principal owns a record (order, ticket, listing), and whether the step a call depends on has
    happened, is the backend's check against its store; an id having provenance does not make it theirs or ready.

## Bound what is remembered

14. Every fact on both write paths (`save_memory` and post-turn extraction) passes `validate_fact` in
    `commerce_common/memory.py`: key of at most 64 characters, value of at most 200, one of the three `MemoryCategory`
    values, and the `MemoryWriteFilter`, which refuses identifier-shaped values by default; `memory_blocked_patterns`
    adds patterns, and a filter with `checks` replaces it (`MemoryRuntime.build`).
15. Extraction reads the last exchange's user and assistant text (`transcript_text` in `commerce_common/turn.py`), and
    `extract_and_store` drops its batch when the subject was purged meanwhile; the Messages API runtimes run it
    (`update_memory`), the SDK host calls the runtime, and the hosted path writes through `save_memory` only.
16. `memory_retention_days` (`with_retention`), `MemoryStore.delete_fact`, `MemoryStore.clear`, and `enable_memory` hold
    on every path without changing prompt or tool bytes; the examples expose read and delete routes
    (`install_memory_routes` in `examples/demo_common/memory.py`), and `clear` belongs in account deletion.
17. The subject is the shopper's `user_id` or the operation's `merchant_id` (`memory_subject` in each role's `executor.py`).

## Refuse in the result, and keep the surface fixed

18. A held call returns a normal result naming its gate (`ToolOutcome.held` in `commerce_common/streaming.py`; the host's
    `tool_result` event carries `status: blocked`), a failure returns an error result, and `execute` never raises.
19. The tool list is a function of the config: `enable_web_search` (default off) adds the tool, the SDK runtimes allow-list
    the registered names, and the manifests enable tools one by one.
20. The reference MCP servers bind to loopback unless an environment variable states that an authenticating gateway is in
    front (`enforce_local_only_bind` in `commerce_common/mcp_server.py`).

## Two rules for adversarial evals

- Poisoned listings, reviews, and messages live in eval fixtures merged in for a run, outside demo and catalog data.
- Every refusal case has a should-serve counterpart in the same niche, so a suite catches over-refusal too (commerce-evals).$body$),
('marketplace:commerce-agents/commerce-agents/plugins/commerce-builder/skills/commerce-ui-tools', 'business', 'commerce-ui-tools', '', 'commerce-ui-tools', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Presentation tools

Paths are in the reference repo: `commerce_common/` is `commerce-common/commerce_common/`, `shopping_agent/` is
`shopping-agent/core/shopping_agent/`, `merchant_agent/` is `merchant-agent/core/merchant_agent/`.

## The contract

- A component is a tool. The model's arguments carry its judgment: which ids, in what order, the reason or the
  note for each, what to compare on. The server joins every fact (title, price, image, metric value, change
  record) from records tools returned this session, so the frontend never renders a model-authored value.
- One spec per component: `PresentationComponent` in `commerce_common/presentation.py` names the tool, the
  `component` string the host renders, the `payload_model` that validates the arguments (each role's
  `tools/presentation.py`), and the `enrich` hook (each role's `enrichment.py`, collected in `PRESENTATION_COMPONENTS`).
- `run_presentation` in `commerce_common/presentation.py` is the one runner: validate, enrich, emit the `ui` event.
  The model reads the executor's `displayed_text` plus the hook's notes; the enriched payload goes to the host only.
- An enrich hook drops ids without provenance and appends a note naming them; with nothing left it raises
  `PresentationRefused`, which comes back as a held call when it names a gate and as an error otherwise.
- Shopping joins from `ShoppingSessionState.seen_products`, the cart, or an order read; merchant joins from
  `MerchantSessionState.latest_snapshot`, `seen_series`, `seen_campaigns`, `seen_analyses`, `seen_listings`, and `seen_changes`.
  `enrich_change_preview` also removes model text whose currency or weekday disagrees with the change record.
- Composition rules (which component ends a turn, text carries the reasoning, cards carry the data) are static
  prompt material; each component's when-to-use line is its tool description (commerce-architecture's layer table).

## Suggestions

- `present_suggestions` is the one tool that carries the turn's chips, up to four; the model calls it in the same
  round as the turn's last component, or after its text when the turn has none, and a tapped chip is sent as the next
  user message. No other payload, built-in or extension, carries chips.
- `sanitize_suggestion_chips` in `commerce_common/fencing.py` runs on `PresentSuggestionsPayload`: invisible and control
  characters out, whitespace collapsed, empties dropped, 80 characters each, four at most. The payload fails when no
  chip survives sanitizing.
- A round of clean presentation calls that includes `present_suggestions` ends the turn (`round_closes_turn` in
  `commerce_common/turn.py`, `close_on_presentation` in the config): the Messages API loop stops there, and the Agent
  SDK runtimes stop through a `PostToolBatch` hook (`close_on_presentation_hook` in `commerce_common/agent_sdk.py`).
  Under host approval the merchant prompt says no chip approves or applies.

## Streaming

The event list is the docstring of `commerce_common/streaming.py`; `to_sse` frames each event and a host ignores
types it does not know. `ui` carries one enriched component, `ui_partial` the same while its call still streams,
`cart_update` the whole cart after a cart write, and `change_update` a change record after it moved. `outcome_events`
in `commerce_common/turn.py` stamps each `ui` event with its call id as `stream_id` and follows it with the
`tool_result`, whose `status` is `ok`, `error`, or `blocked`. Every tool that is not a presentation tool may take a
`status` argument first (`with_status` in `commerce_common/execution.py`): a few words for the person waiting, which
the executor drops before the call runs and the runtime emits as the `tool_call` event's `label`; the web layer shows
it as the activity line. The MCP servers build their tools without it. The Agent SDK runtimes run the same executor but return the payloads together in `result.ui`
after the turn.

## Progressive rendering

A spec with an `enrich_partial` hook is rendered while its arguments arrive: the request marks its tool
`eager_input_streaming` (`with_eager_input` in `commerce_common/prompt_assembly.py`), the orchestrator parses the
buffer with `parse_partial_json` (a string still being written is left out with its key), calls `enrich_partial`
(`commerce_common/presentation.py`), and yields `ui_partial` whenever `partial_signature` changes (`StreamedRound.frame`
in `commerce_common/turn.py`; every visible change with `eager_partial_frames` on the config); the final `ui` event
carries the same `stream_id` and replaces it. Input that streams as text that is not JSON comes back to the model as
an error result and the round goes on (`StreamedRound`). Partial
hooks are synchronous and join from session state only (`partial_products`, `partial_comparison`, `partial_plan`,
`partial_guide` in `shopping_agent/enrichment.py`; `partial_metrics`, `partial_digest`, `partial_change_preview` in
`merchant_agent/enrichment.py`).

## Built-in components

- Shopping (`shopping_agent/enrichment.py`): `present_products`, `present_comparison`, `present_plan`, `present_guide`,
  `present_order_status`, `checkout` (renders the cart; charges nothing), `present_suggestions`, and `present_disclosure`,
  registered only with `enable_disclosures` and filled from `StorefrontBackend.get_disclosure`.
- Merchant (`merchant_agent/enrichment.py`): `present_metrics`, `present_digest`, `present_change_preview`, `present_suggestions`.

## Adding a vertical component

- Build a `PresentationExtension` (`commerce_common/presentation.py`): the tool description and `input_schema` the
  model sees, the `payload_model` that validates the same shape, the `component` name, and the enrich hook.
- Pass it as `extra_presentation_tools` to `ShoppingAgent` or `MerchantAgent` (`examples/travel/api/main.py`); on
  the Agent SDK and MCP paths, subclass the toolset or pass `executor_class=` so the executor receives it as
  `extensions`. `build_tools` rejects a name that collides with a built-in,
  and the extension's bytes join the cached tool list (commerce-prompt-caching).
- The seven in the repo: `examples/travel/api/itinerary.py`, `examples/travel/api/occupancy.py`,
  `examples/telecom/api/plan_matrix.py`, `examples/telecom/api/plan_mix.py`, `examples/entertainment/api/venue_map.py`,
  `examples/entertainment/api/hold_view.py`, `examples/entertainment/api/event_pacing.py`. Each keeps its types and
  its card in the vertical; nothing is added to a core package.$body$),
('marketplace:commerce-agents/commerce-agents/shopping-agent/skills/customer-care', 'business', 'customer-care', '', 'customer-care', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Customer care

Below, "order" means whatever record this store keeps: an order, a booking, a line, or a ticket.

The customer has usually been waiting on something already. Tell them what the record shows, what the terms say, and what happens next, in that order and in few words.

## Where each fact comes from

- Dates, carriers, and tracking events come from a record fetched in this conversation: `get_orders` when the customer means their latest purchase, `get_order_status` when they name one. Until it is in hand, say only that you are looking it up.
- Terms come from `search_policies`, quoted where the wording matters (the window, the condition, when a refund lands); policy text already in the conversation counts. When the terms do not address the question, say so.
- Take today's date from the local time you were given. Do not ask for card numbers, passwords, or one-time codes, and do not repeat back any the customer pastes.

## Status

- Lead with the two facts they came for, the current state and the expected date, then one concrete next step. `present_order_status` shows the order; keep the text to what to do about it.
- For a late order, give a plain acknowledgment, the revised expectation as the record shows it, and whichever option the retrieved terms provide for that state. Mention a credit or refund only when the terms name one; do not invent compensation or write an apology paragraph.

## Returns, refunds, and deliveries that went wrong

- Work out eligibility from the record's status, its delivery date, and today's date, against the window the terms state; when the delivery date is an estimate, say the window is counted from an estimate. Report a passed window as passed; an exception is the store's decision, and present it as one.
- Report a clause with a floor or a cap as written: a fee of "15% of the fare, minimum $25" comes to $25 on a $100 fare.
- Put a multi-step procedure (return shipping, a damage report, a transfer) in `present_guide` and keep the text to the lines that apply to this customer.
- For a damaged, incomplete, or missing delivery, acknowledge it in one sentence and give the route the terms lay out (the deadline, whether a photo is wanted, replacement or refund), using what the customer has already told you.

## What this flow hands off

- This flow reads. Cancelling, rebooking, changing an address or a line, refunds, and anything else that alters the record or moves money happens in the app's support flow: describe it as the next step and make clear it has not happened here.
- Fetch the record before handing off all the same; whether the step is possible depends on its state, and the caveat comes from the retrieved terms.
- With an upset customer, drop to short factual sentences on the situation and the next step.
- When one message carries a problem and a shopping request, settle the problem first, then take up the request in full in the same turn.$body$),
('marketplace:commerce-agents/commerce-agents/shopping-agent/skills/memory-personalization', 'business', 'memory-personalization', '', 'memory-personalization', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Memory and personalization

Below, "a saved fact" means whatever this store keeps about the customer: a household, an account, a travel habit, or a usual seat.

## Where a fact lives

- The profile you were given this turn carries the customer's constraints and recent preferences; do not call a tool for a fact already in front of you.
- Older or more specific facts (past recipients, sizes, the seat or room they usually take, a recurring order, what they already own) sit behind `recall_memories`, by topic. Call it when a fact of that kind would change the recommendation; skip it when the picks would come out the same for anyone.
- A saved fact is a default. Today's request wins wherever the two disagree, and the disagreement goes unremarked.
- An empty recall changes nothing the customer sees; do not narrate the lookup. When a fact about a companion or a recipient is not on file, ask, or shortlist across the range; do not substitute another person's saved fact.

## How a fact reaches the customer

- Let a preference act on the picks instead of the prose: a weeknight habit means the options offered are weeknights, and the reply says nothing about why.
- Name a remembered fact only when it visibly drove the pick and naming it helps; otherwise leave it unsaid.
- Do not read back what is on file. Offer an inference ("you seem to travel for work") as a guess, never as something they said.

## Writing a fact

`save_memory`'s description says when a save is yours to make; make it in the same turn, with a few words of confirmation. When you write one:

- Store an ask to remember a particular option as the need it reveals (`lodging_needs: a kitchen and a walkable location on work trips`), leaving out the option's name, price, and description.
- Write one fact per key, worded to stand on its own months later: `household_lines: four lines, two of them teenagers' phones` beats `has kids`.
- Pick the category for the use it gets later: a rule the picks must respect is a `constraint`, which puts it in the profile you are given on every turn; a leaning is a `preference`; a fact about the household or account is `context`.
- Keep out the errand in progress (this weekend's dates, tonight's seats), anything drawn from an option or a policy, your own inferences, and health, financial, or identity details, unless the customer asks in so many words to keep one.

## When the memory is the subject

- Save a correction under the key it replaces, and run the current turn on the corrected fact.
- Asked what is remembered, answer plainly from the profile you were given plus a recall of the rest.
- Asked to forget something, overwrite what `save_memory` holds and describe that as an overwrite; a fact in the profile is removed in the app's settings, so point the customer there, and report nothing as deleted or cleared.$body$),
('marketplace:commerce-agents/commerce-agents/shopping-agent/skills/planning-goals', 'business', 'planning-goals', '', 'planning-goals', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Planning toward a goal

Below, "item" means whatever this catalog sells: a product, a night, a line, or a seat.

Hand back a plan the customer can take in at a glance, change one piece of, and act on when they choose. Settle the steps first, then attach the items to them.

## Frame it

- Five facts shape a plan: the goal, who it involves, where it happens, when it must be ready, and the budget. Take the ones the request and the profile you were given supply. Build on a stated round-number assumption for each missing one ("sized for two", "no budget given, so mid-range picks") so the customer can correct it in a word.
- Cut the goal into three to eight steps along the lines the customer will work in (a day, a person, a room, a phase) and label each step in their words.
- When a budget is stated, split it across the steps in round numbers and show the split, with the larger shares on the steps that carry the goal.
- Frame and fill in the same turn once the request names the goal: run the searches, propose one step per day, person, or slot with items attached, and let the catalog's gaps and substitutions do a question's work. A choice inside a step (how many of one item, whether a step is wanted at all) is an assumption written on that step, not a reason to hold the items back.
- Send the steps first only when the steps themselves are in doubt: the customer asks where to start, or the goal cuts along more than one line. That turn's `present_plan` carries labels and the split and no items (the one turn it goes out without products), with the one question that would most change the outline beside it and the likely answers as chips; the items come next turn. The question does not go out without the plan.

## Fill it

- Give each step its own search and send them all in one round.
- Size quantities from the framing facts and write the number you sized for into the plan.
- Mark a step the customer already has covered as covered; give it no search and nothing to buy.
- Attach one pick per step. Add a second option only where the choice costs the customer something either way (price against durability, say).
- Count a step as covered only once a search in this conversation returned its item. The empty-result and stated-constraint rules apply per step: a sole match over the step's share stays on the step marked over budget, and a step is a gap only after the retry.
- Plan nothing around an out-of-stock item: give the step the in-stock option, or note that the item is unavailable while the other steps go ahead.

## Show it

- Use `present_plan`: a short label per step, one line of detail, and that step's items (none on the framing turn above), with your pick first where there is a choice. Keep the prose before it to a sentence or two.
- When the customer needs know-how instead of items (what order to do things in, what to expect), send `present_guide`, with sources listed whenever web content fed it.
- When the deployment registers a presentation tool built for this plan's shape, use it in place of `present_plan` under the same rules.

## Change it

- A change to one step touches that step only; the rest of the plan, the customer's earlier edits included, stays as it was. Re-present the plan after the change.
- Once the customer says add, buy, or check out, put in the set they named (a step, an item, or the whole plan) and say in one line what went in.$body$),
('marketplace:commerce-agents/commerce-agents/shopping-agent/skills/purchase-research', 'business', 'purchase-research', '', 'purchase-research', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Purchase research

Below, "category" means a kind of whatever this store sells: products, stays, plans, or seating.

The customer has a category in mind and no criteria yet. Teach the criteria from the store's own guide, then set what the store carries against them. The choice, and anything that touches the cart, stays with the customer.

## Ask once or not at all

- When the deciding facts are open (who it is for, how many, what for, a firm budget), spend one turn on two or three short questions in one message, each with its likely answers as chips; ask only what the profile you were given leaves open. This intake happens once.
- Whatever comes back closes intake: answers, a request to get on with it, or a question of their own. Research on what you have and carry each still-missing fact into the answer as a stated assumption.
- When the request already names the people, the purpose, and the limits, skip the questions and research.
- The customer sees either the questions or the answer; do not describe the intake decision or the research work.

## Where the criteria and the products come from

- Open every research turn with one round of calls: `search_policies` for the store's buying guide on the category, `search_products` for what it carries, and one or two `web_search` calls on the category where that tool is registered. Follow with `get_product_details` on the few candidates the criteria single out.
- Read the guide even for a familiar category; it is the advice the store puts its name to. Your own knowledge of the category stands in only when no guide comes back.
- Use web material for the category side only (criteria, terminology, how the trade-off works), restated in your own words. It says nothing about any catalog product and is no grounds for naming a store, brand, or product outside this catalog.
- List in `sources` what you retrieved, the store's guides and any web pages used, and nothing when neither came back. Leave out a criterion none of the retrieved guides or records support.

## Shape of the answer

- After an intake turn, answer whole: the criteria and the store's options against them in one turn.
- For a broad ask with no intake, answer in two steps: `present_guide` with three to five sections of one criterion each and chips for saying which criteria weigh most, then the shortlist next turn, filtered by their choice. Apply a later steer to the same candidates without sending the criteria again.
- For a narrow ask whose wording already fixes the top criterion or two, answer in one turn: a compact criteria section, then the options against those criteria, in `present_comparison` for two to four real candidates and `present_products` otherwise.
- Show the store's real position. Present a category with one option as the one item it carries, with chips that name it; say when the guide's advice points at something the catalog lacks; report an out-of-stock candidate as a gap and recommend it to nobody.
- Name the pick with the criterion that decided it, in one clause. Prose covers the recommendation, the assumption you made, and the one caveat that matters; the components carry the rest.

## Scope

- Research turns read and recommend. Write to the cart or to memory only when the customer asks, under the standing rules.
- Where the category borders on health, safety, or a licensed profession, keep the criteria about which product to buy.
- Add a purchase chip only once the customer has seen the criteria.$body$),
('marketplace:commerce-agents/commerce-agents/shopping-agent/skills/search-discovery', 'business', 'search-discovery', '', 'search-discovery', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:commerce-agents', '', $body$# Search and discovery

Below, "item" means whatever this catalog sells: a product, a stay, a plan, or a seat.

Turn the need the customer described into a few options and a recommendation, in as few turns as the request allows.

## Read the request and phrase the search

- Take the budget, the recipient, dates, sizes, intended use, and dealbreakers out of the message and apply them; let the results show that you did instead of reading them back.
- Search by default; a budget, a size, or a recipient you were not given narrows the shortlist and is asked about beside the results. Ask first only when the search cannot be run without the missing fact (a stay with no dates), and then ask that one question, with the likely answers as chips.
- Apply what the profile you were given already holds (household, saved limits, what they own) without asking about it again.
- Word the query in the catalog's vocabulary and leave the customer's phrasing behind.
- Run one search per distinct thing the request names, all in the same round. Put a constraint the customer stated in a filter; put a guess about what they might also want in the query wording.

## Shortlist and recommendation

- Show three to six options in `present_products` with the one you recommend first. Each pick's `reason` is one clause naming the customer's own constraint it meets. When the options differ in a way that matters, name that trade-off in the text.
- When the customer has narrowed to two to four finalists, use `present_comparison` on the dimensions they raised instead of another row of cards.
- Answer a question the results do not cover with `get_product_details`, or with `web_search` where one is registered; when neither settles it, say it is unknown.
- Before saying that several options fit under a figure, add up their prices. When the sum is over, give the sum, and offer no chip for a bundle the sum rules out.
- Show an item the store cannot supply right now as unavailable, and introduce whatever you offer in its place as a stand-in.
- Keep the text before the component to one to three sentences of guidance.

## When the item is for someone else

- Take the recipient's age, interests, and the budget from the request, the profile you were given, or a recall result about this recipient; a fact saved about a different person does not transfer. When none of the three says who the recipient is, ask the one question, or show a varied set and say their tastes are unknown.
- Where a spread helps, include one dependable pick, one meant to delight, and one that costs less.
- Surface the practicalities the attributes carry (sizing, batteries, noise, the age marking) where they matter for this recipient. Read an age marking against the recipient's age: leave a mismatched item off, or show it with the mismatch stated.$body$),
('marketplace:financial-services/financial-services/claude-for-msft-365-install/.claude/skills/verify', 'finance', 'verify', '', 'verify', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Verifying claude-for-msft-365-install

This plugin is **admin CLI tooling**, not an app. There is nothing to build and
no server to boot. The surface is the terminal: `scripts/*.sh` on macOS,
`scripts/*.ps1` on Windows.

## Lint gate

```bash
python3 scripts/check.py           # from the REPO ROOT, not the plugin dir
bash -n claude-for-msft-365-install/scripts/<script>.sh
```

`check.py` lints every manifest and self-installs the pre-commit hook that
patch-bumps `.claude-plugin/plugin.json`. Run it before committing.

## Drive the scripts against a fake $HOME

Every macOS script resolves Office paths from `$HOME`, so overriding it gives a
throwaway sandbox — you can exercise the destructive `--apply` paths without
touching real Office data.

```bash
S=<scratchpad>/sandbox
for app in Excel Word Powerpoint; do
  mkdir -p "$S/Library/Containers/com.microsoft.$app/Data/Documents/wef"
done
printf '<x/>' > "$S/Library/Containers/com.microsoft.Excel/Data/Documents/wef/aaaaaaaa-1111-1111-1111-111111111111.manifest-a.xml"

HOME=$S ./scripts/clear-addin-cache.sh                      # list
HOME=$S ./scripts/clear-addin-cache.sh --id <GUID>          # dry-run
HOME=$S ./scripts/clear-addin-cache.sh --id <GUID> --apply  # destructive
```

Seed at least **two IDs across two apps**, with **mixed upper/lowercase**. Both
properties have caught real bugs: cross-app blast radius, and a case-sensitive
glob that reported "already clear" and sent admins to a folder-wide wipe.

## Prove storage is retained

The load-bearing claim of this plugin is that clearing a manifest never touches
the user's chat history. Verify it by snapshot-diffing both trees around the
operation, against the **real** `$HOME`:

```bash
snap() {
  for app in Excel Word Powerpoint; do
    find "$HOME/Library/Containers/com.microsoft.$app/Data/Library/WebKit/WebsiteData" \
         -type f -exec stat -f '%N %z %m' {} \; 2>/dev/null
    find "$HOME/Library/Containers/com.microsoft.$app/Data/Documents/wef" \
         -type f -exec stat -f 'WEF %N %z' {} \; 2>/dev/null
  done | sort
}
snap > before.txt;  <run the script>;  snap > after.txt;  diff before.txt after.txt
```

Manifests live in `Data/Documents/wef`; storage lives in
`Data/Library/WebKit/WebsiteData`. Different subtrees — the diff should show
only the manifest you removed. **Restore any planted files and re-diff to
confirm you left the machine as you found it.**

## Gotchas

- **The Bash tool runs zsh.** Scripts are `#!/usr/bin/env bash`; test bash-only
  behaviour (`shopt`, glob semantics) inside `bash <<'EOF' … EOF`, not inline.
- **`PRAGMA integrity_check` and `SELECT count(*)` fail on exported IndexedDB
  files** with `no such collation sequence: IDBKEY`. That is WebKit's custom
  collation, not corruption — it fails on the source file too. Verify
  completeness with `SELECT sum(length(value)) FROM Records;` on both sides.
- **Never claim the `.ps1` scripts work without running them on Windows.**
  macOS has no PowerShell, so a `.ps1` change verified only here is unverified.
  Run it on a real Windows host against Windows PowerShell 5.1, and always
  include a **parse check** before the behavioural ones:

  ```powershell
  $e = $null
  [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content -Raw .\clear-addin-cache.ps1), [ref]$e) | Out-Null
  if ($e.Count) { $e | ForEach-Object { $_.Message } } else { 'parse ok' }
  ```

  A file can be perfectly fine on macOS and fail to parse outright on Windows
  (see the ASCII note below), so parsing is the first thing to establish.

- **`.ps1` files must be pure ASCII** (enforced by `scripts/check.py`).
  Windows PowerShell 5.1 reads a BOM-less `.ps1` as ANSI, so an em dash decodes
  to mojibake containing `"`, which terminates a string and breaks the parse.
  `clear-addin-cache.ps1` shipped broken this way and no macOS check caught it.
- Probe the arg parser. `--flag` as the final argument makes `shift 2` fail
  under `set -e` and exits 1 with **no output**; each flag needs a
  `[ $# -ge 2 ]` guard.$body$),
('marketplace:financial-services/financial-services/plugins/agent-plugins/earnings-reviewer/skills/audit-xls', 'finance', 'audit-xls', '', 'audit-xls', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:financial-services', '', $body$# Audit Spreadsheet

Audit formulas and data for accuracy and mistakes. Scope determines depth — from quick formula checks on a selection up to full financial-model integrity audits.

## Step 1: Determine scope

If the user already gave a scope, use it. Otherwise **ask them**:

> What scope do you want me to audit?
> - **selection** — just the currently selected range
> - **sheet** — the current active sheet only
> - **model** — the whole workbook, including financial-model integrity checks (BS balance, cash tie-out, roll-forwards, logic sanity)

The **model** scope is the deepest — use it for DCF, LBO, 3-statement, merger, comps, or any integrated financial model before sending to a client or IC.

---

## Step 2: Formula-level checks (ALL scopes)

Run these regardless of scope:

| Check | What to look for |
|---|---|
| Formula errors | `#REF!`, `#VALUE!`, `#N/A`, `#DIV/0!`, `#NAME?` |
| Hardcodes inside formulas | `=A1*1.05` — the `1.05` should be a cell reference |
| Inconsistent formulas | A formula that breaks the pattern of its neighbors in a row/column |
| Off-by-one ranges | `SUM`/`AVERAGE` that misses the first or last row |
| Pasted-over formulas | Cell that looks like a formula but is actually a hardcoded value |
| Circular references | Intentional or accidental |
| Broken cross-sheet links | References to cells that moved or were deleted |
| Unit/scale mismatches | Thousands mixed with millions, % stored as whole numbers |
| Hidden rows/tabs | Could contain overrides or stale calculations |

---

## Step 3: Model-integrity checks (MODEL scope only)

If scope is **model**, identify the model type (DCF / LBO / 3-statement / merger / comps / custom) and run the appropriate integrity checks below.

### 3a. Structural review

| Check | What to look for |
|---|---|
| Input/formula separation | Are inputs clearly separated from calculations? |
| Color convention | Blue=input, black=formula, green=link — or whatever the model uses, applied consistently? |
| Tab flow | Logical order (Assumptions → IS → BS → CF → Valuation)? |
| Date headers | Consistent across all tabs? |
| Units | Consistent (thousands vs millions vs actuals)? |

### 3b. Balance Sheet

| Check | Test |
|---|---|
| BS balances | Total Assets = Total Liabilities + Equity (every period) |
| RE rollforward | Prior RE + Net Income − Dividends = Current RE |
| Goodwill/intangibles | Flow from acquisition assumptions (if M&A) |

If BS doesn't balance, **quantify the gap per period and trace where it breaks** — nothing else matters until this is fixed.

### 3c. Cash Flow Statement

| Check | Test |
|---|---|
| Cash tie-out | CF Ending Cash = BS Cash (every period) |
| CF sums | CFO + CFI + CFF = Δ Cash |
| D&A match | D&A on CF = D&A on IS |
| CapEx match | CapEx on CF matches PP&E rollforward on BS |
| WC changes | Signs match BS movements (ΔAR, ΔAP, ΔInventory) |

### 3d. Income Statement

| Check | Test |
|---|---|
| Revenue build | Ties to segment/product detail |
| Tax | Tax expense = Pre-tax income × tax rate (allow for deferred tax adj) |
| Share count | Ties to dilution schedule (options, converts, buybacks) |

### 3e. Circular references

- Interest → debt balance → cash → interest is a common intentional circ in LBO/3-stmt models
- If intentional: verify iteration toggle exists and works
- If unintentional: trace the loop and flag how to break it

### 3f. Logic & reasonableness

| Check | Flag if |
|---|---|
| Growth rates | >100% revenue growth without explanation |
| Margins | Outside industry norms |
| Terminal value dominance | TV > ~75% of DCF EV (yellow flag) |
| Hockey-stick | Projections ramp unrealistically in out-years |
| Compounding | EBITDA compounds to absurd $ by Year 10 |
| Edge cases | Model breaks at 0% or negative growth, negative EBITDA, leverage goes negative |

### 3g. Model-type-specific bugs

**DCF:**
- Discount rate applied to wrong period (mid-year vs end-of-year)
- Terminal value not discounted back
- WACC uses book values instead of market values
- FCF includes interest expense (should be unlevered)
- Tax shield double-counted

**LBO:**
- Debt paydown doesn't match cash sweep mechanics
- PIK interest not accruing to principal
- Management rollover not reflected in returns
- Exit multiple applied to wrong EBITDA (LTM vs NTM)
- Fees/expenses not deducted from Day 1 equity

**Merger:**
- Accretion/dilution uses wrong share count (pre- vs post-deal)
- Synergies not phased in
- Purchase price allocation doesn't balance
- Foregone interest on cash not included
- Transaction fees not in sources & uses

**3-statement:**
- Working capital changes have wrong sign
- Depreciation doesn't match PP&E schedule
- Debt maturity schedule doesn't match principal payments
- Dividends exceed net income without explanation

---

## Step 4: Report

Output a findings table:

| # | Sheet | Cell/Range | Severity | Category | Issue | Suggested Fix |
|---|---|---|---|---|---|---|

**Severity:**
- **Critical** — wrong output (BS doesn't balance, formula broken, cash doesn't tie)
- **Warning** — risky (hardcodes, inconsistent formulas, edge-case failures)
- **Info** — style/best-practice (color coding, layout, naming)

For **model** scope, prepend a summary line:

> Model type: [DCF/LBO/3-stmt/...] — Overall: [Clean / Minor Issues / Major Issues] — [N] critical, [N] warnings, [N] info

**Don't change anything without asking** — report first, fix on request.

---

## Notes

- **BS balance first** — if it doesn't balance, everything downstream is suspect
- **Hardcoded overrides are the #1 source of silent bugs** — search aggressively
- **Sign convention errors** (positive vs negative for cash outflows) are extremely common
- If the model uses VBA macros, note any macro-driven calculations that can't be audited from formulas alone$body$)
ON CONFLICT (skill_key) DO NOTHING;
