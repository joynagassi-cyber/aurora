-- =============================================================================
-- Aurora Wave 0 — Migration 0011: Registres (01 §4.10, AD-5/AD-16b)
-- model_registry + ai_usage + ai_health. Owner = packages/data / Foundation.
-- These are FROZEN-included in wave 0 even though the epics don't cite them
-- (lead decision, 01 §4.10). AD-5: only the Model Registry may retire a
-- provider (status 'retired').
-- =============================================================================

CREATE TABLE model_registry (
  provider     text NOT NULL,
  model        text NOT NULL,
  capabilities text[] NOT NULL DEFAULT '{}',
               -- reasoning|tool_calling|vision|audio|long_ctx
  status       text NOT NULL DEFAULT 'active'
               CHECK (status IN ('active','cooldown','retired')),
  quota        jsonb,
  data_policy  jsonb,   -- provider DataPolicy (ADR §11)
  cost_class   text,
  version      int NOT NULL DEFAULT 1,
  evaluated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (provider, model, version)
);

CREATE TABLE ai_usage (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider       text NOT NULL,
  model          text NOT NULL,
  env            text NOT NULL,
  user_id        uuid,
  tokens         int,
  latency_ms     int,
  cost           numeric(12,6),
  free_tier_remaining numeric(12,6),
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_ai_usage_provider_model ON ai_usage (provider, model, env, created_at);

CREATE TABLE ai_health (
  provider     text NOT NULL,
  model        text NOT NULL,
  status       text NOT NULL DEFAULT 'active'
               CHECK (status IN ('active','degraded','cooldown','retired')),
  error_rate   numeric(6,4),
  last_error_at timestamptz,
  last_429_at  timestamptz,
  cooldown_until timestamptz,
  ok           boolean NOT NULL DEFAULT true,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (provider, model)
);

-- ai_health is fed by AIUsageTracker on every provider response (01 §4.10):
-- sliding window; AIFallbackStrategy READS it, never recomputes locally.
ALTER TABLE ai_health ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_health FORCE ROW LEVEL SECURITY;
CREATE POLICY ai_health_service_read ON ai_health
  FOR SELECT TO service_role USING (true);  -- registry rows are global, per provider/model
CREATE POLICY ai_health_service_write ON ai_health
  FOR ALL TO service_role USING (true) WITH CHECK (true);
-- Rationale: ai_health is a server-side registry (no per-user scoping),
-- written only by AIUsageTracker (Foundation), read only by AIFallbackStrategy.
-- Both run as service_role server-side. There is NO user row dimension, so the
-- policy is global-by-design and explicitly justified (not an unbounded user path).

ALTER TABLE model_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_registry FORCE ROW LEVEL SECURITY;
CREATE POLICY model_registry_service ON model_registry
  FOR ALL TO service_role USING (true) WITH CHECK (true);
-- Rationale: model_registry is a global server registry (AD-16b owner =
-- Foundation). No user dimension. Access is service_role-only and justified.

ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage FORCE ROW LEVEL SECURITY;
CREATE POLICY ai_usage_user_read ON ai_usage
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY ai_usage_service_role ON ai_usage
  FOR ALL TO service_role USING (true) WITH CHECK (true);
-- Rationale: AIUsageTracker (Foundation) writes cross-user rows; users read
-- only their own usage. service_role write path justified (registry writer).

CREATE TRIGGER ai_health_updated BEFORE UPDATE ON ai_health
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
