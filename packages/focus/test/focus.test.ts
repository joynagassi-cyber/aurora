/**
 * @aurora/focus — minimal tests (node --experimental-strip-types +
 * node:test). One test per feature, deterministic, no DOM.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  beginStart,
  computeFocusBilanScore,
  endSession,
  markActive,
  markInterrupted,
  newFocusTimer,
  newPomodoro,
  pause,
  pomodoroDisplay,
  resume,
  restore,
  tick,
  tickPomodoro,
} from '../src/index.ts';

// --- timer state machine ---------------------------------------------------

function cfgAt(ms: number) {
  return { now: () => ms };
}

test('timer: scheduled -> active -> tick -> manual end accrues activeSec', () => {
  const t0 = Date.parse('2026-09-25T09:00:00Z');
  let s = newFocusTimer(120);
  assert.equal(s.state, 'scheduled');
  s = beginStart(s);
  assert.equal(s.state, 'starting');
  s = markActive(s, cfgAt(t0));
  assert.equal(s.state, 'active');
  // 10s of the active streak elapsed
  const r = tick(s, cfgAt(t0 + 10000));
  assert.equal(r.state.activeSec, 10);
  assert.equal(r.state.state, 'active');
  // manual end 30s later: 10 + 30 = 40
  const ended = endSession(r.state, cfgAt(t0 + 40000));
  assert.equal(ended.state, 'completed');
  assert.equal(ended.endReason, 'manual');
  assert.equal(ended.activeSec, 40);
});

test('timer: planned expiry detected exactly at plannedSec', () => {
  const t0 = Date.parse('2026-09-25T09:00:00Z');
  let s = newFocusTimer(120);
  s = beginStart(s);
  s = markActive(s, cfgAt(t0));
  const justBefore = tick(s, cfgAt(t0 + 119_000));
  assert.equal(justBefore.expired, false);
  const at = tick(s, cfgAt(t0 + 120_000));
  assert.equal(at.expired, true);
  const ended = endSession(at.state, cfgAt(t0 + 120_000), 'expiry');
  assert.equal(ended.endReason, 'expiry');
  assert.equal(ended.activeSec, 120);
});

test('timer: pause/resume excludes pause time from activeSec', () => {
  const t0 = Date.parse('2026-09-25T09:00:00Z');
  let s = newFocusTimer(0);
  s = beginStart(s);
  s = markActive(s, cfgAt(t0));
  s = tick(s, cfgAt(t0 + 60_000)).state;
  s = pause(s, cfgAt(t0 + 60_000));
  assert.equal(s.state, 'paused');
  assert.equal(s.activeSec, 60);
  // paused for 90s: activeSec must NOT grow, pausedSec grows
  const still = tick(s, cfgAt(t0 + 150_000));
  assert.equal(still.state.activeSec, 60);
  assert.equal(still.state.pausedSec, 90);
  s = resume(still.state, cfgAt(t0 + 150_000));
  assert.equal(s.state, 'active');
  // 10s of a fresh active streak after the resume
  const after = tick(s, cfgAt(t0 + 160_000));
  assert.equal(after.state.activeSec, 70);
});

test('timer: crash marks interrupted, restore returns to restored', () => {
  const t0 = Date.parse('2026-09-25T09:00:00Z');
  let s = newFocusTimer(0);
  s = beginStart(s);
  s = markActive(s, cfgAt(t0));
  s = markInterrupted(s, 'crash');
  assert.equal(s.state, 'interrupted');
  assert.equal(s.endReason, 'crash');
  const restored = restore(s);
  assert.equal(restored.state, 'restored');
  assert.equal(restored.endReason, 'restoring');
});

// --- pomodoro (in-app timer + Pomodoro feature) -----------------------------

test('pomodoro: 4 focus cycles -> long break, display helper', () => {
  let p = newPomodoro();
  assert.equal(p.phase, 'focus');
  assert.equal(p.remainingSec, 25 * 60);
  const r1 = tickPomodoro(p, 25 * 60);
  assert.equal(r1.transitioned, true);
  assert.equal(r1.state.phase, 'short_break');
  assert.equal(r1.state.cyclesDone, 1);
  let q = { ...p };
  q = tickPomodoro(q, 25 * 60).state;
  q = tickPomodoro(q, 5 * 60).state;
  q = tickPomodoro(q, 25 * 60).state;
  q = tickPomodoro(q, 5 * 60).state;
  q = tickPomodoro(q, 25 * 60).state;
  q = tickPomodoro(q, 5 * 60).state;
  q = tickPomodoro(q, 25 * 60).state;
  assert.equal(q.phase, 'long_break');
  assert.equal(q.cyclesDone, 4);
  const d = pomodoroDisplay(q);
  assert.equal(d.label, 'Long break');
  assert.equal(d.min, 15);
});

// --- bilan score (G-H1) -----------------------------------------------------

test('bilan: perfect session with all tasks = 100', () => {
  const r = computeFocusBilanScore({
    plannedMinutes: 30,
    actualMinutes: 30,
    interruptions: 0,
    plannedTaskCount: 2,
    completedTaskCount: 2,
  });
  assert.equal(r.score, 100);
});

test('bilan: interruptions penalize, over-time caps adherence at 100', () => {
  const r = computeFocusBilanScore({
    plannedMinutes: 30,
    actualMinutes: 45,
    interruptions: 2,
  });
  // 100*0.5 + 70*0.3 + 100*0.2 = 91
  assert.equal(r.score, 91);
  assert.equal(r.interruptionPenalty, 70);
});

test('bilan: short session scores low adherence', () => {
  const r = computeFocusBilanScore({
    plannedMinutes: 60,
    actualMinutes: 15,
    interruptions: 0,
  });
  assert.equal(r.adherence, 25);
  // 25*0.5 + 100*0.3 + 100*0.2 = 62.5
  assert.equal(r.score, 62.5);
});
