/**
 * @aurora/ui — AgentThinkingLoader (docs/ui-libraries.md §9.3).
 *
 * The "agent is thinking" state: an organic fluid ORGANISM (3 layered
 * morphing blobs) that breathes behind a static monochrome butterfly mark
 * (S9: the mark is never redrawing/animated itself — the ORGANISM thinks,
 * the brand stays calm). Not the three-dot pattern.
 *
 * + THINKING-WORDS layer (pattern researched 2026-09-27: Claude Code pairs
 * its pulsing star with a rotating list of 184 thinking verbs — e.g.
 * "Pondering… / Ruminating… / Combobulating…"; Claude also shows a
 * "Thought for Ns" elapsed chip): a rotating line of thinking verbs
 * (float: exit up −4 px / enter from +4 px, fixed box, aria-hidden) + an
 * optional elapsed-seconds chip. Each word change also makes the ORGANISM
 * "inhale" (scale 1 → 1.04 → 1, 250 ms) so the two motion layers breathe
 * TOGETHER (owner retouche 2026-09-28). The SR text stays STABLE (the
 * rotator is aria-hidden).
 *
 * ALL-THEMES CONTRACT (ui-libraries §9.3, owner decision 2026-09-28):
 *   - The loader must read correctly on ALL 10 expressive themes × {light,
 *     dark} × 3 presets, NO EXCEPTION — blobs = `--aurora-accent-*` only
 *     (theme-aware by construction), butterfly = grayscale monochrome
 *     (works on light & dark), text = neutral tokens. No hue outside a
 *     token (accent-only rule: themes accentuate a WHITE base by default;
 *     DARK is only when the user chooses it).
 *
 * Contracts (05 §2.6 + ui-libraries §9.3 + S5 mobile battery):
 *   - GPU ONLY: transform (scale/rotate) + opacity — no `layout`, no filters.
 *   - Color = `--aurora-accent-*` CSS vars → follows the active expressive
 *     theme / preset (Nocturne/High Contrast = desaturated via token).
 *   - `prefers-reduced-motion` ON = fully STATIC (no keyframe loop, no
 *     word rotation).
 *   - States: `thinking` (loop) · `idle` (static) · `exiting` (collapse +
 *     fade 150–250 ms when the response starts streaming).
 *
 * The butterfly mark is a PROP (`butterfly`), NOT embedded: the app passes
 * the stripped monochrome SVG (ui-libraries §9.2 build artifact), keeping
 * @aurora/ui asset-free (AD-1) and S9-compliant (no asset duplication).
 */
import * as React from "react";
import { AnimatePresence, motion, useAnimationControls } from "motion/react";
import { cn } from "src/lib/utils";
import { useReducedMotion } from "src/theme/provider";

/**
 * Default thinking verbs (Aurora mood: serious + one playful, à la Claude's
 * "Pondering / Ruminating / Combobulating" mix — 3rd-person present, FR).
 * Apps can override with their own register (tone of voice).
 */
export const DEFAULT_THINKING_WORDS = [
  "Réfléchit…",
  "Pondère…",
  "Tisse…",
  "Mûrit…",
  "Brasse…",
  "Explore…",
  "Vérifie…",
  "Éclaire…",
  "Distille…",
  "Recompose…",
  "Anticipe…",
  "Ordonne…",
];

export interface AgentThinkingLoaderProps {
  /** lifecycle state (ui-libraries §9.3). @default "thinking" */
  state?: "thinking" | "idle" | "exiting";
  /** optional monochrome butterfly mark, rendered statically at center. */
  butterfly?: React.ReactNode;
  /**
   * The STABLE screen-reader label (the visible rotating words are
   * aria-hidden — no SR spam). @default "L'agent réfléchit…"
   */
  label?: string;
  /**
   * thinking-verbs line that rotates (Claude pattern). Crossfade 200 ms,
   * fixed-height box (no reflow). Empty array = static `label` fallback.
   * @default DEFAULT_THINKING_WORDS
   */
  words?: string[];
  /** rotation period in ms. @default 2400 */
  wordIntervalMs?: number;
  /**
   * optional elapsed-seconds chip ("Réflexion · Ns" — Claude's "Thought
   * for Ns" pattern; the APP owns the clock, the component only renders).
   */
  elapsedSeconds?: number;
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
  label = "L'agent réfléchit…",
  words = DEFAULT_THINKING_WORDS,
  wordIntervalMs = 2400,
  elapsedSeconds,
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

  // ---- thinking-words rotation (Claude pattern; stable SR text) ----------
  // `words` via ref: the interval must survive re-renders (callers may
  // pass fresh array literals); only length/loop/interval gate the loop.
  const wordsRef = React.useRef(words);
  wordsRef.current = words;
  const [wordIdx, setWordIdx] = React.useState(0);
  React.useEffect(() => {
    setWordIdx(0);
  }, [words.length]);
  React.useEffect(() => {
    if (!loop || words.length < 2) return;
    const t = window.setInterval(
      () => setWordIdx((i) => (i + 1) % wordsRef.current.length),
      wordIntervalMs,
    );
    return () => window.clearInterval(t);
  }, [loop, words.length, wordIntervalMs]);

  // ---- organism "inhale" pulse, SYNCED to every word change --------------
  // One-shot scale [1 → 1.04 → 1] (250 ms, GPU): the organism reacts to
  // each new thought word. Reduced-motion / idle / exiting = no pulse.
  const organismCtl = useAnimationControls();
  React.useEffect(() => {
    if (reduced) return;
    organismCtl.start(
      exiting
        ? { opacity: 0, scale: 0.9, transition: { duration: 0.2, ease: "easeOut" } }
        : { opacity: 1, scale: 1, transition: { duration: 0.2, ease: "easeOut" } },
    );
  }, [exiting, reduced]);
  React.useEffect(() => {
    if (!loop || wordIdx === 0) return;
    organismCtl.start({
      scale: [1, 1.04, 1],
      transition: { duration: 0.25, ease: "easeInOut" },
    });
  }, [wordIdx]);

  return (
    <div
      data-agent-thinking
      data-thinking-state={state}
      data-reduced-motion={reduced ? "true" : "false"}
      data-inhale={loop && wordIdx > 0 ? "true" : "false"}
      role="status"
      aria-live="polite"
      className={cn("flex flex-col items-center gap-3", className)}
    >
      <motion.div
        className="relative"
        style={{
          width: size,
          height: size,
          // reduced-motion = STATIC per-frame values (no control animation)
          ...(reduced
            ? { opacity: exiting ? 0 : 1, scale: exiting ? 0.9 : 1 }
            : {}),
        }}
        initial={reduced ? false : { opacity: 1, scale: 1 }}
        animate={reduced ? undefined : organismCtl}
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
      {words.length > 0 ? (
        // Rotating thinking-verbs: fixed h-5 box (no reflow), FLOAT
        // (exit up −4 px / enter from +4 px, GPU), aria-hidden (SR reads
        // the stable `label` below). Reduced-motion = first word, static.
        // AnimatePresence (default sync mode): the outgoing word exits
        // (up) while the incoming word enters (from below) — no dead
        // time, both absolute in the fixed h-5 box.
        <div
          data-thinking-words
          className="relative h-5 text-[13px] font-medium text-muted-foreground"
        >
          <span className="absolute inset-0">
            <AnimatePresence initial={false}>
              {/* each word = its own absolute layer (no reflow, they
                  overlap during the 200 ms cross-float) */}
              <motion.span
                key={wordIdx}
                aria-hidden
                className="absolute inset-0 grid place-items-center"
                initial={reduced ? false : { opacity: 0, y: 4 }}
                animate={{ opacity: 1, y: 0 }}
                exit={reduced ? undefined : { opacity: 0, y: -4 }}
                transition={{ duration: 0.2, ease: "easeOut" }}
              >
                {words[wordIdx % words.length]}
              </motion.span>
            </AnimatePresence>
          </span>
          <span className="sr-only">{label}</span>
        </div>
      ) : (
        label && (
          <p
            data-thinking-label
            className="text-[13px] font-medium text-muted-foreground"
          >
            {label}
          </p>
        )
      )}
      {elapsedSeconds !== undefined && (
        // "Thought for Ns" pattern: the APP owns the clock, we only
        // render — mono + tabular-nums = no jitter when N increments.
        <p
          data-thinking-elapsed
          className="font-mono text-xs tabular-nums text-muted-foreground/70"
        >
          Réflexion · {elapsedSeconds} s
        </p>
      )}
    </div>
  );
}
