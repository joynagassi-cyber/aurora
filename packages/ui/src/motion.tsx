/**
 * @aurora/ui — motion SSoT (docs/ui-libraries.md §1 "Animations", 05 §2.6).
 *
 * The three screen-level primitives + the skeleton spec, all GPU-only
 * (transform + opacity), smooth, 150-250ms windows, `prefers-reduced-motion`
 * aware (05 §2.6 rule 2 = MANDATORY: when ON everything is static):
 *
 *   - PAGE_TRANSITION  route transition, 200ms ease-out
 *   - REVEAL_TRANSITION  reveal-on-scroll, 250ms ease-out
 *   - NODE_PULSE     the ONLY animated emphasis (active-node breath, 1.5s)
 *   - SKELETON_PULSE skeleton load-pulse (opacity 0.6→1, 1.2s — 05 §3.3)
 *
 * Values here are the SSoT cited by the design docs (docs/design-system/…)
 * where older references pointed at the app-level polish layer
 * (apps/mobile/src/ux/polish.tsx, removed — the primitives it defined live
 * here, in packages/ui, AD-10).
 *
 * Framer Motion (motion) is vendored in the app; the spec objects below are
 * framework-agnostic data so CSS-only surfaces (tokens.css, 05 §3.3) can
 * mirror the same numbers.
 */

import { motion, useReducedMotion, useInView } from 'motion/react';
import { useRef } from 'react';
import type { ReactNode } from 'react';

/** Page-transition spec (smooth, 200ms ease-out — emotion-design §3). */
export const PAGE_TRANSITION = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -4 },
  transition: { duration: 0.2, ease: 'easeOut' as const },
} as const;

/** Reveal-on-scroll spec (staggered within the 150-250ms window). */
export const REVEAL_TRANSITION = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.25, ease: 'easeOut' as const },
} as const;

/**
 * Active-node emphasis — the ONLY allowed animated emphasis
 * (emotion-design §3: NodePulse, 1.5s breath, scale 1→1.04→1).
 * Secondary nodes stay static; reduced-motion = static highlight.
 */
export const NODE_PULSE = {
  animate: { scale: [1, 1.04, 1] },
  transition: { duration: 1.5, ease: 'easeInOut' as const },
} as const;

/**
 * Skeleton load-pulse (05 §3.3: opacity 0.6→1 over 1.2s, easeInOut —
 * « le Skeleton pulse doucement, pas un shimmer agressif »).
 * CSS mirror: `--aurora-skeleton` token in apps/mobile/src/styles/tokens.css.
 */
export const SKELETON_PULSE = {
  keyframes: '0%, 100% { opacity: 0.6; } 50% { opacity: 1; }',
  duration: '1.2s',
  timing: 'ease-in-out',
} as const;

/**
 * <PageTransition> — wraps a page surface. GPU only (opacity + transform),
 * 200ms ease-out. reduced-motion ON = no animation (static, instant).
 */
export function PageTransition({ children }: { children: ReactNode }) {
  const reduced = useReducedMotion();
  if (reduced) return <div data-ux="page-transition-static">{children}</div>;
  return (
    <motion.div
      data-ux="page-transition"
      initial={PAGE_TRANSITION.initial}
      animate={PAGE_TRANSITION.animate}
      exit={PAGE_TRANSITION.exit}
      transition={PAGE_TRANSITION.transition}
    >
      {children}
    </motion.div>
  );
}

/**
 * <NodePulse> — the active-node emphasis (ui-libraries S2: "Focus mode
 * → attenuated secondary nodes, pulse on active"). A soft scale pulse
 * (transform only = GPU), continuous 1.5s breath while `active`;
 * reduced-motion ON = a static highlight (no pulse).
 */
export function NodePulse({
  active,
  children,
}: {
  active: boolean;
  children: ReactNode;
}) {
  const reduced = useReducedMotion();
  if (reduced || !active) {
    return (
      <div data-ux="node-pulse-static" data-active={active ? 'true' : 'false'}>
        {children}
      </div>
    );
  }
  return (
    <motion.div
      data-ux="node-pulse"
      animate={NODE_PULSE.animate}
      transition={{ ...NODE_PULSE.transition, repeat: Infinity }}
      style={{ willChange: 'transform' }}
    >
      {children}
    </motion.div>
  );
}

/**
 * <Reveal> — reveal-on-scroll: the child enters once it is in view
 * (IntersectionObserver via useInView, ref as first arg — motion v13
 * API). GPU-only entry; reduced-motion ON = fully static
 * (05 §2.6 rule 2).
 */
export function Reveal({
  children,
  delay = 0,
}: {
  children: ReactNode;
  /** stagger offset (s), kept small to stay in the 150-250ms window */
  delay?: number;
}) {
  const reduced = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: '-10% 0px -10% 0px' });
  if (reduced) {
    return (
      <div ref={ref} data-ux="reveal-static">
        {children}
      </div>
    );
  }
  return (
    <motion.div
      ref={ref}
      data-ux="reveal"
      initial={REVEAL_TRANSITION.initial}
      animate={inView ? REVEAL_TRANSITION.animate : REVEAL_TRANSITION.initial}
      transition={{ ...REVEAL_TRANSITION.transition, delay: Math.min(delay, 0.4) }}
    >
      {children}
    </motion.div>
  );
}
