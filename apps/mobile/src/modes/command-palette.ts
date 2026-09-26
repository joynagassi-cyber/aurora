/**
 * Command palette — capability registry view (feature-registry.md S4,
 * docs/ui-libraries.md S1 "Command Palette (global search) — Radix
 * Command + shadcn").
 *
 * One capability, five entry points, ZERO duplicated business logic
 * (feature-registry S4): UI button · command palette · agent NL trigger
 * · deep link · automation all resolve to the SAME use-case /
 * capability. The palette is a pure VIEW over the capability registry,
 * filtering on availability (feature-registry S2 chain) + permissions:
 * it renders command rows, it never owns the command execution.
 *
 * The `CommandPalette` surface component (Radix Dialog headless,
 * skinnable) lives in components/ui/command.tsx; this module is the
 * registry -> command list adapter (presentation layer, 02 S4).
 */
import type { FeatureRegistry, AgentCapability } from '@aurora/domain';

export interface PaletteCommand {
  /** the capability / use-case id (the single source of truth, S4). */
  id: string;
  /** display label (FR). */
  label: string;
  /** command group (feature module). */
  group: string;
  /** optional key hint (Kbd, desktop / hardware keyboard). */
  shortcut?: string;
  /** high-risk capabilities surface a confirmation step (kernel S12). */
  requiresConfirmation: boolean;
}

export interface CommandCatalogSource {
  /** available agent capabilities (gated on features + permissions). */
  capabilities: readonly AgentCapability[];
  /** registry to check feature availability (S2 chain). */
  registry: FeatureRegistry;
  /** optional user id (per-user gating). */
  userId?: string;
  /** optional display labels / shortcuts per capability id. */
  labels?: Record<string, { label?: string; shortcut?: string }>;
}

/**
 * Build the command list FROM the capability registry (S4): filter on
 * availability (every `requiresFeatures` must be enabled + visible for
 * the user) and permissions (capability present in the catalog).
 * Disabled features disappear from the palette — never just greyed
 * out (feature-registry S6 "command palette" effect).
 */
export function buildCommandCatalog({
  capabilities,
  registry,
  userId,
  labels,
}: CommandCatalogSource): PaletteCommand[] {
  const rows: PaletteCommand[] = [];
  for (const cap of capabilities) {
    // Availability: all required features must be enabled AND visible
    // (feature-registry S2 chain, S6 deactivation effect on the palette).
    if (cap.requiresFeatures?.some((f) => !registry.visible(f, userId))) continue;
    const label = labels?.[cap.id]?.label ?? cap.title;
    rows.push({
      id: cap.id,
      label,
      group: cap.tool ?? cap.id,
      shortcut: labels?.[cap.id]?.shortcut,
      requiresConfirmation: cap.risk === 'high',
    });
  }
  // Stable order: group first, then label (deterministic UI, no flicker).
  rows.sort((a, b) => (a.group === b.group ? a.label.localeCompare(b.label) : a.group.localeCompare(b.group)));
  return rows;
}

/**
 * Filter the catalog for the palette's search input (display filter
 * ONLY — execution still goes through the use-case layer, S4 "zero
 * duplicated business logic"). Case- and accent-insensitive substring
 * over label + id (FR locale: normalise NFD, strip combining marks).
 */
function fold(s: string): string {
  return s
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase();
}

export function filterCommands(commands: readonly PaletteCommand[], query: string): PaletteCommand[] {
  const q = fold(query.trim());
  if (!q) return [...commands];
  return commands.filter((c) => fold(c.label).includes(q) || fold(c.id).includes(q));
}
