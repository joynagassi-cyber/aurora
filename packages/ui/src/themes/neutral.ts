/**
 * @aurora/ui — Neutral style catalog (05 §5.2 level 1, G-H2 resolved).
 *
 * Light canvas = #FFFFFF (plain white, G-H2 re-2026-10).
 * Dark canvas = #000000 (PURE deepest black, owner 10-07 — re-anchors the
 * G-H2 #121212: the user wants no blue/slate cast, the deepest #000000).
 *
 * These are the FROZEN semantic tokens of 05 §2.1.2/§2.1.3 — normative
 * for wave 1. A theme NEVER redefines success/warning/danger/info
 * (blocking rule 05 §5.1): these values come from here, not from
 * packages/ui/src/themes/*.json.
 *
 * 2026-10 (owner 10-07 "dark pur"): the DARK neutral style is now PURE —
 * canvas #000000 + a hue-0 gray ramp (surfaces/borders/text are neutral
 * black-white-gray, no 210-220° blue tint). The old bluish slate values
 * (#121212 canvas, #1E2026/#25282F surfaces) are deprecated. No tinted or
 * gradient canvas: the two neutral styles define the only two canvas
 * values. Theme expressive colors overlay accents only, they never tint
 * the canvas itself.
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
    // DARK PUR (owner 10-07): the deepest black canvas #000000 + a pure
    // neutral gray ramp (hue 0 — NO blue/slate tint, the "coloré" cast the
    // old #121212/#1E2026 values had). Semantic states below stay colored
    // (blocking rule 05 §5.1: a theme never redefines them).
    "bg": "#000000",
    "bg-subtle": "#0A0A0A",
    "surface": "#121212",
    "surface-alt": "#1C1C1C",
    "surface-overlay": "rgba(0,0,0,0.88)",
    "text-primary": "#FFFFFF",
    "text-secondary": "#D6D6D6",
    "text-muted": "#8F8F8F",
    "text-disabled": "#5A5A5A",
    "border": "#262626",
    "border-strong": "#4A4A4A",
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
    "habit-weak": "#1C1C1C",
    "habit-med": "#818CF8",
    "habit-strong": "#9AA4F4",
    "skeleton": "#1C1C1C",
  },
};
