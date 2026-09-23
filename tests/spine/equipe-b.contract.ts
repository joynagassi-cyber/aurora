// Equipe B — test du spine (miroir de l'equipe A, meme contrat).
//
// L'equipe B consomme le meme contrat Task depuis packages/domain et produit
// une projection declaree IDENTIQUE en type a celle de l'equipe A. Le
// type-check croise (tests/spine/spine.test.ts) prouve que les deux equipes,
// obeissant a leurs Contract Packs (AD-13), produisent le meme contrat
// (AD-15: pas de re-declaration, une SSoT par entite).

// Meme rationale que l'equipe A — tant que packages/domain n'existe pas,
// le test tourne en continue-on-error dans le CI (skip with reason).
// import { Task } from "@aurora/domain";

export interface TaskRowB {
  id: string;
  title: string;
  status: "todo" | "in_progress" | "done";
  dueAt: string | null;
  updatedAt: string;
}

export function contractB(task: { id: string; title: string; status: string; dueAt: string | null; updatedAt: string }): TaskRowB {
  return {
    id: task.id,
    title: task.title,
    status: task.status as TaskRowB["status"],
    dueAt: task.dueAt,
    updatedAt: task.updatedAt,
  };
}

export type ContractB = TaskRowB;
