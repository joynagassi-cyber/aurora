/**
 * ResearchProvider adapters (AD-1: vendors ONLY in adapter packages).
 *
 * Exa / Tavily / You.com implementations of the `ResearchProvider` SSoT
 * port (`packages/domain/src/research-provider.ts`). All are OPTIONAL:
 * `isConfigured()` is false when the API key env var is missing, and the
 * module degrades to `uncertain`-marked results (01 §6) instead of
 * breaking the product (AD-1 last paragraph). Secrets come from env
 * (AD-3: server-only keys, never on device / never hardcoded).
 *
 * Vendor SDK isolation: plain `fetch` to the provider REST API — no
 * vendor SDK packages, no new dependencies.
 */
import type {
  ResearchCredibility,
  ResearchProvider,
  ResearchQuery,
  ResearchResult,
  ResearchSourceKind,
} from '@aurora/domain';

/** Map a provider hit to the typed `ResearchResult` SSoT shape. */
function toResult(
  provider: string,
  kind: ResearchSourceKind,
  hit: {
    title: string;
    url?: string;
    summary?: string;
    score?: number;
  },
): ResearchResult {
  return {
    provider,
    kind,
    title: hit.title,
    url: hit.url,
    summary: hit.summary ?? '',
    confidence: hit.score !== undefined ? Math.max(0, Math.min(1, hit.score)) : 0.5,
    credibility: 'frequent' satisfies ResearchCredibility,
  };
}

/** Exa adapter (AD-1 optional). Configured when EXA_API_KEY is present. */
export class ExaResearchProvider implements ResearchProvider {
  readonly id: string = 'exa';
  private readonly apiKey: string;
  private readonly url: string;

  constructor() {
    this.apiKey = process.env.EXA_API_KEY ?? '';
    this.url = process.env.EXA_URL ?? 'https://api.exa.ai/search';
  }

  isConfigured(): boolean {
    return this.apiKey !== '';
  }

  async search(query: ResearchQuery): Promise<ResearchResult[]> {
    if (!this.isConfigured()) return [];
    const kind: ResearchSourceKind =
      query.region !== undefined ? 'local-regional' : 'technical';
    const res = await fetch(this.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': this.apiKey,
      },
      body: JSON.stringify({
        query: `${query.topic} ${query.domains.join(' ')}`,
        numResults: query.limit ?? 10,
        type: 'auto',
      }),
    });
    if (!res.ok) {
      // Transient / quota-drift (G-U4) → degrade, don't throw.
      return [
        {
          provider: this.id,
          kind,
          title: query.topic,
          summary: `Exa request failed (${res.status}); result marked uncertain.`,
          confidence: 0,
          credibility: 'uncertain',
          provenance: { degraded: true, degradeReason: `http_${res.status}` },
        },
      ];
    }
    const data = (await res.json()) as {
      results?: Array<{ title?: string; url?: string; summary?: string; score?: number }>;
    };
    const results = data.results ?? [];
    return results.map((r) =>
      toResult(this.id, kind, {
        title: r.title ?? '',
        url: r.url,
        summary: r.summary,
        score: r.score,
      }),
    );
  }
}

/** Tavily adapter (AD-1 optional). Configured when TAVILY_API_KEY is present. */
export class TavilyResearchProvider implements ResearchProvider {
  readonly id: string = 'tavily';
  private readonly apiKey: string;
  private readonly url: string;

  constructor() {
    this.apiKey = process.env.TAVILY_API_KEY ?? '';
    this.url = process.env.TAVILY_URL ?? 'https://api.tavily.com/search';
  }

  isConfigured(): boolean {
    return this.apiKey !== '';
  }

  async search(query: ResearchQuery): Promise<ResearchResult[]> {
    if (!this.isConfigured()) return [];
    const kind: ResearchSourceKind =
      query.region !== undefined ? 'local-regional' : 'technical';
    const res = await fetch(this.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        query: `${query.topic} ${query.domains.join(' ')}`,
        maxResults: query.limit ?? 10,
        searchDepth: 'advanced',
      }),
    });
    if (!res.ok) {
      return [
        {
          provider: this.id,
          kind,
          title: query.topic,
          summary: `Tavily request failed (${res.status}); result marked uncertain.`,
          confidence: 0,
          credibility: 'uncertain',
          provenance: { degraded: true, degradeReason: `http_${res.status}` },
        },
      ];
    }
    const data = (await res.json()) as {
      results?: Array<{ title?: string; url?: string; content?: string; score?: number }>;
    };
    const results = data.results ?? [];
    return results.map((r) =>
      toResult(this.id, kind, {
        title: r.title ?? '',
        url: r.url,
        summary: r.content,
        score: r.score,
      }),
    );
  }
}

/** You.com adapter (AD-1 optional). Configured when YOU_API_KEY is present. */
export class YouComResearchProvider implements ResearchProvider {
  readonly id: string = 'you-dot-com';
  private readonly apiKey: string;
  private readonly url: string;

  constructor() {
    this.apiKey = process.env.YOU_API_KEY ?? '';
    this.url = process.env.YOU_URL ?? 'https://api.you.com/api/v1/search';
  }

  isConfigured(): boolean {
    return this.apiKey !== '';
  }

  async search(query: ResearchQuery): Promise<ResearchResult[]> {
    if (!this.isConfigured()) return [];
    const kind: ResearchSourceKind =
      query.region !== undefined ? 'local-regional' : 'technical';
    const res = await fetch(this.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        query: `${query.topic} ${query.domains.join(' ')}`,
        count: query.limit ?? 10,
      }),
    });
    if (!res.ok) {
      return [
        {
          provider: this.id,
          kind,
          title: query.topic,
          summary: `You.com request failed (${res.status}); result marked uncertain.`,
          confidence: 0,
          credibility: 'uncertain',
          provenance: { degraded: true, degradeReason: `http_${res.status}` },
        },
      ];
    }
    const data = (await res.json()) as {
      results?: Array<{ title?: string; url?: string; snippet?: string; score?: number }>;
    };
    const results = data.results ?? [];
    return results.map((r) =>
      toResult(this.id, kind, {
        title: r.title ?? '',
        url: r.url,
        summary: r.snippet,
        score: r.score,
      }),
    );
  }
}

/**
 * Provider factory (AD-15: open to additions). Resolution order:
 * exa → tavily → you-dot-com; the first CONFIGURED provider wins. When
 * none is configured, returns an "offline" provider so the loop degrades
 * to `uncertain` marking instead of breaking (01 §6).
 */
export function createResearchProvider(): ResearchProvider {
  const candidates: ResearchProvider[] = [
    new ExaResearchProvider(),
    new TavilyResearchProvider(),
    new YouComResearchProvider(),
  ];
  const configured = candidates.find((p) => p.isConfigured());
  if (configured !== undefined) return configured;
  return {
    id: 'offline',
    isConfigured: () => false,
    search: async () => [],
  };
}
