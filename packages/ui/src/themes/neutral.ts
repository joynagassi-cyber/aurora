/**
 * @aurora/ui — Neutral style catalog (05 §5.2 level 1, G-H2 resolved).
 *
 * Light canvas = #FFFFFF (plain white, G-H2 re-2026-10).
 * Dark canvas = #121212 (true dark, G-H2 re-2026-10).
 *
 * These are the FROZEN semantic tokens of 05 §2.1.2/§2.1.3 — normative
 * for wave 1. A theme NEVER redefines success/warning/danger/info
 * (blocking rule 05 §5.1): these values come from here, not from
 * packages/ui/src/themes/*.json.
 *
 * 2026-10 (G-H2 re-2026-10): canvas values re-anchored to plain white
 * (#FFFFFF) light / #121212 dark — the blue-tinted near-black
 * (#0A0E1A) and slate.50 (#F8FAFC) canvases are deprecated. No tinted
 * or gradient canvas: the two neutral styles define the only two
 * canvas values. Theme expressive colors overlay accents only, they
 * never tint the canvas itself.
 */

import type { NeutralStyleCatalog } from "./types";

export const NEUTRAL_STYLES: NeutralStyleCatalog = {
  light: {
    "bg": "#FFFFFF",
    "bg-subtle": "#F1F5F9",
    "surface": "#FFFFFF",
    "surface-alt": "#F8FAFC",
    "surface-overlay": "rgba(255,255,255,0.85)",
    "text-primary": "#0F172A",
    "text-secondary": "#334155",
    "text-muted": "#64748B",
    "text-disabled": "#CBD5E1",
    "border": "#E2E8F0",
    "border-strong": "#94A3B8",
    "success": "#10B981",
    "success-surface": "#E8FAF0",
    "warning": "#F59E0B",
    "warning-surface": "#FFF4E0",
    "danger": "#EF4444",
    "danger-surface": "#FEECEC",
    "info": "#0EA5E9",
    "node-mastered": "#10B981",
    "node-fragile": "#F59E0B",
    "node-forgotten": "#EF4444",
    "habit-weak": "#E2E8F0",
    "habit-med": "#9AA4F4",
    "habit-strong": "#4F5AE8",
    "skeleton": "#E2E8F0",
  },
  dark: {
    "bg": "#121212",
    "bg-subtle": "#1E1E1E",
    "surface": "#1E2026",
    "surface-alt": "#25282F",
    "surface-overlay": "rgba(24,24,24,0.88)",
    "text-primary": "#F1F5F9",
    "text-secondary": "#94A3B8",
    "text-muted": "#64748B",
    "text-disabled": "#475569",
    "border": "#334155",
    "border-strong": "#64748B",
    "success": "#34D399",
    "success-surface": "#064E3B",
    "warning": "#FBBF24",
    "warning-surface": "#7C3A08",
    "danger": "#F87171",
    "danger-surface": "#7F1D1D",
    "info": "#38BDF8",
    "node-mastered": "#34D399",
    "node-fragile": "#FBBF24",
    "node-forgotten": "#F87171",
    "habit-weak": "#25282F",
    "habit-med": "#818CF8",
    "habit-strong": "#9AA4F4",
    "skeleton": "#25282F",
  },
};
