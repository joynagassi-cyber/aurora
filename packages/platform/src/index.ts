/**
 * @aurora/platform — Capacitor adapters behind interfaces (04 S3.2, AD-1).
 *
 * The ONLY native surface the app consumes (AD-16c, owner Foundation).
 * Vendor SDKs (@capacitor/*, OneSignal) live HERE — never in the app
 * shell or feature slices (04 §7.2 anti-coupling test). Each adapter =
 * one implementation behind one typed port.
 */

export {
  createAppLifecycleAdapter,
  type AppLifecycleAdapter,
  type AppState,
} from './lifecycle.ts';

export {
  createNetworkStatusAdapter,
  type NetworkStatusAdapter,
} from './network.ts';

export {
  createRemoteNotificationAdapter,
  type RemoteNotificationAdapter,
  type OneSignalNotification,
} from './remote-notification.ts';

export {
  createLocalNotificationAdapter,
  type LocalNotificationAdapter,
  type LocalNotification,
} from './local-notification.ts';

export {
  type BlocklistPrecheck,
  type DpcBridge,
  type DpcSuspendResult,
  type FocusControllerDpc,
  type PrecheckPackage,
} from './dpc.ts';

export {
  DpcAdapter,
  createDpcAdapter,
} from './dpc-adapter.ts';

export {
  reconcileOnBoot,
  applyRecovery,
  type SessionRow,
  type RecoveryDecision,
} from './boot-receiver.ts';

export {
  computeFocusBilanScore,
  type BilanInput,
  type FocusBilanScore,
} from './bilan.ts';
