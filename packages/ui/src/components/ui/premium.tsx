/**
 * @aurora/ui — Premium effects (docs/ui-libraries.md §2 step 3).
 *
 * Aceternity (wobble-card) + Magic UI (marquee) — fetched from the public
 * registries; interactive-card, beam, number-tick, shine-effect,
 * blurred-spotlight are NOT public at registry fetch time (403/404) —
 * implemented here per the library's documented contract.
 */
import * as React from "react";
import { motion } from "motion/react";
import { cn } from "src/lib/utils";

// =============================================================================
// @aceternity/wobble-card — GoalProject interactive cards (docs/ui-libraries.md
// "Wobble for interactive cards, standard for data cards").
// GPU only (transform/rotateX/rotateY), 05 §2.6 rule: smooth, no bounce.
// =============================================================================

export const WobbleCard = ({
  children,
  containerClassName,
  className,
}: {
  children: React.ReactNode;
  containerClassName?: string;
  className?: string;
}) => {
  const [mousePosition, setMousePosition] = React.useState({ x: 0, y: 0 });
  const [isHovering, setIsHovering] = React.useState(false);

  const containerRef = React.useRef<HTMLDivElement>(null);

  const handleMouseMove = (event: React.MouseEvent<HTMLDivElement>) => {
    if (!containerRef.current) return;
    const { width, height } = containerRef.current.getBoundingClientRect();
    const { left, top } = containerRef.current.getBoundingClientRect();
    const x = (event.clientX - (left + width / 2)) / (width / 2);
    const y = (event.clientY - (top + height / 2)) / (height / 2);
    setMousePosition({ x, y });
  };

  return (
    <div
      ref={containerRef}
      className={cn("relative p-2", containerClassName)}
      onMouseEnter={() => setIsHovering(true)}
      onMouseLeave={() => {
        setIsHovering(false);
        setMousePosition({ x: 0, y: 0 });
      }}
      onMouseMove={handleMouseMove}
    >
      <motion.div
        className="h-full w-full p-4 md:p-6 transition-shadow duration-500 [transform-style:preserve-3d]"
        style={{
          rotateX: isHovering ? mousePosition.x * 5 : 0,
          rotateY: isHovering ? -mousePosition.y * 5 : 0,
          scale: isHovering ? 1.05 : 1,
        }}
      >
        <motion.div
          className="absolute inset-0 h-w-full w-full rounded-2xl"
          style={{
            background:
              "radial-gradient(600px circle at calc(50% + " +
              mousePosition.x * 20 +
              "px) calc(50% + " +
              mousePosition.y * 20 +
              "px), hsl(var(--aurora-accent-primary-h) / 0.2), #0000)",
          }}
        />
        <div className={cn("relative z-10", className)}>{children}</div>
      </motion.div>
    </div>
  );
};

// =============================================================================
// @aceternity/interactive-card — Feature cards (docs/ui-libraries.md §1).
// Tilt + light-trail interaction, GPU transforms only.
// =============================================================================

export const InteractiveCard = ({
  children,
  containerClassName,
  className,
}: {
  children: React.ReactNode;
  containerClassName?: string;
  className?: string;
}) => {
  const [position, setPosition] = React.useState({ x: 0, y: 0 });
  const [isHovering, setIsHovering] = React.useState(false);
  const ref = React.useRef<HTMLDivElement>(null);

  const handleMouseMove = (event: React.MouseEvent<HTMLDivElement>) => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    setPosition({ x: event.clientX - left, y: event.clientY - top });
  };

  return (
    <div
      ref={ref}
      className={cn(
        "relative overflow-hidden rounded-xl border border-border bg-card p-6 shadow-sm transition-shadow hover:shadow-lg",
        containerClassName,
      )}
      onMouseEnter={() => setIsHovering(true)}
      onMouseLeave={() => {
        setIsHovering(false);
        setPosition({ x: 0, y: 0 });
      }}
      onMouseMove={handleMouseMove}
    >
      {isHovering && (
        <motion.div
          className="pointer-events-none absolute -inset-1 rounded-2xl opacity-70"
          style={{
            background: `radial-gradient(200px circle at ${position.x}px ${position.y}px, hsl(var(--aurora-accent-secondary-h) / 0.25), transparent 70%)`,
          }}
        />
      )}
      <div className={cn("relative z-10", className)}>{children}</div>
    </div>
  );
};

// =============================================================================
// @aceternity/beam — Focus mode visual (docs/ui-libraries.md §1: "Beam /
// Spotlight … Focus mode visual"). A vertical light beam, GPU opacity/
// transform only.
// =============================================================================

export const Beam = ({
  className,
  children,
}: {
  className?: string;
  children?: React.ReactNode;
}) => {
  return (
    <div className={cn("relative flex flex-col items-center", className)}>
      <motion.div
        className="absolute inset-x-0 top-0 h-full w-full"
        style={{
          background:
            "linear-gradient(180deg, hsl(var(--aurora-accent-primary-h) / 0.4) 0%, hsl(var(--aurora-accent-secondary-h) / 0.15) 50%, transparent 100%)",
        }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.4, ease: "easeOut" }}
      />
      <div className="relative z-10 py-2">{children}</div>
    </div>
  );
};

// =============================================================================
// @magicui/marquee — Notifications ticker (docs/ui-libraries.md §1 "Marquee /
// Ticker (notifications)").
// =============================================================================

export const Marquee = ({
  className,
  reverse = false,
  pauseOnHover = false,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement> & {
  reverse?: boolean;
  pauseOnHover?: boolean;
  children: React.ReactNode;
}) => {
  return (
    <div
      className={cn(
        "group flex overflow-hidden [--duration:40s] [--gap:1rem] data-[paused=true]:[animation-play-state:paused]",
        className,
      )}
      {...props}
    >
      <div
        style={{
          animationDuration: "var(--duration)",
          animationDirection: reverse ? "reverse" : "normal",
        }}
        className={cn(
          "flex w-max min-w-full shrink-0 flex-[0_1] animate-marquee justify-stretch gap-[var(--gap)] group-hover:[--duration:700ms]",
          pauseOnHover && "group-hover:[animation-play-state:paused]",
        )}
      >
        {children}
      </div>
      <div
        aria-hidden
        style={{
          animationDuration: "var(--duration)",
          animationDirection: reverse ? "reverse" : "normal",
        }}
        className={cn(
          "flex w-max min-w-full shrink-0 flex-[0_1] animate-marquee justify-stretch gap-[var(--gap)] group-hover:[--duration:700ms]",
          pauseOnHover && "group-hover:[animation-play-state:paused]",
        )}
      >
        {children}
      </div>
    </div>
  );
};

// =============================================================================
// @magicui/number-tick — Progress numbers (docs/ui-libraries.md §1 "Number
// Tick / Counter … Progress numbers").
// =============================================================================

export const NumberTick = ({
  value = 0,
  className,
}: {
  value: number;
  className?: string;
}) => {
  const [display, setDisplay] = React.useState(0);

  React.useEffect(() => {
    const start = performance.now();
    const duration = 600;
    let raf: number;
    const tick = (now: number) => {
      const p = Math.min(1, (now - start) / duration);
      const eased = 1 - Math.pow(1 - p, 3);
      setDisplay(value * eased);
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [value]);

  return (
    <span className={cn("font-mono tabular-nums", className)}>
      {Number.isInteger(display) ? display : display.toFixed(1)}
    </span>
  );
};

// =============================================================================
// @magicui/shine-effect — Premium card highlight (docs/ui-libraries.md §1
// "Glow / Shine effect").
// =============================================================================

export const ShineEffect = ({
  children,
  shineColor = "white",
  className,
}: {
  children: React.ReactNode;
  shineColor?: string;
  className?: string;
}) => {
  const [position, setPosition] = React.useState({ x: 0, y: 0 });
  const [visible, setVisible] = React.useState(false);

  return (
    <div
      className={cn(
        "relative isolate overflow-hidden rounded-xl p-[1px]",
        className,
      )}
      onMouseMove={(e) => {
        const rect = e.currentTarget.getBoundingClientRect();
        setPosition({ x: e.clientX - rect.left, y: e.clientY - rect.top });
        setVisible(true);
      }}
      onMouseLeave={() => setVisible(false)}
    >
      {visible && (
        <div
          aria-hidden
          className="absolute -inset-x-4 -top-4 bottom-1/2 z-10 to-transparent"
          style={{
            background: `radial-gradient(240px ellipse at ${position.x}px ${position.y}px, ${shineColor}80, transparent)`,
          }}
        />
      )}
      <div className="relative z-0">{children}</div>
    </div>
  );
};

// =============================================================================
// @magicui/blurred-spotlight — docs/ui-libraries.md §2 step 3.
// =============================================================================

export const BlurredSpotlight = ({
  className,
}: {
  className?: string;
}) => {
  return (
    <div
      aria-hidden
      className={cn(
        "pointer-events-none absolute inset-0 -z-10 flex items-center justify-center overflow-hidden rounded-md",
        className,
      )}
    >
      <motion.div
        className="h-full w-full bg-white/30"
        initial={{ opacity: 0.5, filter: "blur(0)" }}
        animate={{ opacity: 0.15, filter: "blur(32px)" }}
        transition={{ duration: 1.2, ease: "easeOut" }}
        style={{
          background:
            "radial-gradient(480px circle at center, hsl(var(--aurora-accent-primary-h) / 0.28), transparent 70%)",
        }}
      />
    </div>
  );
};
