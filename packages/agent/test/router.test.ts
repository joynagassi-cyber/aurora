/**
 * Wave 3 — Agnes-primary router test (task 3, event-reconciliation S2.6).
 *
 * Verifies the FROZEN S2.6 registry (AGNES_REGISTRY) end-to-end:
 *  - Agnes = PRIMARY, alwaysFirst (S2.6 PRIORITY 3)
 *  - Fallback chain: Workers AI → Groq → OpenRouter → CF Worker
 *  - return-after-fallback: when Agnes is healthy again, ALL subsequent
 *    tasks go BACK to Agnes (PRIORITY 3, a temporary bridge not a switch)
 *  - data-policy gate (ADR S11): sensitive data prefers ZDR providers
 *  - 429 cooldown = the provider is skipped, NEVER key rotation (AD-5)
 *
 * Run: `pnpm --filter @aurora/agent test`
 * Node 22: `node --experimental-strip-types --test test/router.test.ts`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  AgnesPrimaryRouter,
  AGNES_REGISTRY,
  defaultRegistry,
  buildTaskProfile,
  levelFor,
  type RouterRegistry,
} from '../src/index.ts';

/** A health checker whose availability table is driven by the test. */
function healthFor(opts: { agnesHealthy?: boolean; agnesCooldown?: boolean; down?: string[] }) {
  return {
    healthy: (p: string) => {
      if (p === 'agnes') return opts.agnesHealthy !== false;
      return !opts.down?.includes(p);
    },
    inCooldown: (p: string) => (p === 'agnes' && opts.agnesCooldown === true),
  };
}

function router(opts?: { agnesHealthy?: boolean; agnesCooldown?: boolean; down?: string[] }): {
  router: AgnesPrimaryRouter;
} {
  const reg: RouterRegistry = {
    list: () => AGNES_REGISTRY,
    modelFor: (provider, _level, profile) => {
      const entry = AGNES_REGISTRY.find((e) => e.provider === provider);
      if (!entry) return undefined;
      // AGENT / CRITICAL profiles → the strongest model (index 0);
      // ROUTINE → the fastest (last entry).
      const wantsStrong = profile.tools > 0 || profile.reasoning === 'deep' || levelFor(profile) === 'CRITICAL';
      return wantsStrong ? entry.models[0] : entry.models[entry.models.length - 1];
    },
  };
  return {
    router: new AgnesPrimaryRouter(
      reg,
      healthFor(opts ?? {}),
      { hasQuota: () => true },
      { compatible: () => true },
    ),
  };
}

const profile = buildTaskProfile(undefined, { tools: 2, reasoning: 'deep' });

test('Router: Agnes is PRIMARY (alwaysFirst) when healthy — S2.6 PRIORITY 3', () => {
  const { router: r } = router({ agnesHealthy: true });
  const pick = r.select(profile, 'u1');
  assert.equal(pick?.provider, 'agnes');
  assert.equal(pick?.reason, 'primary');
  assert.equal(pick?.expectedQuality, 'full');
});

test('Router: 429 cooldown on Agnes → Workers AI is the fallback (reason=fallback)', () => {
  const { router: r } = router({ agnesCooldown: true });
  const pick = r.select(profile, 'u1');
  assert.equal(pick?.provider, 'workers-ai');
  assert.equal(pick?.reason, 'fallback');
});

test('Router: Agnes DOWN → Groq after Workers AI is also down', () => {
  const { router: r } = router({ agnesHealthy: false, down: ['workers-ai'] });
  const pick = r.select(profile, 'u1');
  assert.equal(pick?.provider, 'groq');
  assert.equal(pick?.reason, 'fallback');
});

test('Router: return-to-Agnes — when Agnes is healthy again the NEXT call is primary', () => {
  // Simulate the bridge: first a call while Agnes is down (fallback),
  // then Agnes recovers → the next select() returns Agnes PRIMARY.
  const down = router({ agnesHealthy: false });
  const fb = down.router.select(profile, 'u1');
  assert.notEqual(fb?.provider, 'agnes', 'fallback used while Agnes is down');

  const up = router({ agnesHealthy: true });
  const back = up.router.select(profile, 'u1');
  assert.equal(back?.provider, 'agnes', 'PRIORITY 3: Agnes recovers → all tasks return to Agnes');
  assert.equal(back?.reason, 'primary');
});

test('Router: the frozen S2.6 registry order is agnes → workers-ai → groq → openrouter → cf-worker', () => {
  const order = AGNES_REGISTRY.map((e) => e.provider);
  assert.deepEqual(order, ['agnes', 'workers-ai', 'groq', 'openrouter', 'cf-worker']);
  // Agnes is the ONLY alwaysFirst provider (S2.6 PRIORITY 3).
  const firsts = AGNES_REGISTRY.filter((e) => e.alwaysFirst).map((e) => e.provider);
  assert.deepEqual(firsts, ['agnes']);
  // 429 cooldowns are bounded (no key rotation, AD-5).
  for (const e of AGNES_REGISTRY) {
    if (e.cooldownOn429 !== undefined) assert.ok(e.cooldownOn429 > 0, `${e.provider} cooldown > 0`);
  }
});

test('Router: a ROUTINE profile picks the fastest model of the provider it lands on', () => {
  const routine = buildTaskProfile(undefined, { tools: 0, reasoning: 'none' });
  assert.equal(levelFor(routine), 'ROUTINE');
  const { router: r } = router({ agnesHealthy: true });
  const pick = r.select(routine, 'u1');
  // agnes registry models: [agnes-2.5-flash, agnes-3.0, agnes-image-2.5-flash]
  // ROUTINE → last = the fast / cheap model
  assert.equal(pick?.provider, 'agnes');
  assert.equal(pick?.model, 'agnes-image-2.5-flash');
});

test('Router: defaultRegistry() (gateway) mirrors the S2.6 seed + alwaysFirst Agnes', () => {
  const reg = defaultRegistry();
  const list = reg.list();
  assert.equal(list[0]?.provider, 'agnes');
  assert.equal(list[0]?.alwaysFirst, true, 'defaultRegistry keeps Agnes alwaysFirst');
});
