# Infographic Multi-Resource Engine (2026-09-22)

**Status:** `DESIGNED_NOT_IMPLEMENTED` (wave 2, Artifact + DS teams).
Authority: ADR S16 (Artifact Hub), AD-10 (InfographicRenderer contract),
05 S3.6 (InfographicRenderer DEF: `InfographicSpec` validation -> SVG),
01 S5.1 (`fn-import-course` + `artifact_gen` jobs), 04 S3.2
(Capacitor adapters, LocalFileStorageAdapter), Vercel AI SDK integration
(docs/ai/vercel-ai-sdk-integration.md), ResearchProvider (ADR S8),
Agnes model catalog (ai/providers/agnes.md, ADR v1.7 S8).

## Core Principle

The agent is the **Art Director**. It does NOT hand-draw complex SVG
shapes (slow, error-prone, token-expensive). Instead:

1. It **structures** the infographic (layout, sections, data points)
2. It **orders** external resources via 2 tools:
   - **Search Tool** -> real images from the internet (Exa/Tavily)
   - **GenAI Tool** -> illustrations/characters (Agnes Image 2.1 / 2.5 Flash,
     or fal.ai Flux Schnell as fallback)
3. The **client renderer** (AntV Infographic) assembles the hybrid
   SVG: computed layout + text + external image URLs

This keeps the AI cost per infographic extremely low (1-2 image
generations at 0.003 USD/MP or Agnes image calls) while producing
rich, visual outputs.

## Architecture

```
Vercel AI SDK Agent Kernel (server, packages/agent)
  |
  | streamText({ maxSteps, tools })
  |
  +---> [Tool 1: Search Engine]
  |      ResearchProvider.searchImages(query, {limit})
  |      -> Exa API / Tavily API (image filter)
  |      -> returns { imageUrl, source, license }
  |
  +---> [Tool 2: GenAI Image Engine]
  |      Agnes Image 2.1 / 2.5 Flash (PRIMARY)
  |      fal.ai Flux Schnell (FALLBACK, 0.003 USD/MP)
  |      -> returns { illustrationUrl, model, prompt }
  |
  +---> [Tool 3: Layout Structure]
         Agent outputs JSX-like `InfographicSpec` JSON
         (sections, groups, text, positions, image slots)

Client (apps/mobile, packages/ui)
  |
  +--> AntV Infographic engine (AD-10 InfographicRenderer)
  |     engine.render(spec) -> hybrid SVG:
  |     - computed layout (grid, tree, flow)
  |     - text + labels
  |     - <image> elements (real photos + generated illustrations)
  |
  +--> Local cache (Capacitor Filesystem + SQLite)
        - download images on first render
        - store locally (WebP compressed)
        - reference local path in AntV <image src>
        - offline: infographic renders from local cache (100%)
```

## Tool 1: Search Engine (real images)

```ts
// packages/agent/src/tools/searchImage.ts
import { tool } from 'ai';
import { z } from 'zod';

export const searchRealImageTool = tool({
  description: "Recherche une vraie image ou photo sur internet "
    + "correspondant a un mot-cle precis.",
  parameters: z.object({
    query: z.string().describe("Le sujet de l'image (ex: 'coeur humain anatomie photo')"),
    aspectRatio: z.enum(['1:1', '4:3', '16:9', 'auto']).default('4:3'),
  }),
  execute: async ({ query, aspectRatio }) => {
    // ResearchProvider port (ADR S8) -> Exa or Tavily adapter
    const results = await researchProvider.searchImages(query, {
      limit: 3,
      imageSize: 'medium', // 400-800px, mobile-optimized
      aspectRatio,
    });
    const best = results[0];
    return {
      imageUrl: best?.url ?? 'placeholder_url',
      source: best?.source ?? 'unknown',
      license: best?.license ?? 'unspecified',
    };
  },
});
```

**Providers (ADR S8, ResearchProvider port):**
- **Exa API**: `contents` endpoint with `type: "image"` filter.
  Returns direct image URLs + source + license metadata.
- **Tavily API**: `search` with `include_images: true`.
  Returns image URLs alongside text results.
- **Fallback**: if both absent (AD-1 graceful degradation),
  the tool returns `{ imageUrl: 'placeholder_url' }` and the
  infographic renders with a styled placeholder (not a broken image).

**Security (AD-3):** the Exa/Tavily API keys are server-side
(supabase secret store). The device never sees them.

## Tool 2: GenAI Image Engine (illustrations, characters)

**Primary: Agnes Image (2.1 / 2.5 Flash)**

| Model | Use case | Cost | Latency | Notes |
|---|---|---|---|---|
| **Agnes Image 2.1** | Complex illustrations, multi-element scenes, characters with detail | Per-image (check Agnes pricing) | 3-8 s | Best quality for detailed infographics |
| **Agnes Image 2.5 Flash** | Quick icons, simple vector-style illustrations, decorative elements | Lower (Flash = faster/cheaper) | 1-3 s | Good for rapid iteration, low cost |

**Fallback: fal.ai Flux Schnell**

| Model | Use case | Cost | Latency | Notes |
|---|---|---|---|---|
| **Flux Schnell (fal.ai)** | Same as Agnes Image, when Agnes is unavailable | 0.003 USD/MP | 1-2 s | Ultra-fast, very cheap; quality slightly below Agnes 2.1 |

```ts
// packages/agent/src/tools/generateIllustration.ts
export const generateIllustrationTool = tool({
  description: "Genere une illustration vectorielle ou un personnage "
    + "sur mesure pour l'infographie.",
  parameters: z.object({
    prompt: z.string().describe(
      "Description de l'illustration (ex: 'minimalist vector illustration "
      + "of a student thinking, clean background, flat style, no text')"),
    style: z.enum(['flat', 'vector', 'photo-realistic', 'sketch']).default('flat'),
    size: z.enum(['256x256', '512x512', '1024x1024']).default('512x512'),
  }),
  execute: async ({ prompt, style, size }) => {
    // PRIMARY: Agnes Image (via AIProvider port, AD-1)
    const agnesResult = await aiProvider.complete({
      type: 'image',
      provider: 'agnes',
      model: 'agnes-image-2.5-flash', // fast for infographics
      prompt: buildImagePrompt(prompt, style),
      size,
    });
    if (agnesResult.ok) {
      return { illustrationUrl: agnesResult.data.imageUrl, model: 'agnes-image-2.5-flash' };
    }
    // FALLBACK: fal.ai Flux Schnell
    const falResult = await falClient.generate({
      model: 'flux/schnell',
      prompt: buildImagePrompt(prompt, style),
      image_size: size,
    });
    return { illustrationUrl: falResult.images[0].url, model: 'flux-schnell' };
  },
});
```

**Prompt construction (style coherence):**
The agent's system prompt enforces a **charte graphique** for all
generated images:
- Style: flat vector, clean, no gradients unless theme-specific
- Color palette: derived from the active theme's accent tokens (AD-17)
- Background: white or transparent (the infographic layout provides the bg)
- Text in images: NEVER (the AntV layout renders text separately)
- Cultural context: "adapted for a West African academic audience"
  (when the user's profile declares this)

**Budget (AIBudgetManager, AD-5):**
- Per infographic: max 2 image generations (1 illustration + 1 photo
  max). The agent's system prompt enforces this.
- Daily: 20 image generations per user (Agnes) + 10 (fal.ai fallback).
- The `AIBudgetManager` tracks consumption; when the budget is
  exhausted, the tool returns placeholders (styled, not broken).

## Tool 3: Layout Structure (the agent's composition)

The agent outputs an `InfographicSpec` (AD-10 contract, 05 S3.6 DEF):

```json
{
  "type": "grid",
  "columns": 2,
  "gap": 15,
  "sections": [
    {
      "id": "sec-1",
      "label": "Le Concept",
      "imageSlot": "generated",
      "imageRef": "{{tool_2_result_1}}",
      "text": "Definition de la notion..."
    },
    {
      "id": "sec-2",
      "label": "Exemple Reel",
      "imageSlot": "searched",
      "imageRef": "{{tool_1_result_1}}",
      "caption": "Photo: Mars surface (NASA/JPL)"
    }
  ]
}
```

The `{{tool_N_result_M}}` placeholders are resolved by the Vercel AI
SDK's tool-call interception (the `onStepFinish` hook captures tool
results; the Result Normalizer injects them into the spec before
sending to the client).

## Client Rendering (AntV Infographic, AD-10)

```tsx
// packages/ui/src/renderers/InfographicRenderer.tsx
import { createInfographicEngine } from '@antv/infographic';

// The AD-10 contract: InfographicSpec -> SVG
// The spec includes <image> elements (AntV supports natively)

function InfographicRenderer({ spec, theme }: Props) {
  const engine = useMemo(() => createInfographicEngine(), []);
  // engine.render(spec) produces a hybrid SVG:
  // - layout (grid/tree/flow, computed)
  // - text labels (KaTeX for formulas, 05 S3.6)
  // - <image> elements (real photos + generated illustrations)
  // - theme accent colors (AD-17: resolveToken)
  // - animation (AD-10 AnimationController, G-M1: reveal on scroll)
  return <InfographicCanvas engine={engine} spec={spec} />;
}
```

**The `<image>` tag in AntV:** AntV Infographic's JSX engine natively
supports `<image src={url} width={w} height={h} x={x} y={y} />`.
The image can be:
- A remote URL (online: renders from network)
- A local file path (offline: Capacitor Filesystem, `cap://` protocol)
- A data URI (small images < 100KB, inlined)

## Mobile Optimization (04 S3.2, African market)

### WebP Compression (server-side)

```
Agent orders image (Exa URL or Agnes generation)
  -> Server intercepts the URL
  -> Supabase Edge Function: fetch -> convert to WebP (80% quality,
     max 800px width) -> upload to R2 (key: artifacts/images/{userId}/{hash}.webp)
  -> Return the R2 presigned URL (15 min TTL) to the client
```

The client NEVER loads a raw 4K JPEG from the internet. It gets a
compressed WebP from R2 (Aurora's own storage, presigned).

### Local Cache (Capacitor + SQLite, offline)

```
First render (online):
  1. Client receives the InfographicSpec with image URLs (R2 presigned)
  2. Client downloads each image (WebP, 50-200KB each)
  3. Client stores in Capacitor Filesystem:
     /data/{artifactId}/{imageHash}.webp
  4. Client updates the InfographicSpec: imageSrc = cap://data/{hash}.webp
  5. Client persists the updated spec in SQLite (PowerSync table:
     artifact_images: {artifactId, slot, localPath, url, hash})

Subsequent renders (offline):
  1. Client loads InfographicSpec from SQLite
  2. Image URLs = cap:// paths (local, no network)
  3. AntV renders the infographic 100% offline
  4. PowerSync upsyncs the artifact (metadata only, images are local)
```

**Result: the infographic works offline. The images are on the
phone. No re-download needed.**

### Size budget per infographic

| Element | Size | Notes |
|---|---|---|
| Layout (SVG paths, text) | 5-20 KB | computed by AntV, inline |
| 1 generated illustration (WebP) | 30-80 KB | Agnes 2.5 Flash, 512x512, 80% quality |
| 1 real photo (WebP) | 50-150 KB | Exa source, compressed to 800px, 80% quality |
| Total per infographic | < 250 KB | fits in mobile memory, offline cache |

## Agnes Image Models (ai/providers/agnes.md, additive)

Add to the Agnes provider page:

| Model ID | Type | Use | Cost | Notes |
|---|---|---|---|---|
| `agnes-image-2.1` | image generation | complex illustrations, multi-element scenes | per-image (check account) | best quality; slower (3-8s) |
| `agnes-image-2.5-flash` | image generation | icons, simple vector-style, decorative | lower (Flash) | fast (1-3s); good for infographics |

**Routing (AIModelRouter, v1.7 S6/S14):**
- Infographic illustration: `agnes-image-2.5-flash` (fast, cheap, good enough)
- Complex character / scene: `agnes-image-2.1` (quality)
- Fallback (Agnes unavailable): `fal.ai flux/schnell` (0.003 USD/MP)
- The Model Registry entry: capabilities = `["image-generation"]`,
  modality = `text->image`, context = N/A (prompt only)

## Aesthetic Coherence (the "not robotic" rule)

The agent's system prompt enforces:

```
Charte graphique Aurora (applied to all generated images):
- Style: flat vector, clean lines, no photorealism unless the
  subject requires it (e.g., "Mars surface" = photo, "concept X" = vector)
- Palette: 3 max colors per image, derived from the active theme
  accent tokens (AD-17: resolveToken('accent', theme))
- Background: white (#FFFFFF) or transparent. NEVER a gradient bg.
- Text in image: FORBIDDEN. The AntV layout renders all text.
  The image is a VISUAL ELEMENT, not a text carrier.
- Consistency: if the infographic has 2 illustrations, they MUST
  share the same style (both flat vector, same line weight, same
  color palette). The agent passes the same style params to both
  generation calls.
- Cultural: "adapted for the user's context" (from UserContext,
  NOT hardcoded). If the profile says "engineering student, West
  African context", the illustrations reflect that.
```

The agent does NOT free-generate art. It orders **specific,
scoped, style-locked** image generations. The Art Director
role means: structure + order + verify, not paint.

## Tests (wave 2+)

- Search tool: Exa/Tavily returns valid image URL; placeholder on
  provider absent (AD-1)
- GenAI tool: Agnes Image 2.5 Flash returns a valid image; fal.ai
  fallback works when Agnes is down; budget cap enforced (2 per
  infographic, 20 daily)
- WebP compression: R2 object is WebP, < 200KB, 800px max
- Local cache: offline render works (cap:// paths); PowerSync
  upsyncs metadata, not images
- AntV rendering: hybrid SVG (layout + images) renders at 30 fps
  on Pixel 4a; < 250KB total per infographic
- Theme adaptation: infographic colors change with theme (AD-17);
  semantic tokens (success/warning/danger) are independent
- Aesthetic: 2 illustrations in the same infographic share style
  (flat, same palette, no text in image)
