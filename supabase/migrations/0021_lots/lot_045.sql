INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/react-native', 'business', 'react-native', '', 'react-native', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK (React Native)

Use this skill for React Native apps that need fully custom video session experiences using Zoom Video SDK.

## Quick Links

1. **[Lifecycle Workflow](concepts/lifecycle-workflow.md)** - init -> listeners -> join -> helpers -> leave -> cleanup
2. **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - provider + helper model
3. **[High-Level Scenarios](concepts/high-level-scenarios.md)** - common mobile product patterns
4. **[Setup Guide](examples/setup-guide.md)** - package + platform setup baseline
5. **[Session Join Pattern](examples/session-join-pattern.md)** - tokenized join flow
6. **[Event Handling Pattern](examples/event-handling-pattern.md)** - event listener to state routing
7. **[SKILL.md](SKILL.md)** - complete navigation

## Core Notes

- Video SDK sessions are not Zoom Meetings and use session tokens.
- JWT generation must stay backend-side.
- Wrapper is helper-heavy (audio/video/chat/share/recording/transcription, etc.).
- Event-driven design is required for robust UI state.

## References

- [React Native Reference Index](references/react-native-reference.md)
- [Module Map](references/module-map.md)
- [Official Sources](references/official-sources.md)
- [Deprecated and Contradictions](troubleshooting/deprecated-and-contradictions.md)

## Related Skills

- [zoom-video-sdk](../SKILL.md)
- [zoom-oauth](../../oauth/SKILL.md)
- [zoom-general](../../general/SKILL.md)

## Documentation Index

### Start Here

1. [SKILL.md](SKILL.md)
2. [Lifecycle Workflow](concepts/lifecycle-workflow.md)
3. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)
4. [Setup Guide](examples/setup-guide.md)

### Concepts

- [Lifecycle Workflow](concepts/lifecycle-workflow.md)
- [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)
- [High-Level Scenarios](concepts/high-level-scenarios.md)

### Examples

- [Setup Guide](examples/setup-guide.md)
- [Session Join Pattern](examples/session-join-pattern.md)
- [Event Handling Pattern](examples/event-handling-pattern.md)

### References

- [React Native Reference Index](references/react-native-reference.md)
- [Module Map](references/module-map.md)
- [Official Sources](references/official-sources.md)

### Troubleshooting

- [Common Issues](troubleshooting/common-issues.md)
- [Version Drift](troubleshooting/version-drift.md)
- [Deprecated and Contradictions](troubleshooting/deprecated-and-contradictions.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk', 'business', 'video-sdk', '', 'video-sdk', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-video-sdk-app

Background reference for fully custom video-session products. Prefer `plan-zoom-product` first when the boundary between Meeting SDK and Video SDK is still unclear.

Build custom video experiences powered by Zoom's infrastructure.

## Hard Routing Guardrail (Read First)

- If the user asks for custom real-time video app behavior (topic/session join, custom rendering, attach/detach), route to Video SDK.
- Do not switch to REST meeting endpoints for Video SDK join flows.
- Video SDK does not use Meeting IDs, `join_url`, or Meeting SDK join payload fields (`meetingNumber`, `passWord`).

## Meeting SDK vs Video SDK

| Feature | Meeting SDK | Video SDK |
|---------|-------------|-----------|
| UI | Default Zoom UI or Custom UI | **Fully custom UI** (you build it) |
| Experience | Zoom meetings | Video sessions |
| Branding | Limited customization | **Full branding control** |
| Features | Full Zoom features | Core video features |

## UI Options (Web)

Video SDK gives you **full control over the UI**:

| Option | Description |
|--------|-------------|
| **UI Toolkit** | Pre-built React components (low-code) |
| **Custom UI** | Build your own UI using the SDK APIs |

## Prerequisites

- Zoom Video SDK credentials from Marketplace
- SDK Key and Secret
- Web development environment

> **Need help with OAuth or signatures?** See the **[zoom-oauth](../oauth/SKILL.md)** skill for authentication flows.

> **Need pre-join diagnostics on web?** Use **[probe-sdk](../probe-sdk/SKILL.md)** before Video SDK `join()` to reduce first-minute failures.

> **Start troubleshooting fast:** Use the **[5-Minute Runbook](RUNBOOK.md)** before deep debugging.

## Quick Start (Web)

### NPM Usage (Bundler like Vite/Webpack)

```javascript
import ZoomVideo from '@zoom/videosdk';

const client = ZoomVideo.createClient();
await client.init('en-US', 'Global', { patchJsMedia: true });
await client.join(topic, signature, userName, password);

// IMPORTANT: getMediaStream() ONLY works AFTER join()
const stream = client.getMediaStream();
await stream.startVideo();
await stream.startAudio();
```

### CDN Usage (No Bundler)

> **WARNING: Ad blockers block `source.zoom.us`**. Self-host the SDK to avoid issues.

```bash
# Download SDK locally
curl "https://source.zoom.us/videosdk/zoom-video-1.12.0.min.js" -o js/zoom-video-sdk.min.js
```

```html
<script src="js/zoom-video-sdk.min.js"></script>
```

```javascript
// CDN exports as WebVideoSDK, NOT ZoomVideo
// Must use .default property
const ZoomVideo = WebVideoSDK.default;
const client = ZoomVideo.createClient();

await client.init('en-US', 'Global', { patchJsMedia: true });
await client.join(topic, signature, userName, password);

// IMPORTANT: getMediaStream() ONLY works AFTER join()
const stream = client.getMediaStream();
await stream.startVideo();
await stream.startAudio();
```

### ES Module with CDN (Race Condition Fix)

When using `<script type="module">` with CDN, SDK may not be loaded yet:

```javascript
// Wait for SDK to load before using
function waitForSDK(timeout = 10000) {
  return new Promise((resolve, reject) => {
    if (typeof WebVideoSDK !== 'undefined') {
      resolve();
      return;
    }
    const start = Date.now();
    const check = setInterval(() => {
      if (typeof WebVideoSDK !== 'undefined') {
        clearInterval(check);
        resolve();
      } else if (Date.now() - start > timeout) {
        clearInterval(check);
        reject(new Error('SDK failed to load'));
      }
    }, 100);
  });
}

// Usage
await waitForSDK();
const ZoomVideo = WebVideoSDK.default;
const client = ZoomVideo.createClient();
```

## SDK Lifecycle (CRITICAL ORDER)

The SDK has a strict lifecycle. Violating it causes silent failures.

```
1. Create client:     client = ZoomVideo.createClient()
2. Initialize:        await client.init('en-US', 'Global', options)
3. Join session:      await client.join(topic, signature, userName, password)
4. Get stream:        stream = client.getMediaStream()  ← ONLY AFTER JOIN
5. Start media:       await stream.startVideo() / await stream.startAudio()
```

**Common Mistake (Silent Failure):**

```javascript
// ❌ WRONG: Getting stream before joining
const client = ZoomVideo.createClient();
await client.init('en-US', 'Global');
const stream = client.getMediaStream();  // Returns undefined!
await client.join(...);

// ✅ CORRECT: Get stream after joining
const client = ZoomVideo.createClient();
await client.init('en-US', 'Global');
await client.join(...);
const stream = client.getMediaStream();  // Works!
```

## Video Rendering (Event-Driven)

**The SDK is event-driven.** You must listen for events and render videos accordingly.

### Use `attachVideo()` NOT `renderVideo()`

```javascript
import { VideoQuality } from '@zoom/videosdk';

// Start your camera
await stream.startVideo();

// Attach video - returns element to append to DOM
const element = await stream.attachVideo(userId, VideoQuality.Video_360P);
container.appendChild(element);

// Detach when done
await stream.detachVideo(userId);
```

### Required Events

```javascript
// When other participant's video turns on/off
client.on('peer-video-state-change', async (payload) => {
  const { action, userId } = payload;
  if (action === 'Start') {
    const el = await stream.attachVideo(userId, VideoQuality.Video_360P);
    container.appendChild(el);
  } else {
    await stream.detachVideo(userId);
  }
});

// When participants join/leave
client.on('user-added', (payload) => { /* check bVideoOn */ });
client.on('user-removed', (payload) => { stream.detachVideo(payload.userId); });
```

See [web/references/web.md](web/references/web.md) for complete event handling patterns.

## Key Concepts

| Concept | Description |
|---------|-------------|
| Session | Video session (not a meeting) |
| Topic | Session identifier (any string you choose) |
| Signature | JWT for authorization |
| MediaStream | Audio/video stream control |

## Session Creation Model

**Important**: Video SDK sessions are created **just-in-time**, not in advance.

| Aspect | Video SDK | Meeting SDK |
|--------|-----------|-------------|
| Pre-creation | NOT required | Create meeting via API first |
| Session start | First participant joins with topic | Join existing meeting ID |
| Topic | Any string (you define it) | Meeting ID from API |
| Scheduling | N/A - sessions are ad-hoc | Meetings can be scheduled |

### How Sessions Work

1. **No pre-creation needed**: Sessions don't exist until someone joins
2. **Topic = Session ID**: Any participants joining with the same `topic` string join the same session
3. **First join creates it**: The session is created when the first participant joins
4. **No meeting ID**: There's no numeric meeting ID like in Zoom Meetings

```javascript
// Session is created on-the-fly when first user joins
// Any string can be the topic - it becomes the session identifier
await client.join('my-custom-session-123', signature, 'User Name');

// Other participants join the SAME session by using the SAME topic
await client.join('my-custom-session-123', signature, 'Another User');
```

### Signature Endpoint Setup

The signature endpoint must be accessible from your frontend without CORS issues.

**Option 1: Same-Origin Proxy (Recommended)**

```nginx
# Nginx config
location /api/ {
    proxy_pass http://YOUR_BACKEND_HOST:3005/api/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
}
```

```javascript
// Frontend uses relative URL (same origin)
const response = await fetch('/api/signature', { ... });
```

**Option 2: CORS Configuration**

```javascript
// Express.js backend
const cors = require('cors');
app.use(cors({
  origin: ['https://your-domain.com'],
  credentials: true
}));
```

**WARNING:** Mixed content (HTTPS page → HTTP API) will be blocked by browsers.

## Use Cases

| Use Case | Description |
|----------|-------------|
| [Video SDK BYOS (Bring Your Own Storage)](../general/use-cases/video-sdk-bring-your-own-storage.md) | Save recordings directly to your S3 bucket |

## BYOS (Bring Your Own Storage)

Video SDK feature - Zoom saves cloud recordings **directly** to your Amazon S3 bucket. No downloading required.

> **Official docs:** https://developers.zoom.us/docs/build/storage/

**Prerequisites:**
- Video SDK account with Cloud Recording add-on (Universal Credit includes this)
- AWS S3 bucket

**Authentication options:**
1. **AWS Access Key** - simpler setup
2. **Cross Account Access** - more secure (IAM role assumption)

**S3 path structure:**
```
Buckets/{bucketName}/cmr/byos/{YYYY}/{MM}/{DD}/{GUID}/cmr_byos/
```

**Key benefits:**
- Zero download bandwidth costs
- Direct storage during recording
- Config-only setup (no webhook/download code needed)

**Setup location:** Developer Portal → Account Settings → General → Communications Content Storage Location

See **[../general/use-cases/video-sdk-bring-your-own-storage.md](../general/use-cases/video-sdk-bring-your-own-storage.md)** for complete setup guide.

## Detailed References

### UI & Components
- **[references/ui-toolkit.md](references/ui-toolkit.md)** - Pre-built UI components (Web)
- **[references/triage-intake.md](references/triage-intake.md)** - What to ask first (turn vague reports into answers)
- **[references/session-lifecycle.md](references/session-lifecycle.md)** - Correct API ordering + event-driven rendering
- **[references/licensing-and-entitlements.md](references/licensing-and-entitlements.md)** - License/admin prerequisites
- **[references/token-contract-test-spec.md](references/token-contract-test-spec.md)** - Shared backend token contract and cross-platform smoke test

### Platform Guides
- **[references/authorization.md](references/authorization.md)** - Video SDK JWT generation
- **[web/SKILL.md](web/SKILL.md)** - Web Video SDK (JavaScript/TypeScript)
  - **[web/SKILL.md](web/SKILL.md)** - Complete documentation navigation
  - **[web/examples/react-hooks.md](web/examples/react-hooks.md)** - Official React hooks library
  - **[web/examples/framework-integrations.md](web/examples/framework-integrations.md)** - Next.js, Vue/Nuxt patterns
- **[react-native/SKILL.md](react-native/SKILL.md)** - React Native Video SDK (mobile wrapper, helper/event architecture)
  - **[react-native/SKILL.md](react-native/SKILL.md)** - React Native documentation navigation
  - **[react-native/examples/session-join-pattern.md](react-native/examples/session-join-pattern.md)** - Tokenized session join flow
- **[flutter/SKILL.md](flutter/SKILL.md)** - Flutter Video SDK (mobile wrapper, event-driven architecture)
  - **[flutter/SKILL.md](flutter/SKILL.md)** - Flutter documentation navigation
  - **[flutter/examples/session-join-pattern.md](flutter/examples/session-join-pattern.md)** - Tokenized session join flow
- **[android/SKILL.md](android/SKILL.md)** - Android Video SDK (native mobile custom UI, tokenized sessions)
- **[ios/SKILL.md](ios/SKILL.md)** - iOS Video SDK (native mobile custom UI, delegate-driven lifecycle)
- **[macos/SKILL.md](macos/SKILL.md)** - macOS Video SDK (desktop native apps, custom session windows)
- **[unity/SKILL.md](unity/SKILL.md)** - Unity Video SDK wrapper (game-engine integration, scene-driven UX)
- **[linux/SKILL.md](linux/SKILL.md)** - Linux Video SDK overview (C++ headless bots)
- **[linux/linux.md](linux/linux.md)** - Linux C++ SDK (headless bots, raw media capture/injection)
- **[linux/references/linux-reference.md](linux/references/linux-reference.md)** - Linux API Reference
- **[windows/SKILL.md](windows/SKILL.md)** - Windows C++ SDK (desktop applications, raw media capture/injection)
- **[windows/references/windows-reference.md](windows/references/windows-reference.md)** - Windows API Reference
- **[references/troubleshooting.md](references/troubleshooting.md)** - Common issues and solutions
- **[references/forum-top-questions.md](references/forum-top-questions.md)** - Common forum question patterns (what to cover)

## Sample Repositories

### Official (by Zoom)

| Type | Repository | Stars |
|------|------------|-------|
| Web | [videosdk-web-sample](https://github.com/zoom/videosdk-web-sample) | 137 |
| Web NPM | [videosdk-web](https://github.com/zoom/videosdk-web) | 56 |
| Auth | [videosdk-auth-endpoint-sample](https://github.com/zoom/videosdk-auth-endpoint-sample) | 23 |
| UI Toolkit Web | [videosdk-zoom-ui-toolkit-web](https://github.com/zoom/videosdk-zoom-ui-toolkit-web) | 17 |
| UI Toolkit React | [videosdk-zoom-ui-toolkit-react-sample](https://github.com/zoom/videosdk-zoom-ui-toolkit-react-sample) | 17 |
| Next.js | [videosdk-nextjs-quickstart](https://github.com/zoom/videosdk-nextjs-quickstart) | 16 |
| Telehealth | [VideoSDK-Web-Telehealth](https://github.com/zoom/VideoSDK-Web-Telehealth) | 11 |
| Linux | [videosdk-linux-raw-recording-sample](https://github.com/zoom/videosdk-linux-raw-recording-sample) | - |

**Full list**: See [general/references/community-repos.md](../general/references/community-repos.md)

## Resources

- **Official docs**: https://developers.zoom.us/docs/video-sdk/
- **Developer forum**: https://devforum.zoom.us/

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.

## Linux Operations

- [linux/RUNBOOK.md](linux/RUNBOOK.md) - Linux platform preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/unity', 'business', 'unity', '', 'unity', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK (Unity)

Use this skill when building Unity apps that integrate Zoom Video SDK wrapper APIs.

## Start Here

1. [unity.md](unity.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/session-join-pattern.md](examples/session-join-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/unity-reference-map.md](references/unity-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Key Sources

- Docs: https://developers.zoom.us/docs/video-sdk/unity/
- API reference: https://marketplacefront.zoom.us/sdk/custom/unity/index.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/web', 'business', 'web', '', 'web', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK - Web Development

Expert guidance for developing with the Zoom Video SDK on Web. This SDK enables custom video applications in the browser with real-time video/audio, screen sharing, cloud recording, live streaming, chat, and live transcription.

This skill is for **custom video sessions**, not embedded Zoom meetings.
If the user wants a custom UI for a real Zoom meeting, route to
[../../meeting-sdk/web/component-view/SKILL.md](../../meeting-sdk/web/component-view/SKILL.md).

**Official Documentation**: https://developers.zoom.us/docs/video-sdk/web/
**API Reference**: https://marketplacefront.zoom.us/sdk/custom/web/modules.html
**Sample Repository**: https://github.com/zoom/videosdk-web-sample

## Quick Links

**New to Video SDK? Follow this path:**

1. **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - Universal 3-step pattern for ANY feature
2. **[Session Join Pattern](examples/session-join-pattern.md)** - Complete working code to join a session
3. **[Video Rendering](examples/video-rendering.md)** - Display video with attachVideo()
4. **[Event Handling](examples/event-handling.md)** - Required events for video/audio

**Reference:**
- **[Singleton Hierarchy](concepts/singleton-hierarchy.md)** - 4-level SDK navigation map
- **[API Reference](references/web-reference.md)** - Methods, events, error codes
- **[SKILL.md](SKILL.md)** - Complete documentation navigation
- **[../../probe-sdk/SKILL.md](../../probe-sdk/SKILL.md)** - Optional browser/device/network readiness diagnostics before join

**Having issues?**
- Video not showing → [Video Rendering](examples/video-rendering.md) (use attachVideo, not renderVideo)
- getMediaStream() returns undefined → Call AFTER join() completes
- Quick diagnostics → [Common Issues](troubleshooting/common-issues.md)

## SDK Overview

The Zoom Video SDK for Web is a JavaScript library that provides:
- **Session Management**: Join/leave video SDK sessions
- **Video/Audio**: Start/stop camera and microphone
- **Screen Sharing**: Share screens or browser tabs
- **Cloud Recording**: Record sessions to Zoom cloud
- **Live Streaming**: Stream to RTMP endpoints
- **Chat**: In-session messaging
- **Command Channel**: Custom command messaging
- **Live Transcription**: Real-time speech-to-text
- **Subsessions**: Breakout room support
- **Whiteboard**: Collaborative whiteboard features
- **Virtual Background**: Blur or custom image backgrounds

## Prerequisites

### System Requirements

- **Modern Browser**: Chrome 80+, Firefox 75+, Safari 14+, Edge 80+
- **Video SDK Credentials**: SDK Key and Secret from [Marketplace](https://marketplace.zoom.us/)
- **JWT Token**: Server-side generated signature

### Browser Feature Requirements

```javascript
// Check browser compatibility before init
const compatibility = ZoomVideo.checkSystemRequirements();
console.log('Audio:', compatibility.audio);
console.log('Video:', compatibility.video);
console.log('Screen:', compatibility.screen);

// Check feature support
const features = ZoomVideo.checkFeatureRequirements();
console.log('Supported:', features.supportFeatures);
console.log('Unsupported:', features.unSupportFeatures);
```

### Optional Pre-Join Diagnostics (Recommended for Reliability)

Use Probe SDK as a readiness gate before `client.join(...)` when you need to reduce failed starts:

1. Run diagnostics with [../../probe-sdk/SKILL.md](../../probe-sdk/SKILL.md).
2. Evaluate policy (`allow`, `warn`, `block`).
3. Start Video SDK join only when policy allows.

Cross-skill flow: [../../general/use-cases/probe-sdk-preflight-readiness-gate.md](../../general/use-cases/probe-sdk-preflight-readiness-gate.md)

## Installation

### NPM (Recommended)

```bash
npm install @zoom/videosdk
```

```javascript
import ZoomVideo from '@zoom/videosdk';
```

### CDN (Fallback Strategy Recommended)

> **Note**: Some networks/ad blockers can block `source.zoom.us`. If you see flaky loads, first try allowlisting the domain in your environment. If needed, consider a fallback (mirror/self-host) only if it's permitted for your use case and you can keep versions in sync.

```bash
# Download SDK locally
curl "https://source.zoom.us/videosdk/zoom-video-2.3.12.min.js" -o public/js/zoom-video-sdk.min.js
```

```html
<!-- Use local copy instead of CDN -->
<script src="js/zoom-video-sdk.min.js"></script>
```

```javascript
// CDN exports as WebVideoSDK, NOT ZoomVideo
const ZoomVideo = WebVideoSDK.default;
```

## Quick Start

```javascript
import ZoomVideo from '@zoom/videosdk';

// 1. Create client (singleton - returns same instance)
const client = ZoomVideo.createClient();

// 2. Initialize SDK
await client.init('en-US', 'Global', { patchJsMedia: true });

// 3. Join session
await client.join(topic, signature, userName, password);

// 4. CRITICAL: Get stream AFTER join
const stream = client.getMediaStream();

// 5. Start media
await stream.startVideo();
await stream.startAudio();

// 6. Attach video to DOM
const videoElement = await stream.attachVideo(userId, VideoQuality.Video_360P);
document.getElementById('video-container').appendChild(videoElement);
```

## SDK Lifecycle (CRITICAL ORDER)

The SDK has a strict lifecycle. Violating it causes **silent failures**.

```
1. Create client:     client = ZoomVideo.createClient()
2. Initialize:        await client.init('en-US', 'Global', options)
3. Join session:      await client.join(topic, signature, userName, password)
4. Get stream:        stream = client.getMediaStream()  ← ONLY AFTER JOIN
5. Start media:       await stream.startVideo() / await stream.startAudio()
```

**Common Mistake:**

```javascript
// WRONG: Getting stream before joining
const stream = client.getMediaStream();  // Returns undefined!
await client.join(...);

// CORRECT: Get stream after joining
await client.join(...);
const stream = client.getMediaStream();  // Works!
```

## Critical Gotchas and Best Practices

### getMediaStream() ONLY Works After join()

The #1 issue that causes video/audio to fail:

```javascript
// WRONG
const stream = client.getMediaStream();  // undefined!
await client.join(...);

// CORRECT
await client.join(...);
const stream = client.getMediaStream();  // Works
```

### Use attachVideo() NOT renderVideo()

`renderVideo()` is **deprecated**. Use `attachVideo()` which returns a VideoPlayer element:

```javascript
import { VideoQuality } from '@zoom/videosdk';

// CORRECT: attachVideo returns element to append
const videoElement = await stream.attachVideo(userId, VideoQuality.Video_360P);
document.getElementById('video-container').appendChild(videoElement);

// WRONG: renderVideo is deprecated
await stream.renderVideo(canvas, userId, ...);  // Don't use!
```

### Video Rendering is Event-Driven (CRITICAL)

You MUST listen for events to properly render participant videos:

```javascript
// When another participant's video state changes
client.on('peer-video-state-change', async (payload) => {
  const { action, userId } = payload;
  
  if (action === 'Start') {
    // Participant turned on video - attach it
    const element = await stream.attachVideo(userId, VideoQuality.Video_360P);
    container.appendChild(element);
  } else if (action === 'Stop') {
    // Participant turned off video - detach it
    await stream.detachVideo(userId);
  }
});

// When participants join/leave
client.on('user-added', (payload) => {
  // New participant joined - check if their video is on
  const users = client.getAllUser();
  // Render videos for users with bVideoOn === true
});

client.on('user-removed', (payload) => {
  // Participant left - clean up their video element
  stream.detachVideo(payload[0].userId);
});
```

### Peer Video on Mid-Session Join

**Existing participants' videos won't auto-render when you join mid-session.**

```javascript
// After joining, render existing participants' videos
const renderExistingVideos = async () => {
  await new Promise(resolve => setTimeout(resolve, 500));
  
  const users = client.getAllUser();
  const currentUserId = client.getCurrentUserInfo().userId;
  
  for (const user of users) {
    if (user.bVideoOn && user.userId !== currentUserId) {
      const element = await stream.attachVideo(user.userId, VideoQuality.Video_360P);
      document.getElementById(`video-${user.userId}`).appendChild(element);
    }
  }
};
```

### CDN Race Condition with ES Modules

When using `<script type="module">` with CDN, the SDK may not be loaded yet:

```javascript
function waitForSDK(timeout = 10000) {
  return new Promise((resolve, reject) => {
    if (typeof WebVideoSDK !== 'undefined') {
      resolve();
      return;
    }
    const start = Date.now();
    const check = setInterval(() => {
      if (typeof WebVideoSDK !== 'undefined') {
        clearInterval(check);
        resolve();
      } else if (Date.now() - start > timeout) {
        clearInterval(check);
        reject(new Error('SDK failed to load'));
      }
    }, 100);
  });
}

await waitForSDK();
const ZoomVideo = WebVideoSDK.default;
```

### SharedArrayBuffer for HD Video

For optimal performance and HD video, configure these headers on your server:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

**Note:** As of v1.11.2, SharedArrayBuffer is elective (not strictly required).

### Check HD Capability Before Enabling

```javascript
const stream = client.getMediaStream();

// Check if 720p is supported
const hdSupported = stream.isSupportHDVideo();

// Get maximum video quality
const maxQuality = stream.getVideoMaxQuality();
// 0=90P, 1=180P, 2=360P, 3=720P, 4=1080P

// Start video with HD
if (hdSupported) {
  await stream.startVideo({ hd: true });
}
```

### Screen Share Rendering Mode Check

```javascript
const stream = client.getMediaStream();

// Check which element type to use
if (stream.isStartShareScreenWithVideoElement()) {
  // Use video element
  const video = document.getElementById('share-video');
  await stream.startShareScreen(video as unknown as HTMLCanvasElement);
} else {
  // Use canvas element
  const canvas = document.getElementById('share-canvas');
  await stream.startShareScreen(canvas);
}
```

## Key Features

### Video Quality Enum

```javascript
import { VideoQuality } from '@zoom/videosdk';

VideoQuality.Video_90P   // 0
VideoQuality.Video_180P  // 1
VideoQuality.Video_360P  // 2 (recommended for most cases)
VideoQuality.Video_720P  // 3
VideoQuality.Video_1080P // 4
```

### Virtual Backgrounds

```javascript
const stream = client.getMediaStream();

// Always check support first
if (stream.isSupportVirtualBackground()) {
  // Blur background
  await stream.updateVirtualBackgroundImage('blur');
  
  // Custom image background
  await stream.updateVirtualBackgroundImage('https://example.com/bg.jpg');
  
  // Remove virtual background
  await stream.updateVirtualBackgroundImage(undefined);
}
```

### Video Processor (Custom Effects)

The `VideoProcessor` class allows you to intercept and modify video frames:

```javascript
// video-processor-worker.js
class MyVideoProcessor extends VideoProcessor {
  processFrame(input, output) {
    const ctx = output.getContext('2d');
    ctx.drawImage(input, 0, 0);
    
    // Add overlay
    ctx.fillStyle = 'white';
    ctx.font = '24px Arial';
    ctx.fillText('Live', 20, 40);
    
    return true;
  }
}
```

### WebRTC Mode

Enable WebRTC mode for direct peer-to-peer streaming with HD video support:

```javascript
await client.init('en-US', 'Global', {
  patchJsMedia: true,
  webrtc: true  // Enable WebRTC mode
});
```

## Feature Clients

Access specialized clients from the VideoClient:

| Client | Access Method | Purpose |
|--------|---------------|---------|
| **Stream** | `client.getMediaStream()` | Video, audio, screen share, devices |
| **Chat** | `client.getChatClient()` | Send/receive messages |
| **Command** | `client.getCommandClient()` | Custom commands (reactions, etc.) |
| **Recording** | `client.getRecordingClient()` | Cloud recording control |
| **Transcription** | `client.getLiveTranscriptionClient()` | Live captions |
| **LiveStream** | `client.getLiveStreamClient()` | RTMP streaming |
| **Subsession** | `client.getSubsessionClient()` | Breakout rooms |
| **Whiteboard** | `client.getWhiteboardClient()` | Collaborative whiteboard |

## Common Tasks

### Start/Stop Video

```javascript
await stream.startVideo();
await stream.stopVideo();
```

### Start/Stop Audio

```javascript
await stream.startAudio();
await stream.muteAudio();
await stream.unmuteAudio();
await stream.stopAudio();
```

### Switch Devices

```javascript
// Get available devices
const cameras = stream.getCameraList();
const mics = stream.getMicList();
const speakers = stream.getSpeakerList();

// Switch devices
await stream.switchCamera(cameraId);
await stream.switchMicrophone(micId);
await stream.switchSpeaker(speakerId);
```

### Screen Sharing

```javascript
// Start sharing
await stream.startShareScreen(canvas);

// Stop sharing
await stream.stopShareScreen();

// Receive share
client.on('active-share-change', async (payload) => {
  if (payload.state === 'Active') {
    await stream.startShareView(canvas, payload.userId);
  } else {
    await stream.stopShareView();
  }
});
```

### Chat

```javascript
const chatClient = client.getChatClient();

// Send to everyone
await chatClient.send('Hello, everyone!');

// Send to specific user
await chatClient.sendToUser(userId, 'Private message');

// Receive messages
client.on('chat-on-message', (payload) => {
  console.log(`${payload.sender.name}: ${payload.message}`);
});
```

### Recording (Host Only)

```javascript
const recordingClient = client.getRecordingClient();

await recordingClient.startCloudRecording();
await recordingClient.stopCloudRecording();

client.on('recording-change', (payload) => {
  console.log('Recording status:', payload.state);
});
```

### Leave/End Session

```javascript
// Leave session (others stay)
await client.leave();

// End session for ALL participants (host only)
await client.leave(true);
```

## Error Handling

### Common Join Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid signature` | JWT expired or malformed | Generate new signature |
| `Session does not exist` | Host hasn't started yet | Show "waiting" message, retry |
| `Permission denied` | User denied camera/mic | Request permission again |

### Example Error Handler

```javascript
try {
  await client.join(topic, signature, userName, password);
} catch (error) {
  if (error.reason?.includes('signature')) {
    // Regenerate signature and retry
  } else if (error.reason?.includes('Session')) {
    // Show "Waiting for host..." and poll
  } else if (error.reason?.includes('Permission')) {
    // Guide user to enable permissions
  }
  console.error('Join failed:', error);
}
```

## Browser Compatibility

| Feature | Chrome | Firefox | Safari | Edge |
|---------|--------|---------|--------|------|
| Video | 80+ | 75+ | 14+ | 80+ |
| Audio | 80+ | 75+ | 14+ | 80+ |
| Screen Share | 80+ | 75+ | 15+ | 80+ |
| Virtual BG | 80+ | 90+ | - | 80+ |

**Safari Notes:**
- Virtual background not supported
- Screen sharing requires macOS 15+

## CORS Errors (Telemetry)

**CORS errors to `log-external-gateway.zoom.us` are harmless.**

These are caused by COOP/COEP headers blocking telemetry requests. They don't affect SDK functionality.

## Complete Documentation Library

### Core Concepts
- **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - Universal 3-step pattern for ANY feature
- **[Singleton Hierarchy](concepts/singleton-hierarchy.md)** - 4-level navigation guide

### Complete Examples
- **[Session Join Pattern](examples/session-join-pattern.md)** - JWT auth + session join with full code
- **[Video Rendering](examples/video-rendering.md)** - attachVideo() patterns
- **[Screen Share](examples/screen-share.md)** - Send and receive screen shares
- **[Event Handling](examples/event-handling.md)** - Required events
- **[Chat](examples/chat.md)** - In-session messaging
- **[Recording](examples/recording.md)** - Cloud recording control
- **[Transcription](examples/transcription.md)** - Live captions

### Framework Integrations
- **[React Hooks](examples/react-hooks.md)** - Official @zoom/videosdk-react library
- **[Framework Integrations](examples/framework-integrations.md)** - Next.js, Vue/Nuxt patterns

### Troubleshooting
- **[Common Issues](troubleshooting/common-issues.md)** - Quick diagnostics & error codes

### References
- **[API Reference](references/web-reference.md)** - Complete method signatures
- **[Events Reference](references/events-reference.md)** - All event types
- **[SKILL.md](SKILL.md)** - Complete navigation guide

## Official Sample Repositories

| Type | Repository |
|------|------------|
| Web Sample | [videosdk-web-sample](https://github.com/zoom/videosdk-web-sample) |
| React SDK | [videosdk-react](https://github.com/zoom/videosdk-react) |
| Next.js | [videosdk-nextjs-quickstart](https://github.com/zoom/videosdk-nextjs-quickstart) |
| Vue/Nuxt | [videosdk-vue-nuxt-quickstart](https://github.com/zoom/videosdk-vue-nuxt-quickstart) |
| Auth Endpoint | [videosdk-auth-endpoint-sample](https://github.com/zoom/videosdk-auth-endpoint-sample) |
| UI Toolkit | [videosdk-zoom-ui-toolkit-react-sample](https://github.com/zoom/videosdk-zoom-ui-toolkit-react-sample) |

## Resources

- **Official Docs**: https://developers.zoom.us/docs/video-sdk/web/
- **API Reference**: https://marketplacefront.zoom.us/sdk/custom/web/modules.html
- **Dev Forum**: https://devforum.zoom.us/
- **GitHub Samples**: https://github.com/zoom/videosdk-web-sample

---

**Need help?** Start with [SKILL.md](SKILL.md) for complete navigation.


## Merged from video-sdk/web/SKILL.md

# Zoom Video SDK Web - Complete Documentation Index

## Quick Start Path

**If you're new to the SDK, follow this order:**

1. **Read the architecture pattern** → [concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)
   - Universal formula: Create Client → Init → Join → Get Stream → Use
   - Once you understand this, you can implement any feature

2. **Implement session join** → [examples/session-join-pattern.md](examples/session-join-pattern.md)
   - Complete working JWT + session join code

3. **Listen to events** → [examples/event-handling.md](examples/event-handling.md)
   - **CRITICAL**: The SDK is event-driven, you must listen for events

4. **Implement video** → [examples/video-rendering.md](examples/video-rendering.md)
   - Use attachVideo(), NOT renderVideo()

5. **Troubleshoot any issues** → [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
   - Quick diagnostic checklist
   - Error code tables

---

## Documentation Structure

```
video-sdk/web/
├── SKILL.md                           # Main skill overview
├── SKILL.md                           # This file - navigation guide
│
├── concepts/                          # Core architectural patterns
│   ├── sdk-architecture-pattern.md   # Universal formula for ANY feature
│   └── singleton-hierarchy.md        # 4-level navigation guide
│
├── examples/                          # Complete working code
│   ├── session-join-pattern.md       # JWT auth + session join
│   ├── video-rendering.md            # attachVideo() patterns
│   ├── screen-share.md               # Send and receive screen shares
│   ├── event-handling.md             # Required events
│   ├── chat.md                       # Chat implementation
│   ├── command-channel.md            # Command channel messaging
│   ├── recording.md                  # Cloud recording control
│   ├── transcription.md              # Live transcription/captions
│   ├── react-hooks.md                # Official @zoom/videosdk-react library
│   └── framework-integrations.md     # Next.js, Vue/Nuxt, ZFG patterns
│
├── troubleshooting/                   # Problem solving guides
│   └── common-issues.md              # Quick diagnostic workflow
│
└── references/                        # Reference documentation
    ├── web-reference.md              # API hierarchy, methods, error codes
    └── events-reference.md           # All event types
```

---

## By Use Case

### I want to build a video app
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Understand the pattern
2. [Session Join Pattern](examples/session-join-pattern.md) - Join sessions
3. [Video Rendering](examples/video-rendering.md) - Display video
4. [Event Handling](examples/event-handling.md) - Listen for video events

### I'm getting runtime errors
1. [Common Issues](troubleshooting/common-issues.md) - Error code tables
2. "getMediaStream() is undefined" → Call AFTER join() completes

### I want to receive screen shares
1. [Screen Share](examples/screen-share.md) - startShareView() patterns
2. [Event Handling](examples/event-handling.md) - active-share-change event

### I want to send screen shares
1. [Screen Share](examples/screen-share.md) - startShareScreen() patterns
2. Check isStartShareScreenWithVideoElement() for element type

### I want to use chat
1. [Chat](examples/chat.md) - Send/receive messages
2. getChatClient() for ChatClient access

### I want to record sessions
1. [Recording](examples/recording.md) - Cloud recording (host only)
2. getRecordingClient() for RecordingClient access

### I want to use live transcription
1. [Transcription](examples/transcription.md) - Enable live captions
2. getLiveTranscriptionClient() for LiveTranscriptionClient access

### I want to use command channel
1. [Command Channel](examples/command-channel.md) - Custom signaling between participants
2. Must call getCommandClient() AFTER join()

### I want to implement a specific feature
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - **START HERE!**
2. [Singleton Hierarchy](concepts/singleton-hierarchy.md) - Navigate to the feature
3. [API Reference](references/web-reference.md) - Method signatures

### I'm using React
1. [React Hooks](examples/react-hooks.md) - Official @zoom/videosdk-react library
2. Provides hooks: useSession, useSessionUsers, useVideoState, useAudioState
3. Pre-built components: VideoPlayerComponent, ScreenSharePlayerComponent

### I'm using Next.js or Vue/Nuxt
1. [Framework Integrations](examples/framework-integrations.md) - SSR considerations
2. Server-side JWT generation patterns
3. Client-side only SDK usage

---

## Most Critical Documents

### 1. SDK Architecture Pattern (MASTER DOCUMENT)
**[concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)**

The universal 5-step pattern:
1. Create client
2. Initialize SDK
3. Join session
4. Get stream
5. Use features + listen to events

### 2. Common Issues (MOST COMMON PROBLEMS)
**[troubleshooting/common-issues.md](troubleshooting/common-issues.md)**

Common issues:
- getMediaStream() returns undefined
- Video not displaying
- renderVideo() deprecated

### 3. Singleton Hierarchy (NAVIGATION MAP)
**[concepts/singleton-hierarchy.md](concepts/singleton-hierarchy.md)**

4-level deep navigation showing how to reach every feature.

---

## Key Learnings

### Critical Discoveries:

1. **getMediaStream() ONLY works after join()**
   - The stream object is not available until session is joined
   - See: [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

2. **Use attachVideo() NOT renderVideo()**
   - renderVideo() is deprecated
   - attachVideo() returns a VideoPlayer element to append to DOM
   - See: [Video Rendering](examples/video-rendering.md)

3. **The SDK is Event-Driven**
   - You MUST listen for events to render participant videos
   - key events: peer-video-state-change, user-added, user-removed
   - See: [Event Handling](examples/event-handling.md)

4. **Peer Videos on Mid-Session Join**
   - Existing participants' videos won't auto-render
   - Must manually iterate getAllUser() and attachVideo()
   - See: [Video Rendering](examples/video-rendering.md)

5. **CDN vs NPM**
   - CDN exports as `WebVideoSDK.default`, not `ZoomVideo`
   - Some networks/ad blockers may block `source.zoom.us` - allowlist or use a permitted fallback strategy
   - See: [Session Join Pattern](examples/session-join-pattern.md)

6. **SharedArrayBuffer for HD**
   - Required for 720p/1080p video
   - Need COOP/COEP headers on server
   - Check with `stream.isSupportHDVideo()`

7. **Screen Share Element Type**
   - Check `isStartShareScreenWithVideoElement()` for correct element type
   - See: [Screen Share](examples/screen-share.md)

8. **Command Channel Setup Order**
   - Must call getCommandClient() AFTER client.join()
   - Register listeners AFTER join, not before
   - Web uses getCommandClient() not getCmdChannel()
   - See: [Command Channel](examples/command-channel.md)

9. **Command Channel is Session-Scoped**
   - Does NOT span across different sessions
   - Both sender and receiver must be in the same session

---

## Quick Reference

### "getMediaStream() returns undefined"
→ Call AFTER join() completes

### "Video not showing"
→ [Video Rendering](examples/video-rendering.md) - Use attachVideo(), check events

### "renderVideo() doesn't work"
→ [Video Rendering](examples/video-rendering.md) - Use attachVideo() instead

### "How do I implement [feature]?"
→ [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

### "How do I navigate to [client]?"
→ [Singleton Hierarchy](concepts/singleton-hierarchy.md)

### "What error code means what?"
→ [Common Issues](troubleshooting/common-issues.md)

---

## Document Version

Based on **Zoom Video SDK for Web v2.3.x**

---

**Happy coding!**

Remember: The [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) is your key to unlocking the entire SDK. Read it first!

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/windows', 'business', 'windows', '', 'windows', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK - Windows Development

Expert guidance for developing with the Zoom Video SDK on Windows. This SDK enables custom video applications, raw media capture/injection, cloud recording, live streaming, and real-time transcription on Windows platforms.

**Official Documentation**: https://developers.zoom.us/docs/video-sdk/windows/
**API Reference**: https://marketplacefront.zoom.us/sdk/custom/windows/
**Sample Repository**: https://github.com/zoom/videosdk-windows-rawdata-sample

## Quick Links

**New to Video SDK? Follow this path:**

1. **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - Universal 3-step pattern for ANY feature
2. **[Session Join Pattern](examples/session-join-pattern.md)** - Complete working code to join a session
3. **[Windows Message Loop](troubleshooting/windows-message-loop.md)** - **CRITICAL**: Fix callbacks not firing
4. **[Video Rendering](examples/video-rendering.md)** - Display video with Canvas API

**Reference:**
- **[Singleton Hierarchy](concepts/singleton-hierarchy.md)** - 5-level SDK navigation map
- **[API Reference](references/windows-reference.md)** - Methods, error codes, timing rules
- **[Delegate Methods](references/delegate-methods.md)** - All 80+ callback methods
- **[Sample Applications](references/samples.md)** - Official samples guide
- **[windows.md](windows.md)** - Secondary overview doc (pointer-style)
- **[SKILL.md](SKILL.md)** - Complete documentation navigation

**Having issues?**
- Callbacks not firing → [Windows Message Loop](troubleshooting/windows-message-loop.md)
- Build errors → [Build Errors Guide](troubleshooting/build-errors.md)
- Video subscribe fails → [Video Rendering](examples/video-rendering.md) (subscribe in `onUserVideoStatusChanged`)
- Quick diagnostics → [Common Issues](troubleshooting/common-issues.md)

**Building a Custom UI?**
- [Canvas vs Raw Data](concepts/canvas-vs-raw-data.md) - Choose your rendering approach
- [Raw Video Capture](examples/raw-video-capture.md) - YUV420 frame processing

## SDK Overview

The Zoom Video SDK for Windows is a C++ library that provides:
- **Session Management**: Join/leave video SDK sessions
- **Raw Data Access**: Capture raw audio/video frames (YUV420, PCM)
- **Raw Data Injection**: Send custom audio/video into sessions
- **Screen Sharing**: Share screens or inject custom share sources
- **Cloud Recording**: Record sessions to Zoom cloud
- **Live Streaming**: Stream to RTMP endpoints (YouTube, etc.)
- **Chat & Commands**: In-session messaging and command channels
- **Live Transcription**: Real-time speech-to-text
- **Subsessions**: Breakout room support
- **Whiteboard**: Collaborative whiteboard features
- **Annotations**: Screen share annotations
- **C# Integration**: C++/CLI wrapper for .NET applications

## Prerequisites

### System Requirements

- **OS**: Windows 10 (1903 or later) or Windows 11
- **Architecture**: x64 (recommended), x86, or ARM64
- **Visual Studio**: 2019 or 2022 (Community, Professional, or Enterprise)
- **Windows SDK**: 10.0.19041.0 or later
- **.NET Framework**: 4.8 or later (for C# applications)

### Visual Studio Workloads

Install these workloads via Visual Studio Installer:

1. **Desktop development with C++**
   - MSVC v142 or v143 compiler
   - Windows 10/11 SDK
   - C++ CMake tools (optional)

2. **.NET desktop development** (for C# applications)
   - .NET Framework 4.8 targeting pack
   - C++/CLI support

## Quick Start

### C++ Application

```cpp
#include <windows.h>
#include "zoom_video_sdk_api.h"
#include "zoom_video_sdk_interface.h"
#include "zoom_video_sdk_delegate_interface.h"

USING_ZOOM_VIDEO_SDK_NAMESPACE

// 1. Create SDK object
IZoomVideoSDK* video_sdk_obj = CreateZoomVideoSDKObj();

// 2. Initialize
ZoomVideoSDKInitParams init_params;
init_params.domain = L"https://zoom.us";
init_params.enableLog = true;
init_params.logFilePrefix = L"zoom_win_video";
init_params.videoRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.shareRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.audioRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;

ZoomVideoSDKErrors err = video_sdk_obj->initialize(init_params);

// 3. Add event listener
video_sdk_obj->addListener(myDelegate);

// 4. Join session (IMPORTANT: set audioOption.connect = false)
ZoomVideoSDKSessionContext session_context;
session_context.sessionName = L"my-session";
session_context.userName = L"Windows User";
session_context.token = L"your-jwt-token";
session_context.videoOption.localVideoOn = false;
session_context.audioOption.connect = false;  // Connect audio after join
session_context.audioOption.mute = true;

IZoomVideoSDKSession* session = video_sdk_obj->joinSession(session_context);

// 5. CRITICAL: Add Windows message pump for callbacks to work
bool running = true;
while (running) {
    // Process Windows messages (required for SDK callbacks)
    MSG msg;
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    
    // Your application logic here
    Sleep(10);
}
```

### C# Application

```csharp
using ZoomVideoSDK;

var sdkManager = new ZoomSDKManager();
sdkManager.Initialize();
sdkManager.JoinSession("my-session", "jwt-token", "User Name", "");
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Session Management** | Join, leave, and manage video sessions |
| **Raw Video (YUV I420)** | Capture and inject raw video frames |
| **Raw Audio (PCM)** | Capture and inject raw audio data |
| **Screen Sharing** | Share screens or custom content |
| **Cloud Recording** | Record sessions to Zoom cloud |
| **Live Streaming** | Stream to RTMP endpoints |
| **Chat** | Send/receive chat messages |
| **Command Channel** | Custom command messaging |
| **Live Transcription** | Real-time speech-to-text |
| **C# Support** | Full .NET Framework integration |

## Sample Applications

**Official Repository**: https://github.com/zoom/videosdk-windows-rawdata-sample

| Sample | Description |
|--------|-------------|
| VSDK_SkeletonDemo | Minimal session join - **start here** |
| VSDK_getRawVideo | Capture YUV420 video frames |
| VSDK_getRawAudio | Capture PCM audio |
| VSDK_sendRawVideo | Inject custom video (virtual camera) |
| VSDK_sendRawAudio | Inject custom audio (virtual mic) |
| VSDK_CloudRecording | Cloud recording control |
| VSDK_CommandChannel | Custom command messaging |
| VSDK_TranscriptionAndTranslation | Live captions |

**See complete guide**: [Sample Applications Reference](references/samples.md)

## Critical Gotchas and Best Practices

### ⚠️ CRITICAL: Windows Message Pump Required

**The #1 issue that causes session joins to hang with no callbacks:**

All Windows applications using the Zoom SDK **MUST** process Windows messages. The SDK uses Windows messages to deliver callbacks like `onSessionJoin()`, `onError()`, etc.

**Problem**: Without a message pump, `joinSession()` appears to succeed but callbacks never fire.

**Solution**: Add this to your main loop:

```cpp
while (running) {
    // REQUIRED: Process Windows messages
    MSG msg;
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    
    // Your application logic
    Sleep(10);
}
```

**Applies to**:
- Console applications (no automatic message pump)
- Custom main loops
- Applications that don't use standard WinMain/WndProc

**GUI applications** using WinMain with standard message loop already have this.

### Audio Connection Strategy

**Best Practice**: Set `audioOption.connect = false` when joining, then connect audio in the `onSessionJoin()` callback.

```cpp
// During join
session_context.audioOption.connect = false;  // Don't connect yet
session_context.audioOption.mute = true;

// In onSessionJoin() callback
void onSessionJoin() override {
    IZoomVideoSDKAudioHelper* audioHelper = video_sdk_obj->getAudioHelper();
    if (audioHelper) {
        audioHelper->startAudio();  // Connect now
    }
}
```

**Why**: This pattern is used in all official Zoom samples. It separates session join from audio initialization for better reliability and error handling.

### All Delegate Callbacks Must Be Implemented

The `IZoomVideoSDKDelegate` interface has 70+ pure virtual methods. **ALL must be implemented**, even if empty:

```cpp
// Required even if you don't use them
void onProxyDetectComplete() override {}
void onUserWhiteboardShareStatusChanged(IZoomVideoSDKUser*, IZoomVideoSDKWhiteboardHelper*) override {}
// ... etc
```

**Tip**: Check the SDK version's `zoom_video_sdk_delegate_interface.h` for the complete list. The interface changes between SDK versions.

### Memory Mode for Raw Data

Always use heap mode for raw data memory:

```cpp
init_params.videoRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.shareRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.audioRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
```

Stack mode can cause issues with large video frames.

### Thread Safety

SDK callbacks execute on SDK threads, not your main thread:
- Don't perform heavy operations in callbacks
- Don't call `cleanup()` from within callbacks
- Use thread-safe queues for passing data to UI thread
- Use mutexes when accessing shared state

### Consult Official Samples First

When SDK behavior is unexpected, **always check the official samples** before troubleshooting:

**Local samples**:
- `C:\tempsdk\Zoom_VideoSDK_Windows_RawDataDemos\VSDK_SkeletonDemo\` (simplest)
- `C:\tempsdk\sdksamples\zoom-video-sdk-windows-2.4.12\Sample-Libs\x64\demo\`

Official samples show correct patterns for:
- Message pump implementation ✓
- Audio connection strategy ✓
- Error handling ✓
- Memory management ✓

## Video Rendering - Two Approaches

The Zoom SDK provides **two different ways** to render video. Choose based on your needs.

### 🎯 Canvas API (Recommended for Most Use Cases)

**Best for**: Standard applications, clean video quality, ease of implementation

The SDK renders video directly to your HWND. **No YUV conversion needed**.

```cpp
// Subscribe to a user's video with Canvas API
IZoomVideoSDKCanvas* canvas = user->GetVideoCanvas();
if (canvas) {
    ZoomVideoSDKErrors ret = canvas->subscribeWithView(
        hwnd,                                    // Your window handle
        ZoomVideoSDKVideoAspect_PanAndScan,     // Fit to window, may crop
        ZoomVideoSDKResolution_Auto              // Let SDK choose best resolution
    );
    
    if (ret == ZoomVideoSDKErrors_Success) {
        // SDK is now rendering directly to your window!
    }
}

// Unsubscribe when done
canvas->unSubscribeWithView(hwnd);
```

**Advantages**:
- ✅ **Best quality** - SDK uses optimized, hardware-accelerated rendering
- ✅ **No artifacts** - Professional video quality
- ✅ **Simple code** - 3 lines to subscribe
- ✅ **Better performance** - No CPU-intensive YUV conversion
- ✅ **Automatic scaling** - SDK handles window resizing
- ✅ **Aspect ratio** - Built-in aspect ratio handling

**Example from official .NET sample**:
```cpp
// Self video preview
IZoomVideoSDKCanvas* canvas = myself->GetVideoCanvas();
canvas->subscribeWithView(selfVideoHwnd, aspect, resolution);

// Remote user video
IZoomVideoSDKCanvas* remoteCanvas = remoteUser->GetVideoCanvas();
remoteCanvas->subscribeWithView(remoteVideoHwnd, aspect, resolution);
```

**Video Aspect Options**:
- `ZoomVideoSDKVideoAspect_Original` - Letterbox/pillarbox, no cropping
- `ZoomVideoSDKVideoAspect_FullFilled` - Fill window, may crop edges
- `ZoomVideoSDKVideoAspect_PanAndScan` - Smart crop to fill window
- `ZoomVideoSDKVideoAspect_LetterBox` - Show full video with black bars

**Resolution Options**:
- `ZoomVideoSDKResolution_90P`
- `ZoomVideoSDKResolution_180P`
- `ZoomVideoSDKResolution_360P` - Good balance
- `ZoomVideoSDKResolution_720P` - HD quality
- `ZoomVideoSDKResolution_1080P`
- `ZoomVideoSDKResolution_Auto` - Let SDK decide (recommended)

### 🔧 Raw Data Pipe (Advanced Use Cases)

**Best for**: Custom video processing, effects, recording, computer vision

You receive raw YUV420 frames and handle rendering yourself.

```cpp
// 1. Create a delegate to receive frames
class VideoRenderer : public IZoomVideoSDKRawDataPipeDelegate {
public:
    void onRawDataFrameReceived(YUVRawDataI420* data) override {
        int width = data->GetStreamWidth();
        int height = data->GetStreamHeight();
        
        char* yBuffer = data->GetYBuffer();
        char* uBuffer = data->GetUBuffer();
        char* vBuffer = data->GetVBuffer();
        
        // Convert YUV420 to RGB and render
        ConvertYUVToRGB(yBuffer, uBuffer, vBuffer, width, height);
        RenderToWindow(rgbBuffer, width, height);
    }
    
    void onRawDataStatusChanged(RawDataStatus status) override {
        // Handle video on/off
    }
};

// 2. Subscribe to raw data
IZoomVideoSDKRawDataPipe* pipe = user->GetVideoPipe();
VideoRenderer* renderer = new VideoRenderer();
pipe->subscribe(ZoomVideoSDKResolution_720P, renderer);
```

**YUV420 to RGB Conversion** (ITU-R BT.601):
```cpp
void ConvertYUV420ToRGB(char* yBuffer, char* uBuffer, char* vBuffer, 
                        int width, int height) {
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int yIndex = y * width + x;
            int uvIndex = (y / 2) * (width / 2) + (x / 2);
            
            int Y = (unsigned char)yBuffer[yIndex];
            int U = (unsigned char)uBuffer[uvIndex];
            int V = (unsigned char)vBuffer[uvIndex];
            
            // YUV to RGB conversion
            int C = Y - 16;
            int D = U - 128;
            int E = V - 128;
            
            int R = (298 * C + 409 * E + 128) >> 8;
            int G = (298 * C - 100 * D - 208 * E + 128) >> 8;
            int B = (298 * C + 516 * D + 128) >> 8;
            
            // Clamp to [0, 255]
            R = (R < 0) ? 0 : (R > 255) ? 255 : R;
            G = (G < 0) ? 0 : (G > 255) ? 255 : G;
            B = (B < 0) ? 0 : (B > 255) ? 255 : B;
            
            // Store RGB (BGR format for Windows)
            rgbBuffer[yIndex * 3 + 0] = (unsigned char)B;
            rgbBuffer[yIndex * 3 + 1] = (unsigned char)G;
            rgbBuffer[yIndex * 3 + 2] = (unsigned char)R;
        }
    }
}
```

**Render with GDI**:
```cpp
void RenderToWindow(unsigned char* rgbBuffer, int width, int height) {
    HDC hdc = GetDC(hwnd);
    
    BITMAPINFO bmi = {};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = width;
    bmi.bmiHeader.biHeight = -height;  // Negative for top-down
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 24;     // 24-bit RGB
    bmi.bmiHeader.biCompression = BI_RGB;
    
    RECT rect;
    GetClientRect(hwnd, &rect);
    
    StretchDIBits(hdc,
        0, 0, rect.right, rect.bottom,  // Destination
        0, 0, width, height,              // Source
        rgbBuffer, &bmi,
        DIB_RGB_COLORS, SRCCOPY);
    
    ReleaseDC(hwnd, hdc);
}
```

**Disadvantages**:
- ⚠️ **CPU intensive** - YUV conversion can cause frame drops
- ⚠️ **Artifacts** - Manual rendering may show tearing/artifacts
- ⚠️ **Complex** - More code to maintain
- ⚠️ **Performance** - Slower than Canvas API

**Use Raw Data When**:
- Adding video filters/effects
- Recording to custom formats
- Computer vision processing
- Custom compositing
- Streaming to non-standard outputs

### Self Video vs Remote Users

**Self Video** (your own camera):

**Option A: Canvas API**
```cpp
IZoomVideoSDKSession* session = sdk->getSessionInfo();
IZoomVideoSDKUser* myself = session->getMyself();
IZoomVideoSDKCanvas* canvas = myself->GetVideoCanvas();
canvas->subscribeWithView(selfVideoHwnd, aspect, resolution);
```

**Option B: Video Preview** (for self only)
```cpp
IZoomVideoSDKVideoHelper* videoHelper = sdk->getVideoHelper();
videoHelper->startVideo();  // Start transmission

// For preview rendering
videoHelper->startVideoCanvasPreview(selfVideoHwnd, aspect, resolution);
```

**Remote Users** (other participants):

**Canvas API** (recommended):
```cpp
// In onUserJoin callback
void onUserJoin(IZoomVideoSDKUserHelper*, IVideoSDKVector<IZoomVideoSDKUser*>* userList) {
    for (int i = 0; i < userList->GetCount(); i++) {
        IZoomVideoSDKUser* user = userList->GetItem(i);
        IZoomVideoSDKCanvas* canvas = user->GetVideoCanvas();
        canvas->subscribeWithView(userVideoHwnd, aspect, resolution);
    }
}
```

### Event-Driven Subscription Pattern

⚠️ **CRITICAL**: Video subscription must be **event-driven** and **manual**.

**Key Events**:

1. **`onSessionJoin`** - Subscribe to self video
2. **`onUserJoin`** - Subscribe to new remote users
3. **`onUserVideoStatusChanged`** - Re-subscribe when video turns on/off
4. **`onUserLeave`** - Unsubscribe and cleanup

**Complete Pattern**:

```cpp
class MainFrame : public IZoomVideoSDKDelegate {
private:
    std::map<IZoomVideoSDKUser*, IZoomVideoSDKCanvas*> subscribedUsers_;
    HWND videoWindow_;
    
public:
    void onSessionJoin() override {
        // Start your own video
        IZoomVideoSDKVideoHelper* videoHelper = sdk->getVideoHelper();
        videoHelper->startVideo();
        
        // Subscribe to self video
        IZoomVideoSDKUser* myself = sdk->getSessionInfo()->getMyself();
        SubscribeToUser(myself);
    }
    
    void onUserJoin(IZoomVideoSDKUserHelper*, 
                    IVideoSDKVector<IZoomVideoSDKUser*>* userList) override {
        // Get current user to exclude self
        IZoomVideoSDKUser* myself = sdk->getSessionInfo()->getMyself();
        
        for (int i = 0; i < userList->GetCount(); i++) {
            IZoomVideoSDKUser* user = userList->GetItem(i);
            
            // IMPORTANT: Only subscribe to REMOTE users!
            if (user != myself) {
                SubscribeToUser(user);
            }
        }
    }
    
    void onUserVideoStatusChanged(IZoomVideoSDKVideoHelper*, 
                                  IVideoSDKVector<IZoomVideoSDKUser*>* userList) override {
        IZoomVideoSDKUser* myself = sdk->getSessionInfo()->getMyself();
        
        for (int i = 0; i < userList->GetCount(); i++) {
            IZoomVideoSDKUser* user = userList->GetItem(i);
            if (user != myself) {
                // Re-subscribe when video status changes
                SubscribeToUser(user);
            }
        }
    }
    
    void onUserLeave(IZoomVideoSDKUserHelper*, 
                    IVideoSDKVector<IZoomVideoSDKUser*>* userList) override {
        for (int i = 0; i < userList->GetCount(); i++) {
            IZoomVideoSDKUser* user = userList->GetItem(i);
            UnsubscribeFromUser(user);
        }
    }
    
    void onSessionLeave() override {
        // Cleanup all subscriptions
        for (auto& pair : subscribedUsers_) {
            IZoomVideoSDKCanvas* canvas = pair.second;
            if (canvas) {
                canvas->unSubscribeWithView(videoWindow_);
            }
        }
        subscribedUsers_.clear();
    }
    
private:
    void SubscribeToUser(IZoomVideoSDKUser* user) {
        if (!user || subscribedUsers_.find(user) != subscribedUsers_.end())
            return;
            
        IZoomVideoSDKCanvas* canvas = user->GetVideoCanvas();
        if (canvas) {
            ZoomVideoSDKErrors ret = canvas->subscribeWithView(
                videoWindow_,
                ZoomVideoSDKVideoAspect_PanAndScan,
                ZoomVideoSDKResolution_Auto
            );
            
            if (ret == ZoomVideoSDKErrors_Success) {
                subscribedUsers_[user] = canvas;
            }
        }
    }
    
    void UnsubscribeFromUser(IZoomVideoSDKUser* user) {
        auto it = subscribedUsers_.find(user);
        if (it != subscribedUsers_.end()) {
            IZoomVideoSDKCanvas* canvas = it->second;
            if (canvas) {
                canvas->unSubscribeWithView(videoWindow_);
            }
            subscribedUsers_.erase(it);
        }
    }
};
```

**Key Points**:
- ✅ Subscribe in response to events (onUserJoin, onUserVideoStatusChanged)
- ✅ Always exclude current user from remote subscriptions
- ✅ Unsubscribe on onUserLeave
- ✅ Clean up all subscriptions on onSessionLeave
- ✅ Track subscriptions in a map for lifecycle management

### ⚠️ Screen Share Subscription (DIFFERENT from Video!)

**CRITICAL**: Screen share subscription uses `IZoomVideoSDKShareAction` from the callback, NOT `user->GetShareCanvas()`!

```cpp
// WRONG - This won't work for remote screen shares!
user->GetShareCanvas()->subscribeWithView(hwnd, ...);

// CORRECT - Use IZoomVideoSDKShareAction from onUserShareStatusChanged callback
void onUserShareStatusChanged(IZoomVideoSDKShareHelper* pShareHelper,
                               IZoomVideoSDKUser* pUser,
                               IZoomVideoSDKShareAction* pShareAction) {
    if (!pShareAction) return;
    
    ZoomVideoSDKShareStatus status = pShareAction->getShareStatus();
    
    if (status == ZoomVideoSDKShareStatus_Start || 
        status == ZoomVideoSDKShareStatus_Resume) {
        // Subscribe to the share using Canvas API
        IZoomVideoSDKCanvas* shareCanvas = pShareAction->getShareCanvas();
        if (shareCanvas) {
            shareCanvas->subscribeWithView(shareWindow_, 
                ZoomVideoSDKVideoAspect_Original);
        }
    }
    else if (status == ZoomVideoSDKShareStatus_Stop) {
        // Unsubscribe when share stops
        IZoomVideoSDKCanvas* shareCanvas = pShareAction->getShareCanvas();
        if (shareCanvas) {
            shareCanvas->unSubscribeWithView(shareWindow_);
        }
    }
}
```

**Why is share different from video?**
- **Video**: Each user has one video stream → use `user->GetVideoCanvas()`
- **Share**: A user can have multiple share actions (multi-share) → use `IZoomVideoSDKShareAction*` from callback
- The `IZoomVideoSDKShareAction` object represents a specific share stream and contains the share status, type, and rendering interfaces

**See also**: [Screen Share Subscription Example](examples/screen-share-subscription.md)

### Multi-User Video Layout

For multiple participants, you need **one HWND per user**:

```cpp
// Create separate windows/panels for each user
HWND selfVideoWindow = CreateWindow(...);   // Your video
HWND user1Window = CreateWindow(...);       // User 1's video
HWND user2Window = CreateWindow(...);       // User 2's video

// Subscribe each user to their own window
myself->GetVideoCanvas()->subscribeWithView(selfVideoWindow, ...);
user1->GetVideoCanvas()->subscribeWithView(user1Window, ...);
user2->GetVideoCanvas()->subscribeWithView(user2Window, ...);
```

**Layout Strategies**:
- Grid layout (2x2, 3x3)
- Gallery view (scrollable)
- Active speaker (large) + thumbnails
- Picture-in-picture

### Common Video Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Video not showing | Not calling `startVideo()` | Call `videoHelper->startVideo()` in `onSessionJoin` |
| Artifacts/tearing | Using Raw Data Pipe | Switch to Canvas API |
| Poor performance | YUV conversion on UI thread | Use Canvas API or move conversion to worker thread |
| Video freezes | Not processing Windows messages | Add message pump to main loop |
| Can't see self | Subscribing to wrong user | Use `session->getMyself()` for self video |
| Seeing self in remote list | Not excluding self | Check `if (user != myself)` before subscribing |

## Complete Documentation Library

This skill includes comprehensive guides organized by category:

### Core Concepts (Start Here!)
- **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - Universal 3-step pattern for ANY feature
- **[Singleton Hierarchy](concepts/singleton-hierarchy.md)** - 5-level navigation guide
- **[Canvas vs Raw Data](concepts/canvas-vs-raw-data.md)** - Choose your rendering approach

### Complete Examples
- **[Session Join Pattern](examples/session-join-pattern.md)** - JWT auth + session join with full code
- **[Video Rendering](examples/video-rendering.md)** - Canvas API video display
- **[Screen Share Subscription](examples/screen-share-subscription.md)** - View remote screen shares (DIFFERENT from video!)
- **[Raw Video Capture](examples/raw-video-capture.md)** - YUV420 frame capture
- **[Raw Audio Capture](examples/raw-audio-capture.md)** - PCM audio capture
- **[Send Raw Video](examples/send-raw-video.md)** - Virtual camera (inject custom video)
- **[Send Raw Audio](examples/send-raw-audio.md)** - Virtual mic (inject custom audio)
- **[Cloud Recording](examples/cloud-recording.md)** - Cloud recording control
- **[Command Channel](examples/command-channel.md)** - Custom command messaging
- **[Transcription](examples/transcription.md)** - Live transcription/captions

### UI Framework Integration
- **[Win32 Native](examples/dotnet-winforms/README.md#option-1-win32-native-c---direct-sdk)** - Direct SDK usage with Canvas API (best performance)
- **[WinForms (.NET)](examples/dotnet-winforms/README.md#option-2-winforms-c--ccli-wrapper)** - C++/CLI wrapper + Raw Data Pipe
- **[WPF (.NET)](examples/dotnet-winforms/README.md#option-3-wpf-c--ccli-wrapper)** - C++/CLI wrapper + BitmapSource conversion
- **[Production Quality Guidelines](examples/dotnet-winforms/README.md#production-quality-review)** - Checklist and common issues

### C++/CLI Wrapper Patterns (Wrapping ANY Native Library)
- **[Complete Guide](examples/dotnet-winforms/README.md#ccli-wrapper-patterns-for-net-integration)** - 8 patterns for native→.NET interop
- **[Pattern 1: Basic Structure](examples/dotnet-winforms/README.md#pattern-1-basic-wrapper-structure)** - Project setup, class layout
- **[Pattern 2: void* Pointers](examples/dotnet-winforms/README.md#pattern-2-opaque-void-pointers)** - Hide native types
- **[Pattern 3: gcroot Callbacks](examples/dotnet-winforms/README.md#pattern-3-gcrootT-for-nativemanaged-callbacks)** - Native→Managed events
- **[Pattern 4: IDisposable](examples/dotnet-winforms/README.md#pattern-4-destructor--finalizer-idisposable)** - Cleanup pattern
- **[Pattern 5: Strings](examples/dotnet-winforms/README.md#pattern-5-string-conversion)** - String^ ↔ wstring/string
- **[Pattern 6: Arrays](examples/dotnet-winforms/README.md#pattern-6-arraybuffer-conversion)** - pin_ptr, Marshal::Copy
- **[Pattern 7: Threading](examples/dotnet-winforms/README.md#pattern-7-thread-marshaling-native-thread--ui-thread)** - UI thread dispatch
- **[Pattern 8: LockBits](examples/dotnet-winforms/README.md#pattern-8-lockbits-for-fast-image-manipulation)** - Fast image conversion
- **[Common Errors](examples/dotnet-winforms/README.md#common-wrapper-errors)** - Troubleshooting

### Troubleshooting
- **[Windows Message Loop](troubleshooting/windows-message-loop.md)** - **CRITICAL**: Why callbacks don't fire
- **[Build Errors](troubleshooting/build-errors.md)** - SDK header dependency fixes
- **[Common Issues](troubleshooting/common-issues.md)** - Quick diagnostics & error codes

### References
- **[API Reference](references/windows-reference.md)** - 5-level API hierarchy, methods, error codes
- **[Delegate Methods](references/delegate-methods.md)** - All 80+ callback methods
- **[SKILL.md](SKILL.md)** - Complete navigation guide

### Most Critical Issues (From Real Debugging)

1. **Callbacks not firing** → Missing Windows message loop (99% of issues)
   - See: [Windows Message Loop Guide](troubleshooting/windows-message-loop.md)

2. **Video subscribe returns error 2** → Subscribing too early
   - See: [Video Rendering](examples/video-rendering.md) - Subscribe in `onUserVideoStatusChanged`

3. **Abstract class errors** → Missing virtual method implementations
   - See: [Delegate Methods](references/delegate-methods.md)

### Key Insight

**Once you learn the 3-step pattern, you can implement ANY feature:**
1. Get singleton → 2. Implement delegate → 3. Subscribe & use

See: [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

## Resources

- **Official Docs**: https://developers.zoom.us/docs/video-sdk/windows/
- **API Reference**: https://marketplacefront.zoom.us/sdk/custom/windows/
- **Dev Forum**: https://devforum.zoom.us/
- **GitHub Samples**: https://github.com/zoom/videosdk-windows-rawdata-sample
- **Working Sample**: `C:\tempsdk\zoom-video-sdk-windows-sample\` (complete implementation)

---

**Need help?** Start with [SKILL.md](SKILL.md) for complete navigation.


## Merged from video-sdk/windows/SKILL.md

# Zoom Video SDK Windows - Complete Documentation Index

## Quick Start Path

**If you're new to the SDK, follow this order:**

0. **Overview** → [windows.md](windows.md)
1. **Read the architecture pattern** → [concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)
   - Universal formula: Singleton → Delegate → Subscribe
   - Once you understand this, you can implement any feature

2. **Fix build errors** → [troubleshooting/build-errors.md](troubleshooting/build-errors.md)
   - SDK header dependencies
   - Required include order

3. **Implement session join** → [examples/session-join-pattern.md](examples/session-join-pattern.md)
   - Complete working JWT + session join code

4. **Fix callback issues** → [troubleshooting/windows-message-loop.md](troubleshooting/windows-message-loop.md)
   - **CRITICAL**: Why callbacks don't fire without Windows message loop

5. **Implement video** → [examples/video-rendering.md](examples/video-rendering.md)
   - Canvas API (SDK-rendered) vs Raw Data Pipe

6. **Troubleshoot any issues** → [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
   - Quick diagnostic checklist
   - Error code tables

---

## Documentation Structure

```
video-sdk/windows/
├── SKILL.md                           # Main skill overview
├── SKILL.md                           # This file - navigation guide
├── windows.md                          # Secondary overview doc (pointer-style)
│
├── concepts/                          # Core architectural patterns
│   ├── sdk-architecture-pattern.md   # Universal formula for ANY feature
│   ├── singleton-hierarchy.md        # 5-level navigation guide
│   └── canvas-vs-raw-data.md         # SDK-rendered vs self-rendered choice
│
├── examples/                          # Complete working code
│   ├── session-join-pattern.md       # JWT auth + session join
│   ├── video-rendering.md            # Canvas API video display
│   ├── screen-share-subscription.md  # View remote screen shares
│   ├── raw-video-capture.md          # YUV420 raw frame capture
│   ├── raw-audio-capture.md          # PCM audio capture
│   ├── send-raw-video.md             # Virtual camera (inject video)
│   ├── send-raw-audio.md             # Virtual mic (inject audio)
│   ├── cloud-recording.md            # Cloud recording control
│   ├── command-channel.md            # Custom command messaging
│   ├── transcription.md              # Live transcription/captions
│   └── dotnet-winforms/              # UI Framework integration
│       └── README.md                 # Win32, WinForms, WPF patterns
│                                     # C++/CLI wrapper patterns
│                                     # Production quality guidelines
│
├── troubleshooting/                   # Problem solving guides
│   ├── windows-message-loop.md       # CRITICAL - Why callbacks fail
│   ├── build-errors.md               # Header dependency fixes
│   └── common-issues.md              # Quick diagnostic workflow
│
└── references/                        # Reference documentation
    ├── windows-reference.md           # API hierarchy, methods, error codes
    ├── delegate-methods.md            # All 80+ callback methods
    └── samples.md                     # Official samples guide
```

---

## By Use Case

### I want to build a video app
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Understand the pattern
2. [Session Join Pattern](examples/session-join-pattern.md) - Join sessions
3. [Video Rendering](examples/video-rendering.md) - Display video
4. [Windows Message Loop](troubleshooting/windows-message-loop.md) - Fix callback issues

### I'm getting build errors
1. [Build Errors Guide](troubleshooting/build-errors.md) - SDK header dependencies
2. [Delegate Methods](references/delegate-methods.md) - Abstract class errors
3. [Common Issues](troubleshooting/common-issues.md) - Linker errors

### I'm getting runtime errors
1. [Windows Message Loop](troubleshooting/windows-message-loop.md) - Callbacks not firing
2. [Common Issues](troubleshooting/common-issues.md) - Error code tables

### I want to view screen shares
1. [Screen Share Subscription](examples/screen-share-subscription.md) - **DIFFERENT from video!**
2. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Event-driven pattern
3. [Video Rendering](examples/video-rendering.md) - Compare with video subscription

### I want to capture raw video/audio
1. [Canvas vs Raw Data](concepts/canvas-vs-raw-data.md) - Choose your approach
2. [Raw Video Capture](examples/raw-video-capture.md) - YUV420 frame capture
3. [Raw Audio Capture](examples/raw-audio-capture.md) - PCM audio capture
4. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Subscription pattern

### I want to send custom video/audio (virtual camera/mic)
1. [Send Raw Video](examples/send-raw-video.md) - Inject custom video frames
2. [Send Raw Audio](examples/send-raw-audio.md) - Inject custom audio
3. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - External source pattern

### I want to record sessions
1. [Cloud Recording](examples/cloud-recording.md) - Start/stop cloud recording
2. [API Reference](references/windows-reference.md) - Recording helper methods

### I want to use live transcription
1. [Transcription](examples/transcription.md) - Enable live captions
2. [Delegate Methods](references/delegate-methods.md) - Transcription callbacks

### I want custom messaging between participants
1. [Command Channel](examples/command-channel.md) - Send custom commands
2. [API Reference](references/windows-reference.md) - Command channel methods

### I want to build a Win32 native app
1. [Win32 Integration](examples/dotnet-winforms/README.md#option-1-win32-native-c---direct-sdk) - Direct SDK + Canvas API
2. [Video Rendering](examples/video-rendering.md) - Canvas API patterns
3. [Production Guidelines](examples/dotnet-winforms/README.md#production-quality-review) - Best practices

### I want to build a WinForms (.NET) app
1. [WinForms Integration](examples/dotnet-winforms/README.md#option-2-winforms-c--ccli-wrapper) - C++/CLI wrapper + Raw Data
2. [C++/CLI Patterns](examples/dotnet-winforms/README.md#ccli-wrapper-patterns-for-net-integration) - gcroot, Finalizer, LockBits
3. [Production Guidelines](examples/dotnet-winforms/README.md#production-quality-review) - IDisposable, thread safety

### I want to build a WPF (.NET) app
1. [WPF Integration](examples/dotnet-winforms/README.md#option-3-wpf-c--ccli-wrapper) - C++/CLI + BitmapSource
2. [Bitmap Conversion](examples/dotnet-winforms/README.md#2-bitmap--bitmapsource-conversion) - Freeze(), Dispatcher
3. [Production Guidelines](examples/dotnet-winforms/README.md#production-quality-review) - Performance optimization

### I want to use C# / .NET Framework (general)
1. [.NET Integration Overview](examples/dotnet-winforms/README.md) - **Complete C++/CLI wrapper guide**
2. [Raw Video Capture](examples/raw-video-capture.md) - YUV→RGB conversion patterns
3. [Session Join Pattern](examples/session-join-pattern.md) - SDK initialization flow

### I want to wrap ANY native C++ library for .NET
1. [C++/CLI Wrapper Patterns](examples/dotnet-winforms/README.md#ccli-wrapper-patterns-for-net-integration) - **Complete 8-pattern guide**
2. [Pattern 1: Basic Structure](examples/dotnet-winforms/README.md#pattern-1-basic-wrapper-structure) - Project setup + class layout
3. [Pattern 3: gcroot Callbacks](examples/dotnet-winforms/README.md#pattern-3-gcrootT-for-nativemanaged-callbacks) - Native→Managed events
4. [Pattern 4: IDisposable](examples/dotnet-winforms/README.md#pattern-4-destructor--finalizer-idisposable) - Cleanup pattern
5. [Common Errors](examples/dotnet-winforms/README.md#common-wrapper-errors) - Troubleshooting

### I want to implement a specific feature
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - **START HERE!**
2. [Singleton Hierarchy](concepts/singleton-hierarchy.md) - Navigate to the feature
3. [API Reference](references/windows-reference.md) - Method signatures

---

## Most Critical Documents

### 1. SDK Architecture Pattern (MASTER DOCUMENT)
**[concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)**

The universal 3-step pattern:
1. Get singleton (SDK, helpers, session, users)
2. Implement delegate (event callbacks)
3. Subscribe and use

### 2. Windows Message Loop (MOST COMMON ISSUE)
**[troubleshooting/windows-message-loop.md](troubleshooting/windows-message-loop.md)**

99% of "callbacks not firing" issues are caused by missing Windows message loop.

### 3. Singleton Hierarchy (NAVIGATION MAP)
**[concepts/singleton-hierarchy.md](concepts/singleton-hierarchy.md)**

5-level deep navigation showing how to reach every feature.

---

## Key Learnings

### Critical Discoveries:

1. **Windows Message Loop is MANDATORY**
   - SDK uses Windows message pump for callbacks
   - Without it, callbacks are queued but never fire
   - See: [Windows Message Loop Guide](troubleshooting/windows-message-loop.md)

2. **Subscribe in onUserVideoStatusChanged, NOT onUserJoin**
   - Video may not be ready when user joins
   - Wait for video status change callback
   - See: [Video Rendering](examples/video-rendering.md)

3. **Two Rendering Paths**
   - Canvas API: SDK renders to your HWND (recommended)
   - Raw Data Pipe: You receive YUV frames (advanced)
   - See: [Canvas vs Raw Data](concepts/canvas-vs-raw-data.md)

4. **Helpers Control YOUR Streams Only**
   - `videoHelper->startVideo()` starts YOUR camera
   - To see others, subscribe to their Canvas/Pipe
   - See: [Singleton Hierarchy](concepts/singleton-hierarchy.md)

5. **UI Framework Integration Differs by Platform**
   - **Win32**: Direct SDK, Canvas API (SDK renders to HWND) - best performance
   - **WinForms**: C++/CLI wrapper, Raw Data Pipe, YUV→Bitmap, InvokeRequired
   - **WPF**: Same wrapper + Bitmap→BitmapSource, Dispatcher, Freeze()
   - See: [UI Framework Integration](examples/dotnet-winforms/README.md)

6. **C++/CLI Wrapper Patterns (for ANY native library → .NET)**
   - `void*` pointers - hide native types from managed headers
   - `gcroot<T^>` - prevent GC from collecting managed references in native code
   - Finalizer + Destructor - `~Class()` and `!Class()` for IDisposable cleanup
   - `pin_ptr` + `Marshal::Copy` - array/buffer conversion
   - `LockBits` - 100x faster than SetPixel for image manipulation
   - Thread marshaling - InvokeRequired (WinForms) / Dispatcher (WPF)
   - See: [C++/CLI Wrapper Guide](examples/dotnet-winforms/README.md#ccli-wrapper-patterns-for-net-integration)

7. **Audio Connection Timing**
   - Set `audioOption.connect = false` during join
   - Call `startAudio()` in `onSessionJoin` callback
   - See: [Production Guidelines](examples/dotnet-winforms/README.md#production-quality-review)

---

## Quick Reference

### "My code won't compile"
→ [Build Errors Guide](troubleshooting/build-errors.md)

### "Callbacks never fire"
→ [Windows Message Loop](troubleshooting/windows-message-loop.md)

### "Video subscription returns error 2"
→ [Video Rendering](examples/video-rendering.md) - Subscribe in onUserVideoStatusChanged

### "Abstract class error"
→ [Delegate Methods](references/delegate-methods.md)

### "How do I implement [feature]?"
→ [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

### "How do I navigate to [controller]?"
→ [Singleton Hierarchy](concepts/singleton-hierarchy.md)

### "What error code means what?"
→ [Common Issues](troubleshooting/common-issues.md)

---

## Document Version

Based on **Zoom Video SDK for Windows v2.x**

---

**Happy coding!**

Remember: The [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) is your key to unlocking the entire SDK. Read it first!

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/virtual-agent/android', 'business', 'android', '', 'android', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Virtual Agent - Android

Official docs:
- https://developers.zoom.us/docs/virtual-agent/android/

## Quick Links

1. [concepts/webview-lifecycle.md](concepts/webview-lifecycle.md)
2. [examples/js-bridge-patterns.md](examples/js-bridge-patterns.md)
3. [references/android-reference-map.md](references/android-reference-map.md)
4. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Integration Model

- Host campaign URL in Android WebView.
- Inject runtime context (`window.zoomCampaignSdkConfig`).
- Register JavaScript bridge for `exitHandler`, `commonHandler`, `support_handoff`.
- Apply URL policy via `shouldOverrideUrlLoading` and optional multi-window callbacks.

## Hard Guardrails

- Initialize handlers before expecting JS callbacks.
- Treat legacy `openURL` command handling as compatibility path only.
- Prefer DOM links or `window.open` handling plus explicit native routing.

## Chaining

- Product-level patterns: [../SKILL.md](../SKILL.md)
- Contact Center mobile scope: [../../contact-center/android/SKILL.md](../../contact-center/android/SKILL.md)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/virtual-agent/ios', 'business', 'ios', '', 'ios', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Virtual Agent - iOS

Official docs:
- https://developers.zoom.us/docs/virtual-agent/ios/

## Quick Links

1. [concepts/webview-lifecycle.md](concepts/webview-lifecycle.md)
2. [examples/js-bridge-patterns.md](examples/js-bridge-patterns.md)
3. [references/ios-reference-map.md](references/ios-reference-map.md)
4. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Integration Model

- Load campaign URL in `WKWebView`.
- Inject `window.zoomCampaignSdkConfig` using `WKUserScript`.
- Register message handlers for exit/common/handoff flows.
- Handle URL behavior in navigation delegates (`in-app`, `SFSafariViewController`, or system browser).

## Hard Guardrails

- Register scripts and handlers before web interaction.
- Handle iOS 14.5+ download behavior where needed.
- Keep deprecated `openURL` command support as fallback only.

## Chaining

- Product-level patterns: [../SKILL.md](../SKILL.md)
- Contact Center mobile scope: [../../contact-center/ios/SKILL.md](../../contact-center/ios/SKILL.md)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/virtual-agent', 'business', 'virtual-agent', '', 'virtual-agent', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-virtual-agent

Background reference for Zoom Virtual Agent across:
- Web campaign/chat embeds.
- Android WebView wrappers.
- iOS WKWebView wrappers.
- Knowledge-base sync and custom API ingestion.

Official docs:
- https://developers.zoom.us/docs/virtual-agent/
- https://developers.zoom.us/docs/virtual-agent/web/
- https://developers.zoom.us/docs/virtual-agent/android/
- https://developers.zoom.us/docs/virtual-agent/ios/

## Routing Guardrail

- If the user is implementing Contact Center app surfaces inside Zoom client, chain with [../contact-center/SKILL.md](../contact-center/SKILL.md).
- If the user needs backend knowledge-base CRUD or automation scripts, chain with [../rest-api/SKILL.md](../rest-api/SKILL.md) and [../oauth/SKILL.md](../oauth/SKILL.md).
- If the user asks only for website bot embed and campaign controls, stay on [web/SKILL.md](web/SKILL.md).
- If the user asks for mobile native wrappers around web chat, route to [android/SKILL.md](android/SKILL.md) or [ios/SKILL.md](ios/SKILL.md).

## Quick Links

1. [concepts/architecture-and-lifecycle.md](concepts/architecture-and-lifecycle.md)
2. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
3. [references/versioning-and-drift.md](references/versioning-and-drift.md)
4. [references/samples-validation.md](references/samples-validation.md)
5. [references/environment-variables.md](references/environment-variables.md)
6. [troubleshooting/common-drift-and-breaks.md](troubleshooting/common-drift-and-breaks.md)
7. [RUNBOOK.md](RUNBOOK.md)

Platform skills:
- [web/SKILL.md](web/SKILL.md)
- [android/SKILL.md](android/SKILL.md)
- [ios/SKILL.md](ios/SKILL.md)

## Common Lifecycle Pattern

1. Configure campaign or entry ID in Virtual Agent admin.
2. Initialize SDK in web or WebView container.
3. Wait for readiness (`zoomCampaignSdk:ready` or `waitForReady()`) before calling APIs.
4. Register bridge handlers (`exitHandler`, `commonHandler`, `support_handoff`) when native orchestration is needed.
5. Handle conversation lifecycle (`engagement_started`, `engagement_ended`) and UI state.
6. End chat (`endChat`) and clean up listeners.

## High-Level Scenarios

- Website campaign launcher with contextual customer attributes.
- Mobile app WebView chat with native close/handoff bridge.
- External URL handling via system browser vs in-app browser policy.
- Knowledge-base sync from external systems using custom API connector.
- Cross-team support flow that escalates from bot to live support with handoff payload.

## Chaining

- Contact Center app/web/mobile patterns: [../contact-center/SKILL.md](../contact-center/SKILL.md)
- OAuth app setup and tokens: [../oauth/SKILL.md](../oauth/SKILL.md)
- API workflows for KB automation: [../rest-api/SKILL.md](../rest-api/SKILL.md)
- Event-driven backend follow-up: [../webhooks/SKILL.md](../webhooks/SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/virtual-agent/web', 'business', 'web', '', 'web', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Virtual Agent SDK - Web

Official docs:
- https://developers.zoom.us/docs/virtual-agent/web/
- https://developers.zoom.us/docs/virtual-agent/web/reference/

## Quick Links

1. [concepts/lifecycle-and-events.md](concepts/lifecycle-and-events.md)
2. [examples/campaign-and-entry-patterns.md](examples/campaign-and-entry-patterns.md)
3. [references/web-reference-map.md](references/web-reference-map.md)
4. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Hard Guardrails

- Gate calls behind readiness (`zoomCampaignSdk:ready` or `waitForReady()`).
- Do not call `show/hide/open/close` before SDK initialization.
- Keep CSP and script host policy validated before debugging business logic.
- Prefer campaign embed over entry ID when minimizing user friction is a priority.

## Chaining

- Product-level architecture and drift checks: [../SKILL.md](../SKILL.md)
- Contact Center web context: [../../contact-center/web/SKILL.md](../../contact-center/web/SKILL.md)
- OAuth or REST for backend workflows: [../../oauth/SKILL.md](../../oauth/SKILL.md), [../../rest-api/SKILL.md](../../rest-api/SKILL.md)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/webhooks', 'business', 'webhooks', '', 'webhooks', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /setup-zoom-webhooks

Background reference for Zoom event delivery over HTTP. Prefer workflow skills first, then use this file for verification, subscription, and delivery details.

## Prerequisites

- Zoom app with Event Subscriptions enabled
- HTTPS endpoint to receive webhooks
- Webhook secret token for verification

> **Need help with authentication?** See the **[zoom-oauth](../oauth/SKILL.md)** skill for OAuth setup.

## Quick Start

```javascript
// Express.js webhook handler
const crypto = require('crypto');

// Capture raw body for signature verification (avoid re-serializing JSON).
app.use(require('express').json({
  verify: (req, _res, buf) => { req.rawBody = buf; }
}));

app.post('/webhook', (req, res) => {
  // Verify webhook signature
  const signature = req.headers['x-zm-signature'];
  const timestamp = req.headers['x-zm-request-timestamp'];
  const body = req.rawBody ? req.rawBody.toString('utf8') : JSON.stringify(req.body);
  const payload = `v0:${timestamp}:${body}`;
  const hash = crypto.createHmac('sha256', WEBHOOK_SECRET)
    .update(payload).digest('hex');
  
  if (signature !== `v0=${hash}`) {
    return res.status(401).send('Invalid signature');
  }

  // Handle event
  const { event, payload } = req.body;
  console.log(`Received: ${event}`);
  
  res.status(200).send();
});
```

## Common Events

| Event | Description |
|-------|-------------|
| `meeting.started` | Meeting has started |
| `meeting.ended` | Meeting has ended |
| `meeting.participant_joined` | Participant joined meeting |
| `recording.completed` | Cloud recording ready |
| `user.created` | New user added |

## Detailed References

- **[references/events.md](references/events.md)** - Complete event types reference
- **[references/verification.md](references/verification.md)** - Webhook URL validation
- **[references/subscriptions.md](references/subscriptions.md)** - Event subscriptions API

## Troubleshooting

- **[RUNBOOK.md](RUNBOOK.md)** - 5-minute preflight checks before deep debugging
- **[troubleshooting/common-issues.md](troubleshooting/common-issues.md)** - Signature verification, retries, URL validation

## Sample Repositories

### Official (by Zoom)

| Type | Repository | Stars |
|------|------------|-------|
| Node.js | [webhook-sample](https://github.com/zoom/webhook-sample) | 34 |
| PostgreSQL | [webhook-to-postgres](https://github.com/zoom/webhook-to-postgres) | 5 |
| Go/Fiber | [Go-Webhooks](https://github.com/zoom/Go-Webhooks) | - |
| Header Auth | [zoom-webhook-verification-headers](https://github.com/zoom/zoom-webhook-verification-headers) | - |

### Community

| Language | Repository | Description |
|----------|------------|-------------|
| Laravel | [binary-cats/laravel-webhooks](https://github.com/binary-cats/laravel-webhooks) | Laravel webhook handler |
| AWS Lambda | [splunk/zoom-webhook-to-hec](https://github.com/splunk/zoom-webhook-to-hec) | Serverless to Splunk HEC |
| Node.js | [Will4950/zoom-webhook-listener](https://github.com/Will4950/zoom-webhook-listener) | Webhook forwarder |
| Express+Redis | [ojusave/eventSubscriptionPlayground](https://github.com/ojusave/eventSubscriptionPlayground) | Socket.io + Redis |

### Multi-Language Samples (by tanchunsiong)

| Language | Repository |
|----------|------------|
| Node.js | [Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-NodeJS](https://github.com/tanchunsiong/Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-NodeJS) |
| C# | [Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-ASP.NET-Core-C-](https://github.com/tanchunsiong/Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-ASP.NET-Core-C-) |
| Java | [Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-Java-Spring-Boot](https://github.com/tanchunsiong/Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-Java-Spring-Boot) |
| Python | [Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-Python](https://github.com/tanchunsiong/Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-Python) |
| PHP | [Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-PHP](https://github.com/tanchunsiong/Zoom-Webhook-Signature-OAuth-and-REST-API-Development-Sample-In-PHP) |

**Full list**: See [general/references/community-repos.md](../general/references/community-repos.md)

## Resources

- **Webhook docs**: https://developers.zoom.us/docs/api/webhooks/
- **Event reference**: https://developers.zoom.us/docs/api/rest/reference/zoom-api/events/
- **Developer forum**: https://devforum.zoom.us/

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$)
ON CONFLICT (skill_key) DO NOTHING;
