/**
 * @aurora/ui — AgentThinkingLoader (docs/ui-libraries.md §9.3).
 *
 * The "agent is thinking" state: an organic fluid ORGANISM (3 layered
 * morphing blobs) that breathes behind a static monochrome butterfly mark
 * (S9: the mark is never redrawing/animated itself — the ORGANISM thinks,
 * the brand stays calm). Not the three-dot pattern.
 *
 * Contracts (05 §2.6 + ui-libraries §9.3 + S5 mobile battery):
 *   - GPU ONLY: transform (scale/rotate) + opacity — no `layout`, no filters.
 *   - Color = `--aurora-accent-*` CSS vars → follows the active expressive
 *     theme / preset (Nocturne/High Contrast = desaturated via token).
 *   - `prefers-reduced-motion` ON = fully STATIC (no keyframe loop).
 *   - States: `thinking` (loop) · `idle` (static) · `exiting` (collapse +
 *     fade 150–250 ms when the response starts streaming).
 *
 * The butterfly mark is a PROP (`butterfly`), NOT embedded: the app passes
 * the stripped monochrome SVG (ui-libraries §9.2 build artifact), keeping
 * @aurora/ui asset-free (AD-1) and S9-compliant (no asset duplication).
 */
import * as React from "react";
import { motion } from "motion/react";
import { cn } from "src/lib/utils";
import { useReducedMotion } from "src/theme/provider";

export interface AgentThinkingLoaderProps {
  /** lifecycle state (ui-libraries §9.3). @default "thinking" */
  state?: "thinking" | "idle" | "exiting";
  /** optional monochrome butterfly mark, rendered statically at center. */
  butterfly?: React.ReactNode;
  /** the live label rendered under the organism. @default "Agent réfléchit…" */
  label?: string;
  /** organism size in px (05 §3.4 / §9.3: 64–96 in chat). @default 88 */
  size?: number;
  className?: string;
}

/** Three organic blob silhouettes (viewBox 0 0 200 200). Layered = fluid. */
const BLOB_BACKEND =
  "M100,18 C142,14 178,44 184,86 C190,128 162,168 122,180 C82,192 40,176 26,138 C12,100 34,56 70,34 C78,29 88,20 100,18 Z";
const BLOB_MIDDLE =
  "M60,40 C96,18 150,30 166,72 C182,114 156,160 116,170 C76,180 34,158 30,116 C26,74 32,54 60,40 Z";
const BLOB_FRONT =
  "M78,74 C102,58 140,66 148,96 C156,126 132,152 104,150 C88,149 74,140 66,124 C58,108 58,88 78,74 Z";

/** A single morphing blob: static organic path, GPU scale/rotate/opacity. */
function Blob({
  d,
  fill,
  scale,
  rotate,
  opacity,
  duration,
  loop,
}: {
  d: string;
  fill: string;
  scale: number;
  rotate: number;
  opacity: number;
  duration: number;
  loop: boolean;
}) {
  const animate = loop
    ? {
        scale: [scale, scale * 1.08, scale * 0.94, scale],
        rotate: [rotate, rotate + 120, rotate + 240, rotate + 360],
        opacity: [opacity, opacity * 1.25, opacity * 0.8, opacity],
      }
    : { scale, rotate, opacity };
  return (
    <motion.svg
      viewBox="0 0 200 200"
      aria-hidden
      className="absolute inset-0 h-full w-full"
      initial={false}
      animate={animate}
      transition={
        loop
          ? { duration, ease: "easeInOut", repeat: Infinity }
          : { duration: 0.2, ease: "easeOut" }
      }
      style={{ transformOrigin: "50% 50%" }}
    >
      <path d={d} fill={fill} />
    </motion.svg>
  );
}

export function AgentThinkingLoader({
  state = "thinking",
  butterfly,
  label = "Agent réfléchit…",
  size = 88,
  className,
}: AgentThinkingLoaderProps) {
  const reduced = useReducedMotion();
  // Loop only when: NOT reduced-motion, and state === "thinking".
  // idle/exiting/reduced = static (05 §2.6 rule 2: reduced = static).
  const loop = !reduced && state === "thinking";
  const exiting = state === "exiting";
  // Accent tokens → theme-aware (ui-libraries §9.3).
  const back = "hsl(var(--aurora-accent-primary-h) / 0.28)";
  const middle = "hsl(var(--aurora-accent-secondary-h) / 0.45)";
  const front = "hsl(var(--aurora-accent-primary-h) / 0.6)";

  return (
    <div
      data-agent-thinking
      data-thinking-state={state}
      data-reduced-motion={reduced ? "true" : "false"}
      role="status"
      aria-live={label ? "polite" : undefined}
      className={cn("flex flex-col items-center gap-3", className)}
    >
      <motion.div
        className="relative"
        style={{ width: size, height: size }}
        initial={false}
        animate={
          exiting
            ? { opacity: 0, scale: 0.9 }
            : { opacity: 1, scale: 1 }
        }
        transition={{ duration: 0.2, ease: "easeOut" }}
      >
        <Blob d={BLOB_BACKEND} fill={back} scale={1} rotate={0} opacity={0.5} duration={4.2} loop={loop} />
        <Blob d={BLOB_MIDDLE} fill={middle} scale={0.82} rotate={-30} opacity={0.6} duration={3.4} loop={loop} />
        <Blob d={BLOB_FRONT} fill={front} scale={0.6} rotate={60} opacity={0.7} duration={2.6} loop={loop} />
        {butterfly && (
          <div className="absolute inset-0 grid place-items-center">
            <div
              data-thinking-butterfly
              style={{ width: Math.round(size * 0.55), height: Math.round(size * 0.55) }}
            >
              {butterfly}
            </div>
          </div>
        )}
      </motion.div>
      {label && (
        <p
          data-thinking-label
          className="text-[13px] font-medium text-muted-foreground"
        >
          {label}
        </p>
      )}
    </div>
  );
}
