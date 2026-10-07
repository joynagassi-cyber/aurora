-- 0023 — canvas.locked (wave 3, G10 open item)
-- Addsitive column on canvas_sessions (0022) : verrou volontaire
-- (par l'humain dans /canvas OU par l'agent via canvas_lock).
-- AD-7 : le kernel ne fait qu'EMIT la commande canvas.lock ; la mutation
-- de cette colonne est appliquée par le module Canvas (fn-canvas), qui
-- est le single-writer AD-7 de canvas_*.
--
-- Semantics :
--   locked = true   → canvas_write devient read-only pour ce canvas
--                     (la commande est acceptée mais le module la
--                     rejette avec 'canvas/locked' tant que
--                     canvas_lock(locked=false) n'a pas été émise)
--   locked = false  → édition libre (état par défaut)
--
-- Le module Canvas n'implémente PAS de RLS sur cette colonne : le
-- flag est borne par user_id comme le reste de la table (0022) et
-- n'ouvre aucune surface de lecture supplémentaire.

ALTER TABLE canvas_sessions
  ADD COLUMN IF NOT EXISTS locked BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN canvas_sessions.locked IS
  'Volitional lock by the user or the agent (wave 3 G10). AD-7: canvas_lock EMITs the command; the canvas module applies the mutation.';
