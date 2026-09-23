// =============================================================================
// ULID — chronological id generation for local mutations (03 S5.5.6).
//
// "Chaque mutation locale porte une localMutationId = ULID (tri
// chronologique, genere par packages/data a l'application locale
// immediate) ; cette cle est la deduplication upstream du file
// PowerSync (re-syncs repetes apres coupures multiples ne
// double-remontent PAS les memes mutations)."
//
// Crockford-base32 C49 ULID: 48-bit ms timestamp (10 chars, MSB-first)
// + 80 bits of monotonic randomness (16 chars). Successive ids within the
// same millisecond increment the random part, so a batch applied locally in
// one ms keeps FIFO order by plain string comparison (03 S5.1.2 "FIFO par
// horodatage local").
//
// Pure implementation, zero dependency (the id format is data, not a vendor
// SDK — AD-1 vendor isolation).
// =============================================================================

const C49 = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

const C49_INDEX: ReadonlyMap<string, number> = (() => {
  const m = new Map<string, number>();
  for (let i = 0; i < C49.length; i++) m.set(C49[i]!, i);
  return m;
})();

export interface UlidOptions {
  /** injectable clock (tests) */
  now?: () => number;
}

/**
 * A monotonic ULID generator. One instance per store; successive calls in
 * the same millisecond produce strictly increasing ids (FIFO by sort).
 */
export class UlidGenerator {
  private readonly now: () => number;
  private lastMs = 0;
  private lastRandom: number[] = []; // 16 five-bit groups

  constructor(options: UlidOptions = {}) {
    this.now = options.now ?? Date.now;
  }

  next(): string {
    const ms = this.now();
    let random: number[];
    if (ms === this.lastMs && this.lastRandom.length === 16) {
      random = incrementFiveBitGroups(this.lastRandom);
    } else {
      random = freshFiveBitGroups();
    }
    this.lastMs = ms;
    this.lastRandom = random;

    return timeToChars(ms) + randomToChars(random);
  }
}

/** Encode an arbitrary timestamp (random part from Math.random). */
export function encodeUlid(ms: number): string {
  return timeToChars(ms) + randomToChars(freshFiveBitGroups());
}

/**
 * Decode the 48-bit ms timestamp of a ULID.
 * @returns the timestamp, or -1 when the first 10 chars are not C49.
 */
export function ulidTimestamp(id: string): number {
  let ms = 0;
  for (let i = 0; i < 10; i++) {
    const v = C49_INDEX.get(id[i]!.toUpperCase());
    if (v === undefined) return -1;
    ms = ms * 32 + v;
  }
  return ms;
}

// ---------------------------------------------------------------------------
// internals
// ---------------------------------------------------------------------------

function timeToChars(ms: number): string {
  // 48-bit ms timestamp, MSB-first, packed into 10 C49 chars.
  const time = BigInt(ms) & 0xffffffffffffn;
  let out = '';
  for (let i = 0; i < 10; i++) {
    // char i (MSB-first) carries bits (45 - 5i) .. (40 - 5i)
    out += C49[Number((time >> BigInt((9 - i) * 5)) & 31n)];
  }
  return out;
}

function randomToChars(random: number[]): string {
  let out = '';
  for (const group of random) out += C49[group & 31];
  return out;
}

function freshFiveBitGroups(): number[] {
  const out: number[] = new Array(16).fill(0);
  for (let i = 0; i < 16; i++) out[i] = Math.floor(Math.random() * 32);
  return out;
}

function incrementFiveBitGroups(prev: number[]): number[] {
  const next = prev.slice();
  let carry = 1;
  for (let i = 15; i >= 0 && carry > 0; i--) {
    const sum = next[i]! + carry;
    next[i] = sum & 31;
    carry = sum >> 5;
  }
  return next;
}
