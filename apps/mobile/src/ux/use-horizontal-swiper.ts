/**
 * useHorizontalSwiper (C5.3 2026-10-08) — le glissement horizontal
 * partagé des surfaces multi-vues (le plan C5, « pattern global
 * glissement horizontal des surfaces »). Pointer-based, GPU-only
 * (`transform: translateX`, jamais de layout animation mobile, règle 1
 * 05 §2.6 : la donnée ne s'anime jamais — ici seul le conteneur se
 * déplace), `prefers-reduced-motion` = désactivé (le basculement reste
 * au tap, l'animation est statique).
 *
 * Threshold : 48px (le geste qui révéle / qui referme, au-delà duquel
 * le panneau reste ouvert / fermé). Snap retour 200ms ease-out (le
 * retour au repos, jamais une animation de trace — la donnée ne
 * s'anime pas, le conteneur seulement).
 *
 * Pas de lib (le pattern est identique à celui du `agent/index.tsx` :
 * `swipeOffset`/`swipeActive`/`swipeStart`, dead zone 10px) — le
 * pointeur natif + le `transform` inline suffisent, jamais une lib.
 */
import { useCallback, useRef, useState } from 'react';
import { useReducedMotion } from 'motion/react';

export interface HorizontalSwiperHandlers {
  onPointerDown: (e: React.PointerEvent<HTMLDivElement>) => void;
  onPointerMove: (e: React.PointerEvent<HTMLDivElement>) => void;
  onPointerUp: () => void;
}

/**
 * The hidden side panel (C5) — the glide reveals / hides it. The panel
 * is a sibling of the surface (never an overlay that masks — the
 * panel COEXISTE with the active view, 05 §3.6.15 l.1409-1411 : « le
 * panneau latéral se glisse »). The caller owns the open state + the
 * render (the hook only drives the gesture).
 */
export function useHorizontalSwiper(
  onOpenChange: (open: boolean) => void,
  threshold = 48,
): {
  glideX: number;
  isGliding: boolean;
  handlers: HorizontalSwiperHandlers;
  surfaceStyle?: React.CSSProperties;
} {
  const reduced = useReducedMotion();
  const [glideX, setGlideX] = useState(0);
  const [isGliding, setIsGliding] = useState(false);
  const glideStartX = useRef(0);

  const onPointerDown = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (reduced) return;
      glideStartX.current = e.clientX;
      setIsGliding(true);
      setGlideX(0);
    },
    [reduced],
  );

  const onPointerMove = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (reduced || !isGliding) return;
      const dx = e.clientX - glideStartX.current;
      // Un glissement à gauche révéle le panneau (dx < 0) ; un
      // glissement à droite le referme (dx > 0) — le panneau EST le
      // glissement, pas une 2ᵉ surface qui apparaît.
      if (dx < 0) setGlideX(dx);
    },
    [reduced, isGliding],
  );

  const onPointerUp = useCallback(() => {
    if (reduced) {
      setGlideX(0);
      setIsGliding(false);
      return;
    }
    if (glideX < -threshold) onOpenChange(true); // révéler
    if (glideX > threshold) onOpenChange(false); // refermer
    setGlideX(0);
    setIsGliding(false);
  }, [reduced, glideX, onOpenChange, threshold]);

  /** Le `transform` n'existe QUE pendant le geste (`isGliding`) : la
      donnée ne s'anime jamais (règle 1, 05 §2.6 l.323-330) — seul le
      conteneur glisse. La `translateX` est bornée à -240px (le
      panneau latéral 300px, 05 §3.6.15 l.1402, la surface ne déborde
      jamais de l'écran). */
  const surfaceStyle: React.CSSProperties | undefined = reduced
    ? undefined
    : { transform: `translateX(${Math.max(glideX, -240)}px)` };

  return {
    glideX,
    isGliding,
    handlers: { onPointerDown, onPointerMove, onPointerUp },
    surfaceStyle,
  };
}
