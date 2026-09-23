/**
 * Integrations entities (AD-15 SSoT, 01 S4.7).
 */
import type { OrSetValue } from './crdt';

/** Connection state of an external integration (Composio vendor). */
export interface IntegrationsState {
  userId: string;
  /** the vendor / service id */
  vendor: string;
  /** the tool or connection name */
  connection: string;
  status: 'connected' | 'disconnected' | 'reauth-required' | 'unknown';
  /** when the connection was last verified */
  lastCheckedAt?: string;
  /** the tool ids exposed (01 S4.7 / registries S7) */
  toolIds?: OrSetValue[];
  updatedAt: string;
}

/**
 * An automation (ADR S2: Supabase Cron → dispatcher → persisted jobs →
 * Edge Functions). Declarative trigger + action.
 */
export interface Automation {
  id: string;
  userId: string;
  name: string;
  /** what fires the automation (event / schedule / condition) */
  trigger: 'event' | 'schedule' | 'condition';
  /** the event that fires it (one of the AD-9 9-event vocabulary) */
  triggerEvent?: string;
  /** cron expression for schedule triggers */
  cron?: string;
  /** the kind of job it enqueues (data-event-job-catalog S5) */
  jobKind?: string;
  /** the capability / tool it invokes */
  action?: string;
  enabled: boolean;
  createdAt: string;
  updatedAt: string;
}

/**
 * Notification preferences (ADR S13: cadence, silence windows,
 * intervention level controlled by the user).
 */
export interface NotificationPreference {
  userId: string;
  /** overall enabled */
  enabled: boolean;
  /** DND windows (ISO 8601 time-of-day, e.g. "22:00-07:00") */
  quietHours?: string[];
  /** cadence of proactive Coach check-ins (ADR S13) */
  coachCadence: 'off' | 'low' | 'normal' | 'high';
  /** which channels */
  channels: Array<'push' | 'local' | 'in-app'>;
  updatedAt: string;
}
