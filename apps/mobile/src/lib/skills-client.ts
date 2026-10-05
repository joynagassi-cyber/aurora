// =============================================================================
// skills-client.ts — device-side Skills Marketplace / fn-skills client
// (AD-3: the device invokes the `fn-skills` EF, like the integrations client).
//
// The skills store (skill_catalog + user_skills) is server-side. This module
// is the device's typed door:
//   - `listCatalog()` / `listUserSkills()` / `activateSkill()` /
//     `deactivateSkill()` / `createUserSkill()` / `deleteUserSkill()`
//     all POST to `fn-skills` with the user JWT (the Supabase client carries
//     it; the body NEVER carries identity, AD-7).
//
// AD-3: only the publishable Supabase client is used — zero provider keys on
// the device.
// =============================================================================

import type { AuroraSupabaseClient } from '@aurora/data';

/** A row of the global, curated skill catalog (public read). */
export interface SkillCatalogEntry {
  skillKey: string;
  domain: string;
  name: string;
  trigger: string | null;
  objective: string | null;
  procedure: string[];
  constraints: string[];
  tools: string[];
  source: string;
  description: string | null;
  /** The full markdown SKILL.md body (0021 seed). null for builtin. */
  body: string | null;
}

/** A user-activated skill (RLS-isolated, this user's rows only). */
export interface UserSkillRow {
  id: string;
  skillKey: string;
  domain: string;
  name: string;
  trigger: string | null;
  objective: string | null;
  procedure: string[];
  constraints: string[];
  tools: string[];
  source: string;
  active: boolean;
  /** The markdown body copied from the catalog at activation (0021). */
  body: string | null;
  createdAt: string;
  updatedAt: string;
}

/** Payload to create a personal skill (task 2: user-authored skills). */
export interface CreateSkillPayload {
  name: string;
  domain: string;
  trigger?: string;
  objective?: string;
  procedure?: string[];
  constraints?: string[];
  tools?: string[];
}

export interface SkillClient {
  listCatalog(domain?: string): Promise<SkillCatalogEntry[]>;
  listUserSkills(): Promise<UserSkillRow[]>;
  activateSkill(
    skillKey: string,
    opts?: {
      domain?: string;
      name?: string;
      trigger?: string;
      objective?: string;
      procedure?: string[];
      constraints?: string[];
      tools?: string[];
      source?: string;
    },
  ): Promise<void>;
  deactivateSkill(skillKey: string): Promise<void>;
  createUserSkill(payload: CreateSkillPayload): Promise<string>;
  deleteUserSkill(skillKey: string): Promise<void>;
}

// PostgREST rows use snake_case columns; the EF returns them as-is. We map to
// the camelCase device types here (AD-15: the domain/client types are the
// device contract).

function mapCatalog(row: Record<string, unknown>): SkillCatalogEntry {
  return {
    skillKey: String(row.skill_key ?? ''),
    domain: String(row.domain ?? 'documents'),
    name: String(row.name ?? row.skill_key ?? ''),
    trigger: (row.trigger_ as string | null) ?? null,
    objective: (row.objective as string | null) ?? null,
    procedure: Array.isArray(row.procedure) ? (row.procedure as string[]) : [],
    constraints: Array.isArray(row.constraints) ? (row.constraints as string[]) : [],
    tools: Array.isArray(row.tools) ? (row.tools as string[]) : [],
    source: String(row.source ?? 'builtin'),
    description: (row.description as string | null) ?? null,
    body: (row.body as string | null) ?? null,
  };
}

function mapUserSkill(row: Record<string, unknown>): UserSkillRow {
  return {
    id: String(row.id ?? ''),
    skillKey: String(row.skill_key ?? ''),
    domain: String(row.domain ?? 'documents'),
    name: String(row.name ?? row.skill_key ?? ''),
    trigger: (row.trigger_ as string | null) ?? null,
    objective: (row.objective as string | null) ?? null,
    procedure: Array.isArray(row.procedure) ? (row.procedure as string[]) : [],
    constraints: Array.isArray(row.constraints) ? (row.constraints as string[]) : [],
    tools: Array.isArray(row.tools) ? (row.tools as string[]) : [],
    source: String(row.source ?? 'user-created'),
    active: Boolean(row.active ?? false),
    body: (row.body as string | null) ?? null,
    createdAt: String(row.created_at ?? ''),
    updatedAt: String(row.updated_at ?? ''),
  };
}

export function createSkillClient(supabase: AuroraSupabaseClient): SkillClient {
  return {
    async listCatalog(domain) {
      const { data, error } = await supabase.functions.invoke('fn-skills', {
        body: { verb: 'list_catalog', domain },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; data?: { catalog?: Record<string, unknown>[] }; error?: { message?: string } };
      if (!env?.ok) throw new Error(env?.error?.message ?? 'fn-skills: list_catalog failed');
      return (env.data?.catalog ?? []).map(mapCatalog);
    },
    async listUserSkills() {
      const { data, error } = await supabase.functions.invoke('fn-skills', {
        body: { verb: 'list_user_skills' },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; data?: { skills?: Record<string, unknown>[] }; error?: { message?: string } };
      if (!env?.ok) throw new Error(env?.error?.message ?? 'fn-skills: list_user_skills failed');
      return (env.data?.skills ?? []).map(mapUserSkill);
    },
    async activateSkill(skillKey, opts) {
      const { data, error } = await supabase.functions.invoke('fn-skills', {
        body: {
          verb: 'activate_skill',
          skillKey,
          domain: opts?.domain,
          name: opts?.name,
          trigger_: opts?.trigger,
          objective: opts?.objective,
          procedure: opts?.procedure,
          constraints: opts?.constraints,
          tools: opts?.tools,
          source: opts?.source,
        },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; error?: { message?: string } };
      if (!env?.ok) throw new Error(env?.error?.message ?? 'fn-skills: activate_skill failed');
    },
    async deactivateSkill(skillKey) {
      const { data, error } = await supabase.functions.invoke('fn-skills', {
        body: { verb: 'deactivate_skill', skillKey },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; error?: { message?: string } };
      if (!env?.ok) throw new Error(env?.error?.message ?? 'fn-skills: deactivate_skill failed');
    },
    async createUserSkill(payload) {
      const { data, error } = await supabase.functions.invoke('fn-skills', {
        body: {
          verb: 'create_user_skill',
          name: payload.name,
          domain: payload.domain,
          trigger_: payload.trigger,
          objective: payload.objective,
          procedure: payload.procedure ?? [],
          constraints: payload.constraints ?? [],
          tools: payload.tools ?? [],
        },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; data?: { created?: string }; error?: { message?: string } };
      if (!env?.ok) throw new Error(env?.error?.message ?? 'fn-skills: create_user_skill failed');
      return env.data?.created ?? '';
    },
    async deleteUserSkill(skillKey) {
      const { data, error } = await supabase.functions.invoke('fn-skills', {
        body: { verb: 'delete_user_skill', skillKey },
      });
      if (error) throw error;
      const env = data as { ok?: boolean; error?: { message?: string } };
      if (!env?.ok) throw new Error(env?.error?.message ?? 'fn-skills: delete_user_skill failed');
    },
  };
}
