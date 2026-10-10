-- =============================================================================
-- Aurora — Migration 0025: Discovery vault (0025, discovery-vault plan
-- 2026-10-10, Lot 2) + user_context.discovery_profile (Lot 1 SSoT column)
--
-- ADDITIF ONLY (01 §2.1: the Aurora schema is additive on the shared
-- instance) : one new table `discovery_vault` (Discovery owner, AD-7
-- single-writer) + one new nullable jsonb column on the existing
-- Identity-owned table `user_context` (Lot 1 : le type additif
-- `DiscoveryProfile` (AD-15) avait besoin de sa colonne SSoT pour que
-- `resolveUserContext` (fn-job-dispatcher) ne dégrade PLUS à null en
-- production).
--
-- Vault V1 (tranché 2026-10-10) : Postgres `discovery_vault` + Supabase
-- Storage (PNGs, pas R2 — R2 = V2, OQ-03). Synchronisé via PowerSync
-- (flux `discovery_vault`, vue `v_discovery_vault_scope`).
--
-- RLS (01 §2.2) : ENABLE + FORCE sur `discovery_vault` (jamais de
-- BYPASSRLS, AD-16/AD-7) ; policies `user_isolation` + `service_role`
-- (SELECT, bound by user_id — même pattern que 0006/0008).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. `discovery_vault` (owner Discovery) — une ligne par (user, domaine) :
-- le SSoT évolutif du vault (VAULT.md + manifest append-only).
-- -----------------------------------------------------------------------------
CREATE TABLE discovery_vault (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  -- le domaine de veille (ex. 'structures', 'genie-civil-sol')
  domaine       text NOT NULL,
  -- le document Markdown évolutif (VAULT.md)
  vault_md      text NOT NULL DEFAULT '',
  -- SHA-256 de vault_md post-run (intégrité ; hash ≠ manifest = corrompu)
  vault_hash    text NOT NULL DEFAULT '',
  -- le manifest append-only (index.json) : runs, sections touchées,
  -- count sources, verbes + runId (traçabilité AD-7)
  runs_manifest jsonb NOT NULL DEFAULT '[]'::jsonb,
  -- préfixe Supabase Storage des PNG du vault ({env}/{user_id}/discovery/{domaine}/)
  storage_prefix text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, domaine)
);

COMMENT ON TABLE discovery_vault IS
  'Discovery module (AD-7 owner) : le vault de veille par (user, domaine) — '
  'VAULT.md évolutif + manifest append-only (runs). Écrit UNIQUEMENT par le '
  'job research (AD-7 single-writer) ; lu par le client (PowerSync) + l'agent '
  'chat (READ-ONLY, Lot 3). discovery-vault plan 2026-10-10.';

CREATE TRIGGER discovery_vault_updated BEFORE UPDATE ON discovery_vault
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS (01 §2.2) : ENABLE + FORCE ; user_isolation (owner) + service_role
-- SELECT (relay PowerSync / dispatcher, bound by user_id — jamais de
-- BYPASSRLS, AD-16).
ALTER TABLE discovery_vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE discovery_vault FORCE ROW LEVEL SECURITY;

CREATE POLICY discovery_vault_user_isolation ON discovery_vault
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- JUSTIFICATION service_role : le relay PowerSync + le dispatcher lisent le
-- vault sous RLS (01 §3.4, 03 §5.5) — bound by user_id, jamais de BYPASSRLS.
CREATE POLICY discovery_vault_service_role ON discovery_vault
  FOR SELECT TO service_role
  USING (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 2. `user_context.discovery_profile` (Lot 1, ADDITIF) — la colonne SSoT du
-- type additif `DiscoveryProfile` (AD-15, packages/domain entities-identity.ts).
-- Sans elle, `resolveUserContext` (fn-job-dispatcher) ne peut jamais lire les
-- disciplines réelles de l'utilisateur → dégradation permanente à null.
-- -----------------------------------------------------------------------------
ALTER TABLE user_context
  ADD COLUMN IF NOT EXISTS discovery_profile jsonb;

COMMENT ON COLUMN user_context.discovery_profile IS
  'Lot 1 (discovery-vault plan 2026-10-10) : profil de découverte de '
  'l''utilisateur (G-D14 : disciplines, region, professionalTarget, '
  'budgetConstraint) — shape SSoT `DiscoveryProfile` (AD-15, '
  'packages/domain/src/entities-identity.ts). Nullable : l''utilisateur peut '
  'n''en pas avoir encore ; le filtres de découverte dégrade à { disciplines: [] } '
  '(AD-1, jamais de rupture).';

-- -----------------------------------------------------------------------------
-- 3. Vue de scope PowerSync (owner Discovery) — ajout à v_discovery_scope
-- (0015) plutôt qu'une nouvelle vue : le flux `discovery` expose déjà
-- discovery_items ; on Y AJOUTE discovery_vault (même owner, même module,
-- pas de cross-module JOIN, F-03).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_discovery_vault_scope WITH (security_invoker = on) AS
SELECT id, user_id, domaine, vault_md, vault_hash, runs_manifest,
       storage_prefix, created_at, updated_at
FROM discovery_vault;

-- Le relay (service_role) lit la vue ; RLS borne les lignes (AD-16).
GRANT SELECT ON v_discovery_vault_scope TO service_role;
