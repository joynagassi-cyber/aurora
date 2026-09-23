// Local notification invariants (04 S3.4): schedule / cancel / reduce-for-focus.
//
// Run: node --experimental-strip-types --no-warnings packages/data/test/notifications.test.ts

import {
  InMemoryNotificationTransport,
  LocalNotificationAdapter,
} from '../src/index.ts';

let failures = 0;
function check(cond: boolean, msg: string): void {
  if (!cond) {
    failures++;
    console.error(`FAIL: ${msg}`);
  } else {
    console.log(`ok: ${msg}`);
  }
}

function main(): void {
  const transport = new InMemoryNotificationTransport();
  const adapter = new LocalNotificationAdapter(transport);

  const now = 1_700_000_000_000;
  adapter.scheduleLocal('focus-end', now + 60_000, {
    title: 'Focus session ended',
    route: '/focus/bilan',
    priority: 'primary',
  });
  adapter.scheduleLocal('review-due', now + 30_000, {
    title: 'Review due',
    route: '/learning/reviews',
    priority: 'secondary',
  });
  check(adapter.pending().length === 2, 'two scheduled notifications are pending');
  check(transport.pending.size === 2, 'transport mirrors the adapter table');

  // cancel a pending one (04 S3.2.5)
  adapter.cancelLocal('review-due');
  check(adapter.pending().length === 1, 'cancelled notification is dropped');
  check(transport.pending.has('review-due') === false, 'transport cancel is propagated');

  // fired notifications are not cancellable
  adapter.markFired('focus-end');
  check(adapter.pending().length === 0, 'fired notification leaves the pending table');
  adapter.cancelLocal('focus-end');
  check(adapter.pending().length === 0, 'cancelling a fired id is a no-op');

  // reduce-for-focus: secondary is deferred to the Focus end, primary keeps its time
  adapter.scheduleLocal('primary-a', now + 10_000, { title: 'p', priority: 'primary' });
  adapter.scheduleLocal('secondary-b', now + 10_000, { title: 's', priority: 'secondary' });
  adapter.reduceForFocus(true, now + 90_000);
  check(
    adapter.pending().find((n) => n.id === 'secondary-b')?.atMs === now + 90_000,
    'Focus ON: secondary deferred past the Focus session end',
  );
  check(
    adapter.pending().find((n) => n.id === 'primary-a')?.atMs === now + 10_000,
    'Focus ON: primary keeps its schedule (still fires)',
  );

  if (failures > 0) {
    console.error(`notifications: ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('notifications: all invariants hold');
}

main();
