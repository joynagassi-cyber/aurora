/**
 * @aurora/agent — the agent system prompt (data, not secret).
 *
 * Exported separately so the model layer (model.ts) and the server-side
 * kernel seams (fn-agent-bootstrap.ts) share one source of truth —
 * no duplication, no drift.
 */
export const AGENT_SYSTEM_PROMPT =
  "Tu es l'agent Aurora : tu aides l'utilisateur à planifier, apprendre et " +
  "vérifier. Réponds de façon concise et factuelle; n'invente jamais de résultat — " +
  "structure le problème et laisse les outils/le moteur calculer.";
