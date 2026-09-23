# Agnes Image 2.5 Flash — Full API Reference (2026-09-22)

**Source:** https://www.agnes-ai.com/en/docs/agnes-image-25-flash
**Snapshot date:** 2026-09-22. **Pricing subject to change** (G-U4 rule:
free tier = dated photograph, not a permanent guarantee).

## Model Identity

| Field | Value |
|---|---|
| Model ID | `agnes-image-2.5-flash` |
| API Endpoint | `POST https://apihub.agnes-ai.com/v1/images/generations` |
| Auth | `Authorization: Bearer {AGNES_API_KEY}` (server-side, AD-3) |
| Content-Type | `application/json` |
| Generation | Agnes AI (latest, supersedes 2.1 Flash) |
| Role in Aurora | Primary image generation for infographics (illustrations, characters, icons) |

## Request Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `model` | string | YES | Must be `"agnes-image-2.5-flash"` |
| `prompt` | string | YES | Text instruction for generation or editing |
| `size` | string | YES | Output size tier: `"1K"`, `"2K"`, `"3K"`, `"4K"` (legacy exact sizes like `"1024x768"` accepted but may be normalized) |
| `ratio` | string | No | Aspect ratio with tier-based size. Default: `"1:1"`. See supported ratios below |
| `image` | string[] | For img2img / multi-image | Input image array: public HTTPS URLs or Data URI Base64. Multiple images = multi-image composition |
| `return_base64` | boolean | No | Top-level flag: return text-to-image as Base64 instead of URL |
| `extra_body` | object | No | Advanced params: `response_format`, `image` (for img2img) |
| `extra_body.response_format` | string | No | `"url"` (default) or `"b64_json"`. **MUST be in extra_body, NOT top-level** |
| `extra_body.image` | string[] | For img2img | Input images for image-to-image or multi-image composition |

## Supported Aspect Ratios

| Ratio | 1K | 2K | 3K | 4K |
|---|---|---|---|---|
| 1:1 | 1024x1024 | 2048x2048 | 3072x3072 | 4096x4096 |
| 3:4 | 864x1152 | 1728x2304 | 2592x3456 | 3456x4608 |
| 4:3 | 1152x864 | 2304x1728 | 3456x2592 | 4608x3456 |
| 16:9 | 1312x736 | 2624x1472 | 3936x2208 | 5248x2944 |
| 9:16 | 736x1312 | 1472x2624 | 2208x3936 | 2944x5248 |
| 2:3 | 832x1248 | 1664x2496 | 2496x3744 | 3328x4992 |
| 3:2 | 1248x832 | 2496x1664 | 3744x2496 | 4992x3328 |
| 21:9 | 1568x672 | 3136x1344 | 4704x2016 | 6272x2688 |

**For Aurora infographics:** use `size: "1K"` + `ratio: "4:3"` (1152x864)
or `ratio: "1:1"` (1024x1024) for card-style illustrations. Use `size: "2K"`
+ `ratio: "16:9"` (2624x1472) for wide banners/hero images.

## Request Examples

### Text-to-Image (URL output)

```json
POST https://apihub.agnes-ai.com/v1/images/generations
{
  "model": "agnes-image-2.5-flash",
  "prompt": "A luminous floating city above a misty canyon at sunrise, cinematic realism, wide-angle composition, rich architectural details, soft golden light, high visual density",
  "size": "1K",
  "ratio": "4:3",
  "extra_body": { "response_format": "url" }
}
```

### Text-to-Image (Base64 output)

```json
{
  "model": "agnes-image-2.5-flash",
  "prompt": "A clean product photo of a glass cube on a white studio background, soft shadows, high detail",
  "size": "1K",
  "return_base64": true
}
```

### Image-to-Image (URL input + URL output)

```json
{
  "model": "agnes-image-2.5-flash",
  "prompt": "Transform the scene into a rain-soaked cyberpunk night with neon reflections while preserving the original composition",
  "size": "1K",
  "extra_body": {
    "image": ["https://example.com/input-image.png"],
    "response_format": "url"
  }
}
```

### Multi-Image Composition

```json
{
  "model": "agnes-image-2.5-flash",
  "prompt": "Combine the two characters into an intense fantasy battle scene, dynamic lighting, detailed background, cinematic composition",
  "size": "1K",
  "extra_body": {
    "image": [
      "https://example.com/character-1.png",
      "https://example.com/character-2.png"
    ],
    "response_format": "url"
  }
}
```

### Data URI Base64 Input (img2img)

```json
{
  "model": "agnes-image-2.5-flash",
  "prompt": "Make the object matte black while preserving the original composition",
  "size": "1K",
  "extra_body": {
    "image": ["data:image/png;base64,BASE64_HERE"],
    "response_format": "b64_json"
  }
}
```

## Response Format

### URL Output

```json
{
  "created": 1780000000,
  "data": [{
    "url": "https://storage.googleapis.com/agnes-aigc/xxx.png",
    "b64_json": null,
    "revised_prompt": null
  }]
}
```
Generated image = `data[0].url`

### Base64 Output

```json
{
  "created": 1780000000,
  "data": [{
    "url": null,
    "b64_json": "iVBORw0KGgoAAAANSUhEUgAA...",
    "revised_prompt": null
  }]
}
```
Generated image = `data[0].b64_json`

## Response Fields

| Field | Type | Description |
|---|---|---|
| `created` | integer | Request creation timestamp |
| `data` | array | List of generated image results |
| `data[].url` | string / null | Generated image URL (null when Base64) |
| `data[].b64_json` | string / null | Base64 image data (null when URL) |
| `data[].revised_prompt` | string / null | Revised prompt if available |

## Core Capabilities

| Capability | Description | Aurora Use |
|---|---|---|
| Text-to-image | Generate from natural language | Infographic illustrations, icons, characters |
| Image-to-image | Transform/edit existing image | Style transfer, background change, scene relighting |
| Multi-image composition | Combine multiple references into one | Character + product = campaign visual |
| High-density visuals | Complex scenes, rich compositions | Detailed infographic sections |
| Composition preservation | Preserve layout during editing | Keep infographic structure while re-styling |
| Flexible size (1K-4K) | 4 tiers x 8 ratios = 32 output sizes | Adapt to any infographic slot |
| URL / Base64 output | Two delivery modes | URL for R2 upload; Base64 for in-memory processing |

## Prompting Guide (for Aurora infographic illustrations)

### Text-to-Image Structure

```
[Subject] + [Scene/Environment] + [Style] + [Lighting] + [Composition] + [Quality]
```

Example (infographic illustration for "Thermodynamique" concept):
```
"A minimalist vector illustration of a steam engine converting heat to
mechanical work, flat design style, clean white background, soft studio
lighting, centered composition, no text, high detail, 2D vector aesthetic"
```

### Image-to-Image Structure

```
[Change Request] + [New Style/Scene] + [Add/Remove Elements] + [Preserve Elements]
```

### Multi-Image Composition Structure

```
[Reference Roles] + [Target Scene] + [Relationship] + [Style/Lighting/Composition]
```

### Aurora Charte Graphique (enforced in system prompt)

- Style: flat vector, clean lines, 2D (NOT 3D render, NOT photorealistic)
- Palette: 3 max colors, derived from active theme accent tokens (AD-17)
- Background: white or transparent (the AntV layout provides the bg)
- Text in image: **FORBIDDEN** (AntV renders text separately)
- Consistency: all illustrations in one infographic share the same style
- Cultural: "adapted for a [UserContext.domain] student in [region] context"

## Pricing (SNAPSHOT 2026-09-22, G-U4 rule: dated photograph)

| Billing Item | List Price | Current Price |
|---|---|---|
| 1K output image | $10 / 1,000 images ($0.010/image) | **$0 (FREE)** |
| 2K output image | $18 / 1,000 images ($0.018/image) | **$0 (FREE)** |
| 3K output image | $28 / 1,000 images ($0.028/image) | **$0 (FREE)** |
| 4K output image | $40 / 1,000 images ($0.040/image) | **$0 (FREE)** |
| Input reference images | $5 / 1,000 images | **$0 (FREE)** |

**Rule:** all tiers currently free. This is a **capacity, not a guarantee**
(ADR v1.7 S10: free tier = variable capacity). The Model Registry must
track this; auto-retirement if pricing changes.

## Error Handling

| Error | Cause | Fix |
|---|---|---|
| `response_format` at top level | Must be in `extra_body`, not root | Move to `extra_body.response_format` |
| Missing `image` for img2img | `extra_body.image` required for image-to-image | Provide `extra_body.image: [url1, url2]` |
| Input image URL inaccessible | Private/cookie-gated URL | Use public HTTPS URL or Data URI Base64 |
| Timeout | Generation takes 5-60s+ (complex prompts, 4K) | Client timeout = 60s minimum, 360s recommended |
| Unsupported exact size | `1920x1080` not a native output | Use `size: "2K"` + `ratio: "16:9"` (2624x1472) + crop downstream |
| `tags: ["img2img"]` | NOT required (and may cause issues) | Remove; img2img = just `extra_body.image` |

## Aurora Integration (AD-1, AD-3, AD-5)

```
packages/agent (server, wave 3)
  |
  | generateIllustrationTool (vercel-ai-sdk-integration.md)
  |
  +--> PRIMARY: Agnes Image 2.5 Flash
  |     POST apihub.agnes-ai.com/v1/images/generations
  |     Auth: AGNES_API_KEY (Supabase secret, AD-3: never in device)
  |     size: "1K", ratio: "4:3" (infographic default)
  |     extra_body.response_format: "url"
  |     response -> R2 upload (presigned) -> Artifact
  |
  +--> FALLBACK: fal.ai Flux Schnell
  |     POST fal.ai flux/schnell
  |     0.003 USD/MP
  |     (when Agnes unavailable / 429 / timeout)
  |
  +--> AIResponseEnvelope: { provider: "agnes", model: "agnes-image-2.5-flash",
  |     attempt: 1, reason: "primary", expectedQuality: "full" }
  |
  AIBudgetManager: max 2 image gens per infographic, 20 daily per user
```

## Agnes Image 2.1 Flash (companion model)

| Field | Value |
|---|---|
| Model ID | `agnes-image-2.1-flash` |
| Endpoint | Same (`POST /v1/images/generations`) |
| Parameters | Identical to 2.5 Flash (same request/response contract) |
| Pricing | Identical to 2.5 Flash (currently free) |
| Quality | 2.5 Flash > 2.1 Flash (2.5 "comprehensively exceeds" 2.1) |
| Aurora use | 2.1 = fallback within Agnes (if 2.5 is degraded); 2.5 = primary |

## Model Registry Entry (AD-16b, wave 0)

```json
{
  "modelId": "agnes-image-2.5-flash",
  "provider": "agnes",
  "capabilities": ["image-generation", "image-editing", "multi-image-composition"],
  "modality": "text->image",
  "context": null,
  "status": "active",
  "freeTierQuota": { snapshotDate: "2026-09-22", value: "all tiers free", source: "https://www.agnes-ai.com/en/docs/agnes-image-25-flash" },
  "pricing": { list: "$0.010-$0.040/image by tier", current: "$0 (all tiers)" },
  "timeout": 360,
  "ratios": ["1:1","3:4","4:3","16:9","9:16","2:3","3:2","21:9"],
  "sizeTiers": ["1K","2K","3K","4K"]
}
```
