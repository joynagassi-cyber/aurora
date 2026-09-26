/**
 * Framer Motion (motion) polish layer (docs/ui-libraries.md §1 "Animations" +
 * agent-prompts Phase 3 S3).
 *
 * Three primitives, all GPU-only (transform + opacity — ui-libraries S5
 * "Framer Motion battery"), smooth, 150-250ms, `prefers-reduced-motion`
 * aware (05 §2.6 rule 2 = MANDATORY: when ON everything is static):
 *
 *   - <PageTransition>  route transition, 200ms ease-out
 *   - <NodePulse>       active-node pulse (Focus / semantic tree), the ONLY
 *                       animated emphasis — secondary nodes stay static
 *   - <Reveal>          reveal-on-scroll, staggered 150-250ms
 *
 * The DS already owns the motion engine (AD-10, packages/ui
 * AnimationController/AnimationSlot); this layer is the SCREEN-level
 * polish on top, in the app shell (presentation layer, 02 S4).
 */
import { motion, useReducedMotion, useInView } from 'motion/react';
import { useRef } from 'react';
import type { ReactNode } from 'react';

/** Page-transition spring-free spec (smooth, 200ms ease-out — Phase 3 S3). */
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
 * (transform only = GPU), 2 cycles of a 1.5s breath while `active`;
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
      animate={{ scale: [1, 1.04, 1] }}
      transition={{ duration: 1.5, repeat: active ? Infinity : 0, ease: 'easeInOut' }}
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
