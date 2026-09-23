// Equipe A — test du spine (SPEC wave 0: "deux equipes obeissant a leurs
// packs produisent le meme contrat" — type-check croise, pas de re-declaration).
//
// L'equipe A consomme le contrat Task depuis packages/domain (SSoT AD-15)
// et produit une projection declaree (view, pas une re-declaration).
// Le contrat produit DOIT matcher ce que l'equipe B produit independamment
// (tests/spine/equipe-b.test.ts) — sinon le type-check croise echoue.

// Le type vienne de l'unique SSoT (AD-15, F-01). Tant que
// packages/domain n'existe pas (ACHILLES crele en parallele), ce test est
// un squelette qui echoue le type-check — le CI wave 0 le lance en
// continue-on-error + skip with reason (pas de FAIL bloquant).
// import { Task, TaskStatus } from "@aurora/domain";

// Contrat produit par l'equipe A : projection declaree du Task.
export interface TaskRowA {
  id: string;
  title: string;
  status: "todo" | "in_progress" | "done";
  dueAt: string | null;
  updatedAt: string;
}

// L'equipe A NE RE-DECLARE PAS Task elle-meme : elle consomme le type
// partiel du SSoT et le projecte. En attendant packages/domain, on
// materialise le contrat cible que B doit produire en miroir.
export function contractA(task: { id: string; title: string; status: string; dueAt: string | null; updatedAt: string }): TaskRowA {
  return {
    id: task.id,
    title: task.title,
    status: task.status as TaskRowA["status"],
    dueAt: task.dueAt,
    updatedAt: task.updatedAt,
  };
}

export type ContractA = TaskRowA;
