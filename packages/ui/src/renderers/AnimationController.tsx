/**
 * AnimationController + AnimationSlot — AD-10 engine (motion) behind the
 * 02 §5.5 contract (G-M1 verdict: one controller, the DS provides the
 * instance).
 *
 * Progressive reveal (doc §25.8): formula → arrow → step → result →
 * branch. 05 §2.6 rule 2: `prefers-reduced-motion` = MANDATORY — when
 * ON, every reveal is instant (no trace, 05 §2.6 rule 2).
 * 05 §2.6 rule 1: SCIENTIFIC DATA NEVER animates — only the reveal
 * sequence of the explanation (the data itself is static).
 */
import * as React from "react";
import { useCallback, useRef, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { cn } from "src/lib/utils";
import type { AnimationController, RevealKey } from "./contracts";
import { useReducedMotion } from "src/theme/provider";

const REVEAL_ORDER: RevealKey[] = ["formula", "arrow", "step", "result", "branch"];

/** Staggered durations (05 §2.6: 150/250/400ms — slowest = branch). */
const REVEAL_DURATION: Record<RevealKey, number> = {
  formula: 0.4,
  arrow: 0.25,
  step: 0.25,
  result: 0.25,
  branch: 0.4,
};

export function createAnimationController(): AnimationController {
  let reduced =
    typeof window !== "undefined" &&
    window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

  const targets = new Map<string, HTMLElement | SVGElement>();

  const reveal = (
    nodeRef: { current: HTMLElement | SVGElement | null },
    key: RevealKey,
  ): void => {
    const el = nodeRef.current;
    if (!el) return;
    targets.set(String(key), el);
    // The reveal is orchestrated by the owning AnimationSlot (which
    // wraps the child subtree in <motion>); this controller records
    // the intent + order. With reduced-motion ON: instant, no trace.
    const idx = REVEAL_ORDER.indexOf(key);
    if (reduced) {
      el.classList.add("aurora-revealed");
      return;
    }
    const delay = idx * 0.05; // gentle stagger within the 150-400ms window
    el.style.animationDelay = `${delay}s`;
    el.classList.add("aurora-revealing");
  };

  const setReducedMotion = (on: boolean): void => {
    reduced = on;
    if (on) {
      for (const el of targets.values()) {
        el.classList.remove("aurora-revealing");
        el.classList.add("aurora-revealed");
        el.style.animationDelay = "";
      }
    }
  };

  const prefersReducedMotion = (): boolean => reduced;

  // Keep in sync with the OS preference (05 §2.6 rule 2 — mandatory).
  if (typeof window !== "undefined" && "matchMedia" in window) {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    reduced = mq.matches;
    mq.addEventListener?.("change", (e) => setReducedMotion(e.matches));
  }

  return { reveal, setReducedMotion, prefersReducedMotion };
}

/**
 * G-M1 — the React wrapper that owns the motion engine for one subtree.
 * Children reveal progressively (formula → arrow → step → result →
 * branch); with reduced-motion ON, everything appears instantly.
 */
export function AnimationSlot({
  children,
  reducedMotion,
  revealKey,
  className,
}: {
  children: React.ReactNode;
  /** Which key this slot reveals (05 §3.6.5). */
  revealKey?: RevealKey;
  /** When reduced-motion is ON (05 §2.6 rule 2): instant, no trace. */
  reducedMotion?: boolean;
  className?: string;
}) {
  const osReduced = useReducedMotion();
  const reduced = reducedMotion ?? osReduced;
  const controllerRef = useRef<AnimationController>(null as never);
  if (!controllerRef.current) {
    controllerRef.current = createAnimationController();
  }
  const slotRef = useRef<HTMLElement | null>(null);
  const controller = controllerRef.current;

  const [revealed, setRevealed] = useState(false);
  const key = revealKey ?? "step";

  const animate = useCallback(() => {
    controller.reveal(slotRef as never, key);
    if (reduced) setRevealed(true);
  }, [controller, key, reduced]);

  React.useEffect(() => {
    animate();
  }, [key]);

  return (
    <motion.div
      ref={(el: HTMLDivElement | null) => {
        slotRef.current = el;
      }}
      initial={reduced ? { opacity: 1 } : { opacity: 0, y: 8 }}
      animate={reduced ? { opacity: 1 } : revealed ? { opacity: 1, y: 0 } : { opacity: 0, y: 8 }}
      transition={{
        duration: REVEAL_DURATION[key],
        ease: "easeOut",
      }}
      data-aurora-slot={key}
      data-reduced-motion={reduced ? "true" : "false"}
      className={cn(className)}
    >
      {revealed || reduced ? <AnimatePresence>{children}</AnimatePresence> : null}
    </motion.div>
  );
}

export type { AnimationController, RevealKey };
