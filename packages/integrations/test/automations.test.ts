/**
 * @aurora/integrations — automations tests (AD-8 idempotency, AD-15
 * closed JobKind, JobCompleted consumer).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  INTEGRATIONS_JOB_HANDLERS,
  automationDedupKey,
  buildAutomationJobPayload,
  cronInsertSql,
  filterJobCompletedForAutomation,
  isJobKind,
} from '../src/automations.ts';
import type { Automation, JobCompletedEvent } from '@aurora/domain';

const automation: Automation = {
  id: 'auto-1',
  userId: 'u-1',
  name: 'Daily reminder sweep',
  trigger: 'schedule',
  cron: '0 8 * * *',
  jobKind: 'notification',
  action: 'reminder-sweep',
  enabled: true,
  createdAt: '2026-09-25T00:00:00Z',
  updatedAt: '2026-09-25T00:00:00Z',
};

/** AD-8: deterministic dedup key (kind|automationId|minute) — re-
 *  dispatch of the same tick is a no-op. */
test('automations: dedup key is deterministic', () => {
  const a = automationDedupKey('auto-1', 1000, 'notification');
  const b = automationDedupKey('auto-1', 1000, 'notification');
  assert.equal(a, b);
  assert.equal(a, 'notification|auto-1|1000');
  const c = automationDedupKey('auto-1', 1001, 'notification');
  assert.notEqual(a, c);
});

/** AD-15: unknown jobKind on an automation row degrades to
 *  `notification` (closed 11-kind vocabulary, no 12th kind). */
test('automations: unknown kind degrades to notification', () => {
  const p = buildAutomationJobPayload(
    { ...automation, jobKind: 'speak_to_me_please' },
    42,
  );
  assert.equal(p.jobKind, 'notification');
  assert.equal(isJobKind(p.jobKind), true);
  // and valid kinds pass through
  const p2 = buildAutomationJobPayload(
    { ...automation, jobKind: 'agent_run' },
    42,
  );
  assert.equal(p2.jobKind, 'agent_run');
});

/** The cron INSERT is idempotent (ON CONFLICT DO NOTHING +
 *  deterministic idempotency_key). */
test('automations: cron SQL carries the dedup key', () => {
  const sql = cronInsertSql(automation, 1730000000, 'job-xyz');
  assert.match(sql, /ON CONFLICT DO NOTHING/);
  assert.match(sql, /notification\|auto-1\|1730000000/);
  assert.match(sql, /job-xyz/);
});

/** Handler idempotent-replay: a re-dispatched job with a stale dedup
 *  key is reported as skipped (AD-8). */
test('automations: notification handler skips idempotent replays', async () => {
  const handler = INTEGRATIONS_JOB_HANDLERS[0].handler;
  const payload = buildAutomationJobPayload(automation, 100);
  payload.tick = 100;
  const ok = await handler('job-1', 'u-1', payload);
  assert.equal(ok.ok, true);
  assert.equal((ok.result as { skipped?: string }).skipped, undefined);

  // replay with a mismatched dedup key → skip
  const replay = { ...payload, dedupKey: automationDedupKey('auto-1', 999, 'notification') };
  const out = await handler('job-1', 'u-1', replay);
  assert.equal(out.ok, true);
  assert.equal((out.result as { skipped?: string }).skipped, 'idempotent-replay');
});

/** JobCompleted consumer: events observed via the events table,
 *  filtered by automation (userId + jobKind). */
test('automations: JobCompleted filter is userId+jobKind scoped', () => {
  const events: JobCompletedEvent[] = [
    {
      eventId: 'e-1',
      occurredAt: '2026-09-25T08:00:00Z',
      type: 'JobCompleted',
      payload: { jobId: 'j-1', jobKind: 'notification', userId: 'u-1', status: 'done' },
    },
    {
      eventId: 'e-2',
      occurredAt: '2026-09-25T08:00:00Z',
      type: 'JobCompleted',
      payload: { jobId: 'j-2', jobKind: 'notification', userId: 'u-2', status: 'done' },
    },
    {
      eventId: 'e-3',
      occurredAt: '2026-09-25T08:00:00Z',
      type: 'JobCompleted',
      payload: { jobId: 'j-3', jobKind: 'agent_run', userId: 'u-1', status: 'failed' },
    },
  ];
  const out = filterJobCompletedForAutomation(events, {
    userId: 'u-1',
    jobKind: 'notification',
  });
  assert.deepEqual(out.map((e) => e.eventId), ['e-1']);
});
