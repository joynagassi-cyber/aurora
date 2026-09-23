// Test du spine — type-check croise entre les deux equipes (SPEC wave 0).
//
// "test du spine (deux equipes obeissant a leurs packs produisent le
//  meme contrat) verifie a chaque merge" (SPEC.md, Plan de Contract
//  Packs wave 0, AD-15/AD-13).
//
// Mechanisme: les projections declarees de l'equipe A et de l'equipe B
// sont assertees mutuellement assignables (invariante = les deux
// contrats sont le meme type structurel). Si l'une des deux equipes
// re-declaire Task au lieu de consommer packages/domain, la signature
// diverge et le type-check croise echoue.
//
// Execution: pnpm -r exec vitest run tests/spine
//   - tant que packages/domain n'existe pas (ACHILLES crele en
//     parallele, wave 0), le CI wave 0 branche ce test en
//     continue-on-error + skip with reason (pas de FAIL bloquant,
//     le test doit etre runnable des que le workspace existe).
//
// Refs: SPEC.md wave 0, AD-15 (SSoT), AD-13 (one-writer / contract packs),
//       docs/architecture/dependency-matrix.md S15 ("Testing the Decoupling").

import { ContractA, contractA } from "./equipe-a.contract.js";
import { ContractB, contractB } from "./equipe-b.contract.js";

// ---- Type-check croise: le contrat A = le contrat B (mutuelle assignability)
const sample = {
  id: "task-1",
  title: "Waves",
  status: "todo" as const,
  dueAt: null,
  updatedAt: "2026-09-23T00:00:00Z",
};

const a: ContractA = contractA(sample);
const b: ContractB = contractB(sample);

// Bi-assignable = meme contrat structurellement. Un drift d'une equipe
// (champ ajoute, type divergent) casse ces deux assignments.
const _asB: ContractB = a;
const _asA: ContractA = b;

// ---- Runtime: meme entree -> meme sortie (le contrat est aussi deterministe)
if (JSON.stringify(a) !== JSON.stringify(b)) {
  throw new Error(
    `spine contract drift: equipeA=${JSON.stringify(a)} equipeB=${JSON.stringify(b)}`,
  );
}

export { _asA, _asB };
// Le fichier est un module consommable par vitest ; s'il est importe
// (pas execute comme test), le type-check croise est verifie au
// type-check par tsc. En mode vitest, le module charge les imports et
// le branchement de runtime est verifie.
