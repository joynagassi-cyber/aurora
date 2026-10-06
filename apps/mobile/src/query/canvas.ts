// canvas.ts — canvas device hooks (0022, AD-3/AD-7).
//
// `useCanvasSession(id)` : charge la session (canvas_sessions) + ses
// commentaires (canvas_comments) d'un coup — les deux passages RLS
// sont bornés par auth.uid(), jamais de fausse data (AD-7).
//
// `useCanvasSave` : upsert debounce 1 s des blocs — le bloc jsonb est
// le SSoT contenu ; l'invalidation React Query suit le save pour garder
// la surface cohérente (le save n'est pas un mutation optimiste, il
// attend la confirmation serveur).

import { useQuery, useQueryClient } from '@tanstack/react-query';
import type { CanvasBlock, CanvasComment, CanvasSession } from '@aurora/domain';
import { qk } from './query-client';
import { useMobileData } from './context';

export function useCanvasSession(id: string | undefined) {
  const { canvas } = useMobileData();
  return useQuery<{ session: CanvasSession | null; comments: CanvasComment[] }>({
    queryKey: qk.canvas.session(id ?? ''),
    queryFn: async () => {
      if (!canvas || !id) return { session: null, comments: [] };
      const [session, comments] = await Promise.all([
        canvas.get(id),
        canvas.listComments(id),
      ]);
      return { session, comments };
    },
    enabled: Boolean(canvas && id),
    retry: false,
  });
}

/**
 * Sauvegarde debounce 1 s des blocs (l'upsert porte la charge réseau).
 * Le timer vit dans un ref per-session pour qu'un montage/démontage
 * de la page ne perde pas le dernier save en attente.
 */
export function useCanvasSave() {
  const { canvas } = useMobileData();
  const qc = useQueryClient();
  const timers = new Map<string, ReturnType<typeof setTimeout>>();

  const saveNow = async (id: string, blocks: CanvasBlock[]) => {
    if (!canvas) return;
    await canvas.save(id, blocks);
    qc.invalidateQueries({ queryKey: qk.canvas.session(id) });
  };

  const saveDebounced = (id: string, blocks: CanvasBlock[]) => {
    const pending = timers.get(id);
    if (pending) clearTimeout(pending);
    timers.set(
      id,
      setTimeout(() => {
        void saveNow(id, blocks);
      }, 1000),
    );
  };

  // Unmount safety : flush le save en attente au démontage.
  return saveDebounced;
}
