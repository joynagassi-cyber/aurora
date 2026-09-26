/**
 * ERYNIS — tests for product modes + command palette (wave 5, 1 test
 * per task, node native type-stripping, no runner dep).
 *
 * Contract tested: feature-registry S7 (six modes = profiles over the
 * registries) + S4 (palette renders FROM the capability registry,
 * filtering on availability + permissions; disabled features vanish
 * from the command list, S6 deactivation effect).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  PRODUCT_MODES,
  MODE_PROFILES,
  getModeProfile,
  effectiveEmphasis,
  type ProductMode,
} from '../src/modes/product-modes.ts';
import {
  buildCommandCatalog,
  filterCommands,
} from '../src/modes/command-palette.ts';
import type { FeatureRegistry, FeatureDescriptor, AgentCapability } from '../packages/domain/src/index.ts';

// ------------------------------------------------------------------
// Product modes
// ------------------------------------------------------------------

test('six product modes, one profile each (feature-registry S7)', () => {
  assert.equal(PRODUCT_MODES.length, 6);
  for (const m of PRODUCT_MODES) {
    assert.ok(MODE_PROFILES[m], `missing profile for ${m}`);
    assert.equal(getModeProfile(m).mode, m);
  }
});

test('minimal mode = Inbox/Tasks/Calendar front, everything else hidden-but-preserved', () => {
  const p = getModeProfile('minimal');
  assert.equal(p.emphasis['inbox'], 'front');
  assert.equal(p.emphasis['tasks'], 'front');
  assert.equal(p.emphasis['calendar'], 'front');
  assert.equal(p.emphasis['learning'], 'hidden');
  assert.equal(p.emphasis['discovery'], 'hidden');
  // "hidden-but-preserved" (S6): hidden is an emphasis, not a deletion —
  // the profile still lists the feature, the surface just drops it.
  assert.ok('learning' in p.emphasis);
});

test('exam period profile matches feature-registry S7 + S3 (context period)', () => {
  const p = getModeProfile('exam');
  assert.equal(p.emphasis['learning'], 'front');
  assert.equal(p.emphasis['progress'], 'front');
  assert.equal(p.emphasis['focus'], 'front');
  assert.equal(p.emphasis['discovery'], 'minimized');
  assert.equal(p.emphasis['advanced-analytics'], 'minimized');
  assert.equal(p.contextPeriod, 'exam');
});

test('focus-heavy mode widens notification suppression scope (focus spec §8)', () => {
  assert.equal(getModeProfile('focus-heavy').notificationScope, 'blocklist_wide');
  assert.equal(getModeProfile('core').notificationScope, 'aurora_only');
});

test('user override wins: explicitly disabled feature = hidden (feature-registry S6)', () => {
  const featureState = {
    enabled: { learning: false },
    visible: { discovery: false },
  };
  // exam mode emphasizes learning, but the user turned it off → hidden.
  assert.equal(effectiveEmphasis('exam' as ProductMode, featureState, 'learning'), 'hidden');
  // discovery visible=false → hidden even under study (where it is minimized).
  assert.equal(effectiveEmphasis('study' as ProductMode, featureState, 'discovery'), 'hidden');
  // untouched feature keeps the mode emphasis.
  assert.equal(effectiveEmphasis('exam' as ProductMode, featureState, 'progress'), 'front');
  // no user state → pure mode emphasis.
  assert.equal(effectiveEmphasis('core' as ProductMode, undefined, 'productivity'), 'front');
});

// ------------------------------------------------------------------
// Command palette (feature-registry S4)
// ------------------------------------------------------------------

/** Minimal in-memory FeatureRegistry (same shape as InMemoryFeatureRegistry). */
function reg(
  descriptors: FeatureDescriptor[],
  userEnabled: Record<string, Record<string, boolean>> = {},
): FeatureRegistry {
  const enabledOf = (id: string, userId?: string): boolean => {
    if (userId && userEnabled[id]?.[userId] !== undefined) return userEnabled[id][userId];
    return descriptors.find((d) => d.id === id)?.defaultEnabled ?? false;
  };
  return {
    list: () => descriptors,
    enabled: (id, userId) => enabledOf(id, userId),
    visible: (id, userId) => {
      const d = descriptors.find((x) => x.id === id);
      return (d?.defaultVisible ?? false) && enabledOf(id, userId);
    },
    setEnabled: (_id, _userId, _on) => {},
    get: (id) => descriptors.find((d) => d.id === id),
  };
}

const FEATURE_TASKS = 'productivity.tasks';
const FOCUS = 'productivity.focus';
const CAPS: AgentCapability[] = [
  { id: 'task.create', title: 'Créer une tâche', tool: 'tasks', risk: 'low', requiresFeatures: [FEATURE_TASKS] },
  { id: 'focus.start', title: 'Ouvrir Focus', tool: 'focus', risk: 'medium', requiresFeatures: [FOCUS] },
  { id: 'focus.block', title: 'Bloquer des apps', tool: 'focus', risk: 'high', requiresFeatures: [FOCUS] },
  { id: 'progress.analyze', title: 'Analyser Progress', tool: 'progress', risk: 'low' },
];

const DESCRIPTORS: FeatureDescriptor[] = [
  {
    id: FEATURE_TASKS,
    title: 'Tasks',
    module: 'productivity',
    status: 'stable',
    defaultEnabled: true,
    defaultVisible: true,
  },
  {
    id: FOCUS,
    title: 'Focus',
    module: 'productivity',
    status: 'stable',
    defaultEnabled: true,
    defaultVisible: true,
  },
];

test('palette catalog = capability registry filtered on availability (S4 zero-dup)', () => {
  const catalog = buildCommandCatalog({
    capabilities: CAPS,
    registry: reg(DESCRIPTORS),
    labels: { 'task.create': { label: 'Créer une tâche', shortcut: 'N' } },
  });
  const ids = catalog.map((c) => c.id);
  // capability with no requiresFeatures is always available.
  assert.ok(ids.includes('progress.analyze'));
  // focus.start is medium risk → no confirmation; focus.block is high → confirmation.
  const focusStart = catalog.find((c) => c.id === 'focus.start');
  const focusBlock = catalog.find((c) => c.id === 'focus.block');
  assert.equal(focusStart?.requiresConfirmation, false);
  assert.equal(focusBlock?.requiresConfirmation, true);
});

test('disabling a feature removes its commands from the palette (S6 deactivation effect)', () => {
  const catalog = buildCommandCatalog({
    capabilities: CAPS,
    registry: reg(DESCRIPTORS, { [FOCUS]: { u1: false } }),
    userId: 'u1',
  });
  assert.ok(catalog.every((c) => c.id !== 'focus.start' && c.id !== 'focus.block'), 'focus commands must vanish for u1');
  assert.ok(catalog.some((c) => c.id === 'task.create'), 'unrelated capability survives');
});

test('search filter is display-only, case-insensitive over label + id', () => {
  const catalog = buildCommandCatalog({ capabilities: CAPS, registry: reg(DESCRIPTORS) });
  assert.ok(filterCommands(catalog, 'creer').some((c) => c.id === 'task.create'));
  assert.ok(filterCommands(catalog, 'PROGRESS').some((c) => c.id === 'progress.analyze'));
  assert.deepEqual(filterCommands(catalog, 'nope-match'), []);
});
