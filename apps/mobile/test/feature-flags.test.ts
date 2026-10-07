/**
 * feature-flags.test.ts — G-M7 feature registry (docs/frontend/
 * feature-registry.md S1/S2/S8, roadmap 10-07). Contratuel node:test :
 * la résolution (URL > user_context > seed) + le parsing `?feature` sont
 * purs → testables sans React / DOM / réseau.
 *
 * Run: node --experimental-strip-types --no-warnings
 *        --test apps/mobile/test/feature-flags.test.ts
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  FEATURE_MODULES,
  GATED_FEATURES,
  parseFeatureOverride,
  resolveFeatureEnabled,
} from '../src/feature-registry.ts';

test('FEATURE_MODULES seed : les 8 modules cibles + 7 cœurs existent (S8)', () => {
  const ids = FEATURE_MODULES.map((m) => m.id);
  for (const id of GATED_FEATURES) {
    assert.ok(ids.includes(id), `module cible manquant dans la seed: ${id}`);
  }
  assert.equal(FEATURE_MODULES.length, 15, 'seed = 7 cœurs + 8 cibles');
});

test('seed : tous les modules start ON (le flag COUPE, ne masque pas)', () => {
  for (const m of FEATURE_MODULES) {
    assert.equal(m.enabledByDefault, true, `module ${m.id} doit être ON par défaut`);
  }
});

test('resolve : seed par défaut quand ni user ni URL (S2 chain)', () => {
  assert.equal(resolveFeatureEnabled('calendar', null, undefined), true);
  assert.equal(resolveFeatureEnabled('unknown-module', null, undefined), false);
});

test('resolve : user_context.features gagne sur la seed', () => {
  assert.equal(resolveFeatureEnabled('focus', { focus: false }, undefined), false);
  assert.equal(resolveFeatureEnabled('knowledge', { focus: false }, undefined), true);
});

test('resolve : le URL override (séance) gagne sur user + seed', () => {
  assert.equal(
    resolveFeatureEnabled('discovery', { discovery: false }, { discovery: true }),
    true,
    'URL force ON',
  );
  assert.equal(
    resolveFeatureEnabled('skills', { skills: true }, { skills: false }),
    false,
    'URL force OFF',
  );
});

test('parseFeatureOverride : ?feature=a,b → ON ; -x → OFF (séance)', () => {
  assert.deepEqual(
    parseFeatureOverride({ feature: 'calendar,-focus' }),
    { calendar: true, focus: false },
  );
  assert.deepEqual(
    parseFeatureOverride({ features: 'inbox, canvas' }),
    { inbox: true, canvas: true },
  );
  assert.equal(parseFeatureOverride({}), undefined, 'sans paramètre → undefined');
  assert.equal(parseFeatureOverride({ feature: '   ' }), undefined, 'vide → undefined');
  // Paramètre répété (?feature=a&feature=b) : les deux comptent.
  assert.deepEqual(
    parseFeatureOverride({ feature: ['a', 'b'] }),
    { a: true, b: true },
  );
});
