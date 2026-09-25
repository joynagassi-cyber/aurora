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
} from './lifecycle';

export {
  createNetworkStatusAdapter,
  type NetworkStatusAdapter,
} from './network';

export {
  createRemoteNotificationAdapter,
  type RemoteNotificationAdapter,
  type OneSignalNotification,
} from './remote-notification';

export {
  createLocalNotificationAdapter,
  type LocalNotificationAdapter,
  type LocalNotification,
} from './local-notification';
