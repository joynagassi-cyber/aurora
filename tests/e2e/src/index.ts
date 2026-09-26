/**
 * @aurora/e2e — OQ-08 E2E runner (wave 4, HARPYS).
 *
 * The 20 E2E agent scenarios (master mission S60) and the 23 composite
 * workflows live in `@aurora/workflows` as the deterministic tracing spec.
 * OQ-08 assumes Playwright-on-device for the actual execution; until that
 * tooling lands, this package hosts the runner skeleton that replays the
 * scenario contracts against a device stub, plus the Playwright config.
 *
 * The package deliberately keeps ZERO business logic: it is the thin
 * bridge between the @aurora/workflows spec and the device.
 */
import {
  WORKFLOWS, E2E_SCENARIOS, ERROR_CLASSES,
  allEmittedEvents,
  type E2EScenario,
} from '@aurora/workflows';

export { WORKFLOWS, E2E_SCENARIOS, ERROR_CLASSES, allEmittedEvents };
export type { E2EScenario };

/** Minimal device stub contract — the Playwright device exposes this. */
export interface DeviceStub {
  /** run one utterance through the agent and return the UI state change */
  runScenario(scenario: E2EScenario): Promise<{ result: string; events: readonly string[] }>;
}

/**
 * Replay every E2E scenario against a device stub. This is the deterministic
 * portion of OQ-08: the device is injected so the runner works in CI
 * (stub) and on a real Playwright device (real implementation).
 */
export async function runAllScenarios(device: DeviceStub): Promise<readonly string[]> {
  const results: string[] = [];
  for (const s of E2E_SCENARIOS) {
    const { result, events } = await device.runScenario(s);
    // AD-9: only the 9 events may be observed on the device surface.
    for (const e of events) {
      if (!allEmittedEvents().includes(e)) {
        throw new Error(`scenario ${s.id} observed unknown event ${e} (AD-9 violation)`);
      }
    }
    results.push(`${s.id}: ${result}`);
  }
  return results;
}
