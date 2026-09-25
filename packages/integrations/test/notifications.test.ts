/**
 * @aurora/integrations — notification split tests (04 §7 anti-double-push,
 * §3.4 split rule, §7.2e key anti-leak).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  assertNoDoublePush,
  createOneSignalServerClient,
  decideChannel,
  isWithinQuietHours,
} from '../src/notifications.ts';
import type { NotificationPlan, NotificationRequest } from '../src/notifications.ts';

const pref = {
  enabled: true,
  quietHours: ['22:00-07:00'],
  channels: ['push', 'local', 'in-app'],
};

/** §3.4: a local-deadline-driven request routes to the LOCAL channel
 *  ONLY — the server never pushes that object (anti-double-push core). */
test('split: local-deadline request → local channel only', () => {
  const req: NotificationRequest = {
    userId: 'u-1',
    title: 'Focus timer end',
    body: '25:00 Pomodoro done',
    priority: 'reminder',
    localDeadline: '2026-09-25T09:00:00Z',
    nowIso: '2026-09-25T08:00:00Z',
  };
  const plan = decideChannel(req, pref);
  assert.equal(plan.channel, 'local');
  assert.equal(plan.local?.scheduledFor, req.localDeadline);
  assert.equal(plan.onesignal, undefined); // never both (04 §7)
  assert.equal(assertNoDoublePush(plan), true);
});

/** No local deadline, outside quiet hours, push channel allowed →
 *  push, and the plan carries ONLY the OneSignal block. */
test('split: server-state request → push channel only', () => {
  const req: NotificationRequest = {
    userId: 'u-1',
    title: 'Coaching check-in',
    body: 'How is the week going?',
    priority: 'coach',
    nowIso: '2026-09-25T09:00:00Z', // 09:00 UTC outside 22:00-07:00
  };
  const plan = decideChannel(req, pref);
  assert.equal(plan.channel, 'push');
  assert.deepEqual(plan.onesignal?.userIds, ['u-1']);
  assert.equal(plan.local, undefined);
  assert.equal(assertNoDoublePush(plan), true);
});

/** Global kill-switch → suppressed (state, not deletion, §15). */
test('split: disabled prefs → suppressed', () => {
  const req: NotificationRequest = {
    userId: 'u-1',
    title: 'T',
    body: 'B',
    priority: 'alert',
    nowIso: '2026-09-25T09:00:00Z',
  };
  const plan = decideChannel(req, { enabled: false, channels: [] });
  assert.equal(plan.suppressed, 'disabled');
  assert.equal(plan.onesignal, undefined);
  assert.equal(plan.local, undefined);
});

/** Quiet-hours: within 22:00-07:00 (UTC) → push deferred, still ONE
 *  channel (suppression = state, §15). */
test('quiet-hours: 23:00 defers the push, single channel kept', () => {
  const req: NotificationRequest = {
    userId: 'u-1',
    title: 'T',
    body: 'B',
    priority: 'coach',
    nowIso: '2026-09-25T23:00:00Z',
  };
  const plan = decideChannel(req, pref);
  assert.equal(plan.channel, 'push');
  assert.equal(plan.suppressed, 'quiet-hours');
  assert.equal(plan.onesignal?.deliveryTimeForced !== undefined, true);
  assert.equal(plan.local, undefined);
  assert.equal(assertNoDoublePush(plan), true);
});

/** Parser: cross-midnight windows + malformed entries are safe. */
test('quiet-hours: window parser is cross-midnight + safe', () => {
  assert.equal(isWithinQuietHours(['22:00-07:00'], '2026-09-25T23:30:00Z'), true);
  assert.equal(isWithinQuietHours(['22:00-07:00'], '2026-09-25T06:30:00Z'), true);
  assert.equal(isWithinQuietHours(['22:00-07:00'], '2026-09-25T08:00:00Z'), false);
  assert.equal(isWithinQuietHours(['not-a-window'], '2026-09-25T08:00:00Z'), false);
  assert.equal(isWithinQuietHours(undefined, '2026-09-25T08:00:00Z'), false);
});

/** §7.2e anti-leak: the server key is env-only; an unconfigured
 *  client reports not-configured and send degrades (no crash). */
test('onesignal: key anti-leak + degrade-first send', async () => {
  const prevApp = process.env.ONESIGNAL_APP_ID;
  const prevKey = process.env.ONESIGNAL_REST_API_KEY;
  process.env.ONESIGNAL_APP_ID = '';
  process.env.ONESIGNAL_REST_API_KEY = '';
  try {
    const c = createOneSignalServerClient();
    assert.equal(c.isConfigured(), false);
    const plan: NotificationPlan = {
      channel: 'push',
      onesignal: {
        appId: '',
        userIds: ['u-1'],
        title: 'T',
        body: 'B',
      },
    };
    const out = await c.send(plan);
    assert.equal(out.accepted, false);
    assert.equal(out.reason, 'onesignal_not_configured');
  } finally {
    if (prevApp === undefined) delete process.env.ONESIGNAL_APP_ID;
    else process.env.ONESIGNAL_APP_ID = prevApp;
    if (prevKey === undefined) delete process.env.ONESIGNAL_REST_API_KEY;
    else process.env.ONESIGNAL_REST_API_KEY = prevKey;
  }
});
