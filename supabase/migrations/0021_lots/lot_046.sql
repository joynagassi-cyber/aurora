INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/websockets', 'business', 'websockets', '', 'websockets', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /setup-zoom-websockets

Background reference for persistent Zoom event streams. Prefer workflow routing first, then use this file when WebSockets are plausibly better than webhooks.

## WebSockets vs Webhooks

| Aspect | WebSockets | Webhooks |
|--------|------------|----------|
| **Connection** | Persistent, bidirectional | One-time HTTP POST |
| **Latency** | Lower (no HTTP overhead) | Higher (new connection per event) |
| **Security** | Direct connection, no exposed endpoint | Requires endpoint validation, IP whitelisting |
| **Model** | Pull (you connect to Zoom) | Push (Zoom connects to you) |
| **State** | Stateful (maintains connection) | Stateless (each event independent) |
| **Setup** | More complex (access token, connection) | Simpler (just endpoint URL) |

**Choose WebSockets when:**
- Real-time, low-latency updates are critical
- Security is paramount (banking, healthcare, finance)
- You don't want to expose a public endpoint
- You need bidirectional communication

**Choose Webhooks when:**
- Simpler setup is preferred
- Small number of event notifications
- Existing HTTP infrastructure

## Prerequisites

- Server-to-Server OAuth app in [Zoom Marketplace](https://marketplace.zoom.us/)
- Account ID, Client ID, and Client Secret
- WebSocket subscription with events enabled

> **Need help with S2S OAuth?** See the **[zoom-oauth](../oauth/SKILL.md)** skill for complete authentication flows.

> **Start troubleshooting fast:** Use the **[5-Minute Runbook](RUNBOOK.md)** before deep debugging.

## Quick Start

### 1. Create Server-to-Server OAuth App

1. Go to [Zoom Marketplace](https://marketplace.zoom.us/develop/create)
2. Create a **Server-to-Server OAuth** app
3. Copy Account ID, Client ID, Client Secret

### 2. Enable WebSocket Subscription

1. In your app, go to **Feature** → **Event Subscriptions**
2. Add an Event Subscription
3. Select **WebSockets** as the method type
4. Select events to subscribe to (e.g., `meeting.created`, `meeting.started`)
5. Save - an endpoint URL will be generated

### 3. Connect via WebSocket

```javascript
const WebSocket = require('ws');
const axios = require('axios');

// Step 1: Get access token
async function getAccessToken() {
  const credentials = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
  
  const response = await axios.post(
    'https://zoom.us/oauth/token',
    new URLSearchParams({
      grant_type: 'account_credentials',
      account_id: ACCOUNT_ID
    }),
    {
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );
  
  return response.data.access_token;
}

// Step 2: Connect to WebSocket
async function connectWebSocket() {
  const accessToken = await getAccessToken();
  
  // WebSocket URL from your subscription settings
  const wsUrl = `wss://ws.zoom.us/ws?subscriptionId=${SUBSCRIPTION_ID}&access_token=${accessToken}`;
  
  const ws = new WebSocket(wsUrl);
  
  ws.on('open', () => {
    console.log('WebSocket connection established');
  });
  
  ws.on('message', (data) => {
    const event = JSON.parse(data);
    console.log('Event received:', event.event);
    
    // Handle different event types
    switch (event.event) {
      case 'meeting.started':
        console.log(`Meeting started: ${event.payload.object.topic}`);
        break;
      case 'meeting.ended':
        console.log(`Meeting ended: ${event.payload.object.uuid}`);
        break;
      case 'meeting.participant_joined':
        console.log(`Participant joined: ${event.payload.object.participant.user_name}`);
        break;
    }
  });
  
  ws.on('close', (code, reason) => {
    console.log(`Connection closed: ${code} - ${reason}`);
    // Implement reconnection logic
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
  
  return ws;
}

connectWebSocket();
```

## Event Format

Events received via WebSocket have the same format as webhook events:

```json
{
  "event": "meeting.started",
  "event_ts": 1706123456789,
  "payload": {
    "account_id": "abcD3ojkdbjfg",
    "object": {
      "id": 1234567890,
      "uuid": "abcdefgh-1234-5678-abcd-1234567890ab",
      "host_id": "xyz789",
      "topic": "Team Standup",
      "type": 2,
      "start_time": "2024-01-25T10:00:00Z",
      "timezone": "America/Los_Angeles"
    }
  }
}
```

## Common Events

| Event | Description |
|-------|-------------|
| `meeting.created` | Meeting scheduled |
| `meeting.updated` | Meeting settings changed |
| `meeting.deleted` | Meeting deleted |
| `meeting.started` | Meeting begins |
| `meeting.ended` | Meeting ends |
| `meeting.participant_joined` | Participant joins meeting |
| `meeting.participant_left` | Participant leaves meeting |
| `recording.completed` | Cloud recording ready |
| `user.created` | New user added |
| `user.updated` | User details changed |

## Connection Management

### Keep-Alive

WebSocket connections require periodic heartbeats. Zoom will close idle connections.

```javascript
// Send ping every 30 seconds
setInterval(() => {
  if (ws.readyState === WebSocket.OPEN) {
    ws.ping();
  }
}, 30000);
```

### Reconnection

Implement automatic reconnection for reliability:

```javascript
function connectWithReconnect() {
  const ws = connectWebSocket();
  
  ws.on('close', () => {
    console.log('Connection lost. Reconnecting in 5 seconds...');
    setTimeout(connectWithReconnect, 5000);
  });
  
  return ws;
}
```

### Single Connection Limit

**Important:** Only ONE WebSocket connection can be open per subscription at a time. Opening a new connection will close the existing one.

## Detailed References

- **[references/connection.md](references/connection.md)** - Connection lifecycle, authentication, error handling
- **[references/events.md](references/events.md)** - Complete event types reference

## Troubleshooting

- **[troubleshooting/common-issues.md](troubleshooting/common-issues.md)** - Subscription URL confusion, disconnects, no-events debugging

## Sample Repositories

### Official / Community

| Type | Repository | Description |
|------|------------|-------------|
| Node.js | [just-zoomit/zoom-websockets](https://github.com/just-zoomit/zoom-websockets) | WebSocket sample with S2S OAuth |

## WebSockets vs RTMS

Don't confuse WebSockets with RTMS (Realtime Media Streams):

| Feature | WebSockets | RTMS |
|---------|------------|------|
| **Purpose** | Event notifications | Media streams |
| **Data** | Meeting events, user events | Audio, video, transcripts |
| **Use case** | React to Zoom events | AI/ML, live transcription |
| **Skill** | This skill | **rtms** |

For real-time audio/video/transcript data, use the **rtms** skill instead.

## Resources

- **WebSockets docs**: https://developers.zoom.us/docs/api/websockets/
- **Webhooks comparison**: https://www.zoom.com/en/blog/a-guide-to-webhooks-and-websockets/
- **Developer forum**: https://devforum.zoom.us/

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/zoom-apps-sdk', 'business', 'zoom-apps-sdk', '', 'zoom-apps-sdk', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Apps SDK

Background reference for web apps that run inside the Zoom client. Prefer `choose-zoom-approach` first, then route here for Layers API, Collaborate Mode, in-client OAuth, and runtime constraints.

# Zoom Apps SDK

Build web apps that run inside the Zoom client - meetings, webinars, main client, and Zoom Phone.

**Official Documentation**: https://developers.zoom.us/docs/zoom-apps/
**SDK Reference**: https://appssdk.zoom.us/
**NPM Package**: https://www.npmjs.com/package/@zoom/appssdk

## Quick Links

**New to Zoom Apps? Follow this path:**

1. **[Architecture](concepts/architecture.md)** - Frontend/backend pattern, embedded browser, deep linking
2. **[Quick Start](examples/quick-start.md)** - Complete working Express + SDK app
3. **[Running Contexts](concepts/running-contexts.md)** - Where your app runs (inMeeting, inMainClient, etc.)
4. **[Zoom Apps vs Meeting SDK](concepts/meeting-sdk-vs-zoom-apps.md)** - Stop mixing app types
4. **[In-Client OAuth](examples/in-client-oauth.md)** - Seamless authorization with PKCE
5. **[API Reference](references/apis.md)** - 100+ SDK methods
6. **Integrated Index** - see the section below in this file
7. **[5-Minute Runbook](RUNBOOK.md)** - Preflight checks before deep debugging

**Reference:**
- **[API Reference](references/apis.md)** - All SDK methods by category
- **[Events Reference](references/events.md)** - All SDK event listeners
- **[Layers API](references/layers-api.md)** - Immersive and camera mode rendering
- **[OAuth Reference](references/oauth.md)** - OAuth flows for Zoom Apps
- **[Zoom Mail](references/zmail-sdk.md)** - Mail plugin integration

**Having issues?**
- App won't load in Zoom → Check [Domain Allowlist](#url-whitelisting-required) below
- SDK errors → [Common Issues](troubleshooting/common-issues.md)
- Local dev setup → [Debugging Guide](troubleshooting/debugging.md)
- Version upgrade → [Migration Guide](troubleshooting/migration.md)
- Forum-derived FAQs → [Forum Top Questions](troubleshooting/forum-top-questions.md)

**Building immersive experiences?**
- [Layers Immersive Mode](examples/layers-immersive.md) - Custom video layouts
- [Camera Mode](examples/layers-camera.md) - Virtual camera overlays

> **Need help with OAuth?** See the **[zoom-oauth](../oauth/SKILL.md)** skill for authentication flows.

## SDK Overview

The Zoom Apps SDK (`@zoom/appssdk`) provides JavaScript APIs for web apps running in Zoom's embedded browser:

- **Context APIs** - Get meeting, user, and participant info
- **Meeting Actions** - Share app, invite participants, open URLs
- **Authorization** - In-Client OAuth with PKCE (no browser redirect)
- **Layers API** - Immersive video layouts and camera mode overlays
- **Collaborate Mode** - Shared app state across participants
- **App Communication** - Message passing between app instances (main client <-> meeting)
- **Media Controls** - Virtual backgrounds, camera listing, recording control
- **UI Controls** - Expand app, notifications, popout
- **Events** - React to meeting state, participants, sharing, and more

## Prerequisites

- Zoom app configured as **"Zoom App"** type in [Marketplace](https://marketplace.zoom.us/)
- OAuth credentials (Client ID + Secret) with Zoom Apps scopes
- Web application (Node.js + Express recommended)
- **Your domain whitelisted** in Marketplace domain allowlist
- ngrok or HTTPS tunnel for local development
- Node.js 18+ (for the backend server)

## Quick Start

### Option A: NPM (Recommended for frameworks)

```bash
npm install @zoom/appssdk
```

```javascript
import zoomSdk from '@zoom/appssdk';

async function init() {
  try {
    const configResponse = await zoomSdk.config({
      capabilities: [
        'shareApp',
        'getMeetingContext',
        'getUserContext',
        'openUrl'
      ],
      version: '0.16'
    });

    console.log('Running context:', configResponse.runningContext);
    // 'inMeeting' | 'inMainClient' | 'inWebinar' | 'inImmersive' | ...

    const context = await zoomSdk.getMeetingContext();
    console.log('Meeting ID:', context.meetingID);
  } catch (error) {
    console.error('Not running inside Zoom:', error.message);
    showDemoMode();
  }
}
```

### Option B: CDN (Vanilla JS)

```html
<script src="https://appssdk.zoom.us/sdk.js"></script>

<script>
// CRITICAL: Do NOT declare "let zoomSdk" - the SDK defines window.zoomSdk globally
// Using "let zoomSdk = ..." causes: SyntaxError: redeclaration of non-configurable global property
let sdk = window.zoomSdk;  // Use a different variable name

async function init() {
  try {
    const configResponse = await sdk.config({
      capabilities: ['shareApp', 'getMeetingContext', 'getUserContext'],
      version: '0.16'
    });

    console.log('Running context:', configResponse.runningContext);
  } catch (error) {
    console.error('Not running inside Zoom:', error.message);
    showDemoMode();
  }
}

function showDemoMode() {
  document.body.innerHTML = '<h1>Preview Mode</h1><p>Open this app inside Zoom to use.</p>';
}

document.addEventListener('DOMContentLoaded', () => {
  init();
  setTimeout(() => { if (!sdk) showDemoMode(); }, 3000);
});
</script>
```

## Critical: Global Variable Conflict

The CDN script defines `window.zoomSdk` globally. **Do NOT redeclare it:**

```javascript
// WRONG - causes SyntaxError in Zoom's embedded browser
let zoomSdk = null;
zoomSdk = window.zoomSdk;

// CORRECT - use different variable name
let sdk = window.zoomSdk;

// ALSO CORRECT - NPM import (no conflict)
import zoomSdk from '@zoom/appssdk';
```

This only applies to the CDN approach. The NPM import creates a module-scoped variable, no conflict.

## Browser Preview / Demo Mode

The SDK only functions inside the Zoom client. When accessed in a regular browser:
- `window.zoomSdk` exists but `sdk.config()` throws an error
- Always implement try/catch with fallback UI
- Add timeout (3 seconds) in case SDK hangs

## URL Whitelisting (Required)

**Your app will NOT load in Zoom unless the domain is whitelisted.**

1. Go to [Zoom Marketplace](https://marketplace.zoom.us/)
2. Open your app -> **Feature** tab
3. Under **Zoom App**, find **Add Allow List**
4. Add your domain (e.g., `yourdomain.com` for production, `xxxxx.ngrok.io` for dev)

Without this, the Zoom client shows a blank panel with no error message.

## OAuth Scopes (Required)

Capabilities require matching OAuth scopes enabled in Marketplace:

| Capability | Required Scope |
|------------|----------------|
| `getMeetingContext` | `zoomapp:inmeeting` |
| `getUserContext` | `zoomapp:inmeeting` |
| `shareApp` | `zoomapp:inmeeting` |
| `openUrl` | `zoomapp:inmeeting` |
| `sendAppInvitation` | `zoomapp:inmeeting` |
| `runRenderingContext` | `zoomapp:inmeeting` |
| `authorize` | `zoomapp:inmeeting` |
| `getMeetingParticipants` | `zoomapp:inmeeting` |

**To add scopes:** Marketplace -> Your App -> **Scopes** tab -> Add required scopes.

Missing scopes = capability fails silently or throws error. Users must re-authorize if you add new scopes.

## Running Contexts

Your app runs in different surfaces within Zoom. The `configResponse.runningContext` tells you where:

| Context | Surface | Description |
|---------|---------|-------------|
| `inMeeting` | Meeting sidebar | Most common. Full meeting APIs available |
| `inMainClient` | Main client panel | Home tab. No meeting context APIs |
| `inWebinar` | Webinar sidebar | Host/panelist. Meeting + webinar APIs |
| `inImmersive` | Layers API | Full-screen custom rendering |
| `inCamera` | Camera mode | Virtual camera overlay |
| `inCollaborate` | Collaborate mode | Shared state context |
| `inPhone` | Zoom Phone | Phone call app |
| `inChat` | Team Chat | Chat sidebar |

See **[Running Contexts](concepts/running-contexts.md)** for context-specific behavior and APIs.

## SDK Initialization Pattern

Every Zoom App starts with `config()`:

```javascript
import zoomSdk from '@zoom/appssdk';

const configResponse = await zoomSdk.config({
  capabilities: [
    // List ALL APIs you will use
    'getMeetingContext',
    'getUserContext',
    'shareApp',
    'openUrl',
    'authorize',
    'onAuthorized'
  ],
  version: '0.16'
});

// configResponse contains:
// {
//   runningContext: 'inMeeting',
//   clientVersion: '5.x.x',
//   unsupportedApis: []  // APIs not supported in this client version
// }
```

**Rules:**
1. `config()` MUST be called before any other SDK method
2. Only capabilities listed in `config()` are available
3. Capabilities must match OAuth scopes in Marketplace
4. Check `unsupportedApis` for graceful degradation

## In-Client OAuth (Summary)

Best UX for authorization - no browser redirect:

```javascript
// 1. Get code challenge from your backend
const { codeChallenge, state } = await fetch('/api/auth/challenge').then(r => r.json());

// 2. Trigger in-client authorization
await zoomSdk.authorize({ codeChallenge, state });

// 3. Listen for authorization result
zoomSdk.addEventListener('onAuthorized', async (event) => {
  const { code, state } = event;
  // 4. Send code to backend for token exchange
  await fetch('/api/auth/token', {
    method: 'POST',
    body: JSON.stringify({ code, state })
  });
});
```

See **[In-Client OAuth Guide](examples/in-client-oauth.md)** for complete implementation.

## Layers API (Summary)

Build immersive video layouts and camera overlays:

```javascript
// Start immersive mode - replaces gallery view
await zoomSdk.runRenderingContext({ view: 'immersive' });

// Position participant video feeds
await zoomSdk.drawParticipant({
  participantUUID: 'user-uuid',
  x: 0, y: 0, width: 640, height: 480, zIndex: 1
});

// Add overlay images
await zoomSdk.drawImage({
  imageData: canvas.toDataURL(),
  x: 0, y: 0, width: 1280, height: 720, zIndex: 0
});

// Exit immersive mode
await zoomSdk.closeRenderingContext();
```

See **[Layers Immersive](examples/layers-immersive.md)** and **[Camera Mode](examples/layers-camera.md)**.

## Environment Variables

| Variable | Description | Where to Find |
|----------|-------------|---------------|
| `ZOOM_APP_CLIENT_ID` | App client ID | Marketplace -> App -> App Credentials |
| `ZOOM_APP_CLIENT_SECRET` | App client secret | Marketplace -> App -> App Credentials |
| `ZOOM_APP_REDIRECT_URI` | OAuth redirect URL | Your server URL + `/auth` |
| `SESSION_SECRET` | Cookie signing secret | Generate random string |
| `ZOOM_HOST` | Zoom host URL | `https://zoom.us` (or `https://zoomgov.com`) |

## Common APIs

| API | Description |
|-----|-------------|
| `config()` | Initialize SDK, request capabilities |
| `getMeetingContext()` | Get meeting ID, topic, status |
| `getUserContext()` | Get user name, role, participant ID |
| `getRunningContext()` | Get current running context |
| `getMeetingParticipants()` | List participants |
| `shareApp()` | Share app screen with participants |
| `openUrl({ url })` | Open URL in external browser |
| `sendAppInvitation()` | Invite users to open your app |
| `authorize()` | Trigger In-Client OAuth |
| `connect()` | Connect to other app instances |
| `postMessage()` | Send message to connected instances |
| `runRenderingContext()` | Start Layers API (immersive/camera) |
| `expandApp({ action })` | Expand/collapse app panel |
| `showNotification()` | Show notification in Zoom |

## Complete Documentation Library

### Core Concepts
- **[Architecture](concepts/architecture.md)** - Frontend/backend pattern, embedded browser, deep linking, X-Zoom-App-Context
- **[Running Contexts](concepts/running-contexts.md)** - All contexts, context-specific APIs, multi-instance communication
- **[Security](concepts/security.md)** - OWASP headers, CSP, cookie security, PKCE, token storage

### Complete Examples
- **[Quick Start](examples/quick-start.md)** - Hello World Express + SDK app
- **[In-Client OAuth](examples/in-client-oauth.md)** - PKCE authorization flow
- **[Layers Immersive](examples/layers-immersive.md)** - Custom video layouts
- **[Camera Mode](examples/layers-camera.md)** - Virtual camera overlays
- **[Collaborate Mode](examples/collaborate-mode.md)** - Shared state across participants
- **[Guest Mode](examples/guest-mode.md)** - Unauthenticated/authenticated/authorized states
- **[Breakout Rooms](examples/breakout-rooms.md)** - Room detection and cross-room state
- **[App Communication](examples/app-communication.md)** - connect + postMessage between instances

### Troubleshooting
- **[Common Issues](troubleshooting/common-issues.md)** - Quick diagnostics and error codes
- **[Debugging](troubleshooting/debugging.md)** - Local dev, ngrok, browser preview
- **[Migration](troubleshooting/migration.md)** - SDK version upgrade notes

### References
- **[API Reference](references/apis.md)** - All 100+ SDK methods
- **[Events Reference](references/events.md)** - All SDK event listeners
- **[Layers API Reference](references/layers-api.md)** - Drawing and rendering methods
- **[OAuth Reference](references/oauth.md)** - OAuth flows for Zoom Apps
- **[Zoom Mail](references/zmail-sdk.md)** - Mail plugin integration

## Sample Repositories

### Official (by Zoom)

| Repository | Type | Last Updated | Status | SDK Version |
|-----------|------|-------------|--------|-------------|
| [zoomapps-sample-js](https://github.com/zoom/zoomapps-sample-js) | Hello World (Vanilla JS) | Dec 2025 | Active | ^0.16.26 |
| [zoomapps-advancedsample-react](https://github.com/zoom/zoomapps-advancedsample-react) | Advanced (React + Redis) | Oct 2025 | Active | 0.16.0 |
| [zoomapps-customlayout-js](https://github.com/zoom/zoomapps-customlayout-js) | Layers API | Nov 2023 | Stale | ^0.16.8 |
| [zoomapps-texteditor-vuejs](https://github.com/zoom/zoomapps-texteditor-vuejs) | Collaborate (Vue + Y.js) | Oct 2023 | Stale | ^0.16.7 |
| [zoomapps-serverless-vuejs](https://github.com/zoom/zoomapps-serverless-vuejs) | Serverless (Firebase) | Aug 2024 | Stale | ^0.16.21 |
| [zoomapps-cameramode-vuejs](https://github.com/zoom/zoomapps-cameramode-vuejs) | Camera Mode | - | - | - |
| [zoomapps-workshop-sample](https://github.com/zoom/zoomapps-workshop-sample) | Workshop | - | - | - |

**Recommended for new projects:** Use `@zoom/appssdk` version `^0.16.26`.

### Community

| Type | Repository | Description |
|------|------------|-------------|
| Library | [harvard-edtech/zaccl](https://github.com/harvard-edtech/zaccl) | Zoom App Complete Connection Library |

**Full list**: See [general/references/community-repos.md](../general/references/community-repos.md)

### Learning Path

1. **Start**: `zoomapps-sample-js` - Simplest, most up-to-date
2. **Advanced**: `zoomapps-advancedsample-react` - Comprehensive (In-Client OAuth, Guest Mode, Collaborate)
3. **Specialized**: Pick based on feature (Layers, Serverless, Camera Mode)

## Critical Gotchas (From Real Development)

### 1. Global Variable Conflict
The CDN script defines `window.zoomSdk`. Declaring `let zoomSdk` in your code causes `SyntaxError: redeclaration of non-configurable global property`. Use `let sdk = window.zoomSdk` or the NPM import.

### 2. Domain Allowlist
Your app URL **must** be in the Marketplace domain allowlist. Without it, Zoom shows a blank panel with no error. Also add `appssdk.zoom.us` and any CDN domains you use.

### 3. Capabilities Must Be Listed
Only APIs listed in `config({ capabilities: [...] })` are available. Calling an unlisted API throws an error. This is also true for event listeners.

### 4. SDK Only Works Inside Zoom
`zoomSdk.config()` throws outside the Zoom client. Always wrap in try/catch with browser fallback:
```javascript
try { await zoomSdk.config({...}); } catch { showBrowserPreview(); }
```

### 5. ngrok URL Changes
Free ngrok URLs change on restart. You must update 4 places in Marketplace: Home URL, Redirect URL, OAuth Allow List, Domain Allow List. Consider ngrok paid plan for stable subdomain.

### 6. In-Client OAuth vs Web OAuth
Use `zoomSdk.authorize()` (In-Client) for best UX - no browser redirect. Only fall back to web redirect for initial install from Marketplace.

### 7. Camera Mode CEF Race Condition
Camera mode uses CEF which takes time to initialize. `drawImage`/`drawWebView` may fail if called too early. Implement retry with exponential backoff.

### 8. Cookie Configuration
Zoom's embedded browser requires cookies with `SameSite=None` and `Secure=true`. Without this, sessions break silently.

### 9. State Validation
Always validate the OAuth `state` parameter to prevent CSRF attacks. Generate cryptographically random state, store it, and verify on callback.

## Resources

- **Official docs**: https://developers.zoom.us/docs/zoom-apps/
- **SDK reference**: https://appssdk.zoom.us/
- **NPM package**: https://www.npmjs.com/package/@zoom/appssdk
- **Developer forum**: https://devforum.zoom.us/
- **GitHub SDK source**: https://github.com/zoom/appssdk

---

**Need help?** Start with Integrated Index section below for complete navigation.

---

## Integrated Index

_This section was migrated from `SKILL.md`._

## Quick Start Path

**If you're new to Zoom Apps, follow this order:**

1. **Run preflight checks first** -> [RUNBOOK.md](RUNBOOK.md)

2. **Read the architecture** -> [concepts/architecture.md](concepts/architecture.md)
   - Frontend/backend pattern, embedded browser, deep linking
   - Understand how Zoom loads and communicates with your app

3. **Build your first app** -> [examples/quick-start.md](examples/quick-start.md)
   - Complete Express + SDK Hello World
   - ngrok setup for local development

4. **Understand running contexts** -> [concepts/running-contexts.md](concepts/running-contexts.md)
   - Where your app runs (inMeeting, inMainClient, inWebinar, etc.)
   - Context-specific APIs and limitations

5. **Implement OAuth** -> [examples/in-client-oauth.md](examples/in-client-oauth.md)
   - In-Client OAuth with PKCE (best UX)
   - Token exchange and storage

6. **Add features** -> [references/apis.md](references/apis.md)
   - 100+ SDK methods organized by category
   - Code examples for each

7. **Troubleshoot** -> [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
   - Quick diagnostics for common problems

---

## Documentation Structure

```
zoom-apps-sdk/
├── SKILL.md                           # Main skill overview
├── SKILL.md                           # This file - navigation guide
│
├── concepts/                          # Core architectural patterns
│   ├── architecture.md               # Frontend/backend, embedded browser, OAuth flow
│   ├── running-contexts.md           # Where your app runs + context-specific APIs
│   └── security.md                   # OWASP headers, CSP, data access layers
│
├── examples/                          # Complete working code
│   ├── quick-start.md                # Hello World - minimal Express + SDK app
│   ├── in-client-oauth.md            # In-Client OAuth with PKCE
│   ├── layers-immersive.md           # Layers API - immersive mode (custom layouts)
│   ├── layers-camera.md              # Layers API - camera mode (virtual camera)
│   ├── collaborate-mode.md           # Collaborate mode (shared state)
│   ├── guest-mode.md                 # Guest mode (unauthenticated -> authorized)
│   ├── breakout-rooms.md             # Breakout room integration
│   └── app-communication.md          # connect + postMessage between instances
│
├── troubleshooting/                   # Problem solving guides
│   ├── common-issues.md              # Quick diagnostics, error codes
│   ├── debugging.md                  # Local dev setup, ngrok, browser preview
│   └── migration.md                  # SDK version migration notes
│
└── references/                        # Reference documentation
    ├── apis.md                        # Complete API reference (100+ methods)
    ├── events.md                      # All SDK events
    ├── layers-api.md                  # Layers API detailed reference
    ├── oauth.md                       # OAuth flows for Zoom Apps
    └── zmail-sdk.md                   # Zoom Mail integration
```

---

## By Use Case

### I want to build a basic Zoom App
1. [Architecture](concepts/architecture.md) - Understand the pattern
2. [Quick Start](examples/quick-start.md) - Build Hello World
3. [In-Client OAuth](examples/in-client-oauth.md) - Add authorization
4. [Security](concepts/security.md) - Required headers

### I want immersive video layouts (Layers API)
1. [Layers Immersive](examples/layers-immersive.md) - Custom video positions
2. [Layers API Reference](references/layers-api.md) - All drawing methods
3. [App Communication](examples/app-communication.md) - Sync layout across participants

### I want a virtual camera overlay
1. [Camera Mode](examples/layers-camera.md) - Camera mode rendering
2. [Layers API Reference](references/layers-api.md) - Drawing methods

### I want real-time collaboration
1. [Collaborate Mode](examples/collaborate-mode.md) - Shared state APIs
2. [App Communication](examples/app-communication.md) - Instance messaging

### I want guest/anonymous access
1. [Guest Mode](examples/guest-mode.md) - Three authorization states
2. [In-Client OAuth](examples/in-client-oauth.md) - promptAuthorize flow

### I want breakout room support
1. [Breakout Rooms](examples/breakout-rooms.md) - Room detection and state sync

### I want to sync between main client and meeting
1. [App Communication](examples/app-communication.md) - connect + postMessage
2. [Running Contexts](concepts/running-contexts.md) - Multi-instance behavior

### I want serverless deployment
1. [Quick Start](examples/quick-start.md) - Understand the base pattern first
2. Sample: [zoomapps-serverless-vuejs](https://github.com/zoom/zoomapps-serverless-vuejs) - Firebase pattern

### I want to add Zoom Mail integration
1. [Zoom Mail Reference](references/zmail-sdk.md) - REST API + mail plugins

### I'm getting errors
1. [Common Issues](troubleshooting/common-issues.md) - Quick diagnostic table
2. [Debugging](troubleshooting/debugging.md) - Local dev setup, DevTools
3. [Migration](troubleshooting/migration.md) - Version compatibility

---

## Most Critical Documents

### 1. Architecture (FOUNDATION)
**[concepts/architecture.md](concepts/architecture.md)**

Understand how Zoom Apps work: Frontend in embedded browser, backend for OAuth/API, SDK as the bridge. Without this, nothing else makes sense.

### 2. Quick Start (FIRST APP)
**[examples/quick-start.md](examples/quick-start.md)**

Complete working code. Get something running before diving into advanced features.

### 3. Common Issues (MOST COMMON PROBLEMS)
**[troubleshooting/common-issues.md](troubleshooting/common-issues.md)**

90% of Zoom Apps issues are: domain allowlist, global variable conflict, or missing capabilities.

---

## Key Learnings

### Critical Discoveries:

1. **Global Variable Conflict is the #1 Gotcha**
   - CDN script defines `window.zoomSdk` globally
   - `let zoomSdk = ...` causes SyntaxError in Zoom's browser
   - Use `let sdk = window.zoomSdk` or NPM import

2. **Domain Allowlist is Non-Negotiable**
   - App shows blank panel with zero error if domain not whitelisted
   - Must include your domain AND `appssdk.zoom.us` AND any CDN domains
   - ngrok URLs change on restart - must update Marketplace each time

3. **config() Gates Everything**
   - Must be called first, must list all capabilities
   - Unlisted capabilities throw errors
   - Check `unsupportedApis` for client version compatibility

4. **In-Client OAuth > Web OAuth for UX**
   - `authorize()` keeps user in Zoom (no browser redirect)
   - Web redirect only needed for initial Marketplace install
   - Always implement PKCE (code_verifier + code_challenge)

5. **Two App Instances Can Run Simultaneously**
   - Main client instance + meeting instance
   - Use `connect()` + `postMessage()` to sync between them
   - Pre-meeting setup in main client, use in meeting

6. **Camera Mode Has CEF Quirks**
   - CEF initialization takes time
   - Draw calls may fail if too early
   - Use retry with exponential backoff

7. **Cookie Settings Matter**
   - `SameSite=None` + `Secure=true` required
   - Without this, sessions silently fail in embedded browser

---

## Quick Reference

### "App shows blank panel"
-> [Domain Allowlist](troubleshooting/common-issues.md) - add domain to Marketplace

### "SyntaxError: redeclaration"
-> [Global Variable](troubleshooting/common-issues.md) - use `let sdk = window.zoomSdk`

### "config() throws error"
-> [Browser Preview](troubleshooting/debugging.md) - SDK only works inside Zoom

### "API call fails silently"
-> [OAuth Scopes](troubleshooting/common-issues.md) - add required scopes in Marketplace

### "How do I implement [feature]?"
-> [API Reference](references/apis.md) - find the method, check capabilities needed

### "How do I test locally?"
-> [Debugging Guide](troubleshooting/debugging.md) - ngrok + Marketplace config

---

## Document Version

Based on **@zoom/appssdk v0.16.x** (latest: 0.16.26+)

---

**Happy coding!**

Start with [Architecture](concepts/architecture.md) to understand the pattern, then [Quick Start](examples/quick-start.md) to build your first app.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/zoom-mcp', 'business', 'zoom-mcp', '', 'zoom-mcp', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom MCP

Guidance for the bundled Zoom MCP connector in this Claude plugin. Prefer `design-mcp-workflow` or [setup-zoom-mcp](../setup-zoom-mcp/SKILL.md) first, then route here for tool-surface details, auth expectations, and MCP-specific constraints.

# Zoom MCP Server

This plugin bundles Zoom's hosted MCP server at `mcp-us.zoom.us` for AI-agent access to:

- semantic meeting search
- meeting-linked asset retrieval
- recording resource retrieval

Zoom Docs are exposed through a separate bundled server:

- `zoom-docs-mcp` at `mcp.zoom.us`
- purpose-built for Zoom Docs creation and retrieval

Current tool names from the main Zoom MCP server:

- `get_meeting_assets`
- `search_meetings`
- `get_recording_resource`
- `recordings_list`

Some MCP clients namespace server tools in the UI, for example `zoom-mcp:recordings_list`.
Treat the raw tool names above as authoritative.

Zoom Docs-specific MCP work should use the dedicated `zoom-docs-mcp` server.

Whiteboard-specific MCP work is covered by the dedicated skill
[whiteboard/SKILL.md](whiteboard/SKILL.md).

## Quick Start

**1. Export the token expected by the bundled connector:**

```bash
export ZOOM_MCP_ACCESS_TOKEN="your_zoom_user_oauth_access_token"
```

**2. Enable or restart the plugin so Claude restarts the bundled MCP server definition.**

**3. Verify discovery:**
- Confirm the client can see `recordings_list`, `search_meetings`, `get_meeting_assets`,
  and `get_recording_resource`.
- If the client exposes raw protocol inspection, `tools/list` is the authoritative discovery source.
- The current catalog is documented in [references/tools.md](references/tools.md).

**4. Run the first useful call:**
```text
recordings_list
  userId: "me"
  from: "2026-03-01"
  to: "2026-03-06"
  page_size: 10
```

## Critical Notes

**1. User OAuth is the documented execution path**

Use a **General app** with **user-level OAuth** as the execution path for Zoom MCP
tool use in this plugin. Do not rely on Server-to-Server OAuth as a supported MCP auth model here.

**2. Zoom MCP uses MCP-specific granular scopes**

The Zoom MCP scope set is not the same as the older broad REST scopes.
The key scopes for the main Zoom MCP server are:
- `ai_companion:read:search` — Search across Zoom Meeting, Zoom Chat, and Zoom Doc, returning the most relevant results based on the query
- `meeting:read:search` — Search and view meetings
- `meeting:read:assets` — View a meeting's assets
- `cloud_recording:read:list_user_recordings` — Lists all cloud recordings for a user.
- `cloud_recording:read:content` — read recording content scope
- `docs:write:import` — Create a new file by import
- `docs:read:export` — Read file content in Markdown format

For Zoom Docs MCP specifically, the official docs page shows these granular scopes for the documented tools:
- `docs:write:import` — Create a new file by import
- `docs:read:export` — Read file content in Markdown format

**3. AI Companion features are feature prerequisites, not scope substitutes**

Semantic meeting search, meeting assets, and recording-content retrieval depend on account
features such as **Smart Recording** and **Meeting Summary** for useful results. These feature
settings do not replace the required OAuth scopes.

**4. Whiteboard is a separate MCP surface**

The Zoom MCP endpoint and the Whiteboard MCP endpoint are separate. Route Whiteboard-specific
requests to [whiteboard/SKILL.md](whiteboard/SKILL.md).

**5. Use REST for deterministic meeting CRUD**

The current Zoom MCP tool surface does not expose deterministic
meeting create, update, or delete tools. If the user needs explicit meeting CRUD operations,
route to [../rest-api/SKILL.md](../rest-api/SKILL.md).

## Server Endpoints

| Transport | URL |
|-----------|-----|
| Streamable HTTP (recommended) | `https://mcp-us.zoom.us/mcp/zoom/streamable` |
| SSE (fallback) | `https://mcp-us.zoom.us/mcp/zoom/sse` |

Dedicated Docs MCP server:

| Transport | URL |
|-----------|-----|
| Streamable HTTP (recommended) | `https://mcp.zoom.us/mcp/docs/streamable` |
| SSE (fallback) | `https://mcp.zoom.us/mcp/docs/sse` |

Dedicated Whiteboard MCP skill:
- [whiteboard/SKILL.md](whiteboard/SKILL.md)

## Search and Retrieval Model

`search_meetings` uses AI Companion retrieval rather than a plain metadata filter. In this
use the live MCP server as authoritative for response schema and scope behavior.

Two result families matter most:

- **Recap-oriented results**: AI summary, meeting-linked documents, recordings, and related assets
- **Recording-oriented results**: cloud recording references and transcript-capable resources

Use [examples/transcript-retrieval.md](examples/transcript-retrieval.md) for the main retrieval
workflow.

## Tool Catalog

| Tool | Key Parameters | Required Scope |
|------|---------------|----------------|
| `get_meeting_assets` | `meetingId`* | `meeting:read:assets` |
| `search_meetings` | `q`, `from`, `to`, `page_size`, `next_page_token` | `meeting:read:search` |
| `get_recording_resource` | `meetingId`*, `types`, `clip_num`, `play_time`, `raw_passcode`, `encode_passcode` | `cloud_recording:read:content` |
| `recordings_list` | `userId`*, `from`, `to`, `meeting_id`, `trash`, `trash_type`, `page_size`, `next_page_token` | `cloud_recording:read:list_user_recordings` |

\* Required parameter

Full parameter and output guidance: [references/tools.md](references/tools.md)

## Key Workflows

**Search meeting content, then retrieve assets:**
```text
search_meetings
  q: "Q4 planning discussion"
  from: "2026-03-01"
  to: "2026-03-06"
→ choose a returned meeting
→ get_meeting_assets  meetingId: "MEETING_ID_OR_UUID"
```

**List recordings, then retrieve recording resources:**
```text
recordings_list
  userId: "me"
  from: "2026-03-01"
  to: "2026-03-06"
→ choose a recording target
→ get_recording_resource  meetingId: "MEETING_UUID_OR_RECORDING_ID"
```

**Create or fetch a Zoom Doc:**
- use the dedicated `zoom-docs-mcp` server rather than the main `zoom-mcp` server
- official documented tools on the Zoom Docs MCP page are:
  - `create_file_with_content`
  - `get_file_content`

## Error Reference

| Code | Meaning | Fix |
|------|---------|-----|
| `401 Unauthorized` | Missing or rejected bearer token at the endpoint | Set `ZOOM_MCP_ACCESS_TOKEN`, then restart Claude or re-enable the plugin |
| `-32001 Invalid access token` | Token expired, malformed, or missing required scopes | Refresh OAuth token and verify the MCP-specific scopes |
| `-32602 Can not found tool` | Requested tool name is not exposed by the active MCP server | Re-run `tools/list` and use the current tool names for that endpoint |
| `404` | Possible downstream resource-not-found response | Re-discover the target with `search_meetings` or `recordings_list` |

Full error reference: [references/error-codes.md](references/error-codes.md)

## Documentation

### Concepts
- [concepts/mcp-architecture.md](concepts/mcp-architecture.md) — MCP protocol, hosted endpoints, discovery, and capability model
- [concepts/oauth-setup.md](concepts/oauth-setup.md) — OAuth app creation, MCP-specific scopes, AI Companion prerequisites, token lifecycle

### Examples
- [examples/transcript-retrieval.md](examples/transcript-retrieval.md) — Search/assets and recording-resource workflows
- [examples/create-zoom-doc.md](examples/create-zoom-doc.md) — Verified Zoom Docs creation flow
- [examples/search-and-act.md](examples/search-and-act.md) — Search, inspect assets, and hand off CRUD work to REST when needed
- [examples/meeting-lifecycle.md](examples/meeting-lifecycle.md) — Why meeting CRUD belongs in REST, plus the MCP-to-REST handoff pattern

### References
- [references/tools.md](references/tools.md) — Current Zoom MCP tool reference
- [references/error-codes.md](references/error-codes.md) — MCP and Zoom API errors with fixes
- [whiteboard/SKILL.md](whiteboard/SKILL.md) — Dedicated Whiteboard MCP skill

### Troubleshooting
- [troubleshooting/common-errors.md](troubleshooting/common-errors.md) — Scope failures, endpoint mixups, search/recording issues

### Operations
- [RUNBOOK.md](RUNBOOK.md) — 5-minute preflight and debugging checklist

## Related Skills

- [zoom-rest-api](../rest-api/SKILL.md) — Deterministic REST API access, including meeting CRUD
- [zoom-oauth](../oauth/SKILL.md) — OAuth implementation patterns
- [zoom-webhooks](../webhooks/SKILL.md) — Event-driven recording and meeting workflows
- [zoom-rtms](../rtms/SKILL.md) — Live media and transcript streams during active meetings$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/zoom-mcp/whiteboard', 'business', 'whiteboard', '', 'whiteboard', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom MCP Whiteboard

Dedicated guidance for Zoom's Whiteboard MCP server.

## Endpoints

| Transport | URL |
|-----------|-----|
| Streamable HTTP (recommended) | `https://mcp-us.zoom.us/mcp/whiteboard/streamable` |
| SSE (fallback) | `https://mcp-us.zoom.us/mcp/whiteboard/sse` |

## Authentication

- **User OAuth with Whiteboard scopes** is the verified working path for `list_whiteboards`
  and `get_a_whiteboard`.
- **S2S OAuth** can reach the Whiteboard MCP gateway and complete `tools/list`, but tool
  execution must be validated separately for your app and Whiteboard scopes.
- Practical rule: start with **user OAuth** for Whiteboard MCP unless you have already
  proven your S2S app can mint and execute with the required Whiteboard scopes.
- The bundled connector expects the token in `ZOOM_WHITEBOARD_MCP_ACCESS_TOKEN`.

Reference: [references/authentication-and-identifiers.md](references/authentication-and-identifiers.md)

## Required Scopes

Whiteboard MCP read scopes:
- `whiteboard:read:list_whiteboards`
- `whiteboard:read:whiteboard`

Write-capable Whiteboard metadata advertised by the gateway:
- `whiteboard:write:whiteboard`

## Whiteboard ID Mapping

For Whiteboard MCP, use the identifier from the URL segment after `/wb/db/`, not the numeric
segment after `/p/`.

Example:

```text
https://us05whiteboard.zoom.us/wb/db/6iktP8hJT3e5qaCuwFuAGg/p/180968285929472
                                     ^^^^^^^^^^^^^^^^^^^^^^   ^^^^^^^^^^^^^^^
                                     whiteboard_id            page/subresource id
```

## Available Tools

The current Whiteboard MCP tool surface is:

- `create_a_whiteboard_for_brainstorming`
- `list_whiteboards`
- `create_a_whiteboard`
- `get_a_whiteboard`
- `create_a_whiteboard_by_script`
- `update_a_whiteboard_metadata`
- `create_a_whiteboard_for_meeting_summary`
- `create_a_whiteboard_for_strategy_analysis`

Some MCP clients namespace server tools in the UI. Treat the raw tool names above as
authoritative.

Reference: [references/tools.md](references/tools.md)

## Read Workflow

1. Use a user OAuth token with the Whiteboard read scopes.
2. Call `list_whiteboards` to discover accessible whiteboards and confirm the correct `whiteboard_id`.
3. Call `get_a_whiteboard` with that `whiteboard_id`.

## Chaining

- Parent MCP skill: [../SKILL.md](../SKILL.md)
- OAuth guidance: [../concepts/oauth-setup.md](../concepts/oauth-setup.md)
- General routing: [../../general/SKILL.md](../../general/SKILL.md)

## References

- [references/authentication-and-identifiers.md](references/authentication-and-identifiers.md) - Auth behavior and Whiteboard ID mapping.
- [references/tools.md](references/tools.md) - Whiteboard MCP tool catalog.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/pdf-viewer/skills/view-pdf', 'business', 'view-pdf', '', 'view-pdf', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# PDF Viewer — Interactive Document Workflows

You have access to a local PDF server that renders documents in a live
viewer and lets you annotate, fill forms, and place signatures with
real-time visual feedback.

## When to use this skill

**Use the PDF viewer when the user wants interactivity:**
- "Show me this contract" / "Open this paper"
- "Highlight the key terms and let me review"
- "Help me fill out this form"
- "Sign this on page 3" / "Add my initials to each page"
- "Stamp this CONFIDENTIAL" / "Mark this as approved"
- "Walk me through this document and annotate the important parts"

**Do NOT use the viewer for pure ingestion:**
- "Summarize this PDF" → use the native Read tool directly
- "What does page 5 say?" → use Read
- "Extract the table from section 3" → use Read

The viewer's value is showing the user the document and collaborating
on markup — not streaming text back to you.

## Tools

### `list_pdfs`
List available local PDFs and allowed local directories. No arguments.

### `display_pdf`
Open a PDF in the interactive viewer. **Call once per document.**
- `url` — local file path or HTTPS URL
- `page` — initial page (optional, default 1)
- `elicit_form_inputs` — if `true`, prompts the user to fill form
  fields before displaying (use for interactive form-filling)

Returns a `viewUUID` — pass this to every `interact` call. Calling
`display_pdf` again creates a **separate** viewer; interact calls with
the new UUID won't reach the one the user is looking at.

Also returns `formFields` (name, type, page, bounding box) if the PDF
has fillable fields — use these coordinates for signature placement.

### `interact`
All follow-up actions after `display_pdf`. Pass `viewUUID` plus one or
more commands. **Batch multiple commands in one call** via the
`commands` array — they run sequentially. End batches with
`get_screenshot` to verify changes visually.

**Annotation actions:**
- `add_annotations` — add markup (see types below)
- `update_annotations` — modify existing (id + type required)
- `remove_annotations` — delete by id array
- `highlight_text` — auto-find text by query and highlight it
  (preferred over manual rects for text markup)

**Navigation actions:**
- `navigate` (page), `search` (query), `find` (query, silent),
  `search_navigate` (matchIndex), `zoom` (scale 0.5–3.0)

**Extraction actions:**
- `get_text` — extract text from page ranges (max 20 pages). Use for
  reading content to decide what to annotate, NOT for summarization.
- `get_screenshot` — capture a page as an image (verify your annotations)

**Form action:**
- `fill_form` — fill named fields: `fields: [{name, value}, ...]`

## Annotation Types

All annotations need `id` (unique string), `type`, `page` (1-indexed).
Coordinates are PDF points (1/72 inch), origin **top-left**, Y increases
downward. US Letter is 612×792pt.

| Type | Key properties | Use for |
|------|----------------|---------|
| `highlight` | `rects`, `color?`, `content?` | Mark important text |
| `underline` | `rects`, `color?` | Emphasize terms |
| `strikethrough` | `rects`, `color?` | Mark deletions |
| `note` | `x`, `y`, `content`, `color?` | Sticky-note comments |
| `freetext` | `x`, `y`, `content`, `fontSize?` | Visible text on page |
| `rectangle` | `x`, `y`, `width`, `height`, `color?`, `fillColor?` | Box regions |
| `circle` | `x`, `y`, `width`, `height`, `color?`, `fillColor?` | Circle regions |
| `line` | `x1`, `y1`, `x2`, `y2`, `color?` | Draw lines/arrows |
| `stamp` | `x`, `y`, `label`, `color?`, `rotation?` | APPROVED, DRAFT, CONFIDENTIAL, etc. |
| `image` | `imageUrl`, `x?`, `y?`, `width?`, `height?` | **Signatures, initials**, logos |

**Image annotations** accept a local file path or HTTPS URL (no data:
URIs). Dimensions auto-detected if omitted. Users can also drag & drop
images directly onto the viewer.

## Interactive Workflows

### Collaborative annotation (AI-driven)
1. `display_pdf` to open the document
2. `interact` → `get_text` on relevant page range to understand content
3. Propose a batch of annotations to the user (describe what you'll mark)
4. On approval, `interact` → `add_annotations` + `get_screenshot`
5. Show the user, ask for edits, iterate
6. When done, remind them they can download the annotated PDF from the
   viewer toolbar

### Form filling (visual, not programmatic)
Unlike headless form tools, this gives the user **live visual
feedback** and handles forms with cryptic/unnamed fields where the
label is printed on the page rather than in field metadata.

1. `display_pdf` — inspect returned `formFields` (name, type, page,
   bounding box)
2. If field names are cryptic (`Text1`, `Field_7`), `get_screenshot`
   the pages and match bounding boxes to visual labels
3. Ask the user for values using the **visual** labels, or infer from
   context
4. `interact` → `fill_form`, then `get_screenshot` to show the result
5. User confirms or edits directly in the viewer

For simple well-labeled forms, `display_pdf` with
`elicit_form_inputs: true` prompts the user upfront instead.

### Signing (visual, not certified)
1. Ask for the signature/initials image path
2. `display_pdf`, check `formFields` for signature-type fields or ask
   which page/position
3. `interact` → `add_annotations` with `type: "image"` at the target
   coordinates
4. `get_screenshot` to confirm placement

**Disclaimer:** This places a visual signature image. It is **not** a
certified or cryptographic digital signature.

## Supported Sources

- Local files (paths under client MCP roots)
- arXiv (`/abs/` URLs auto-convert to PDF)
- Any direct HTTPS PDF URL (bioRxiv, Zenodo, OSF, etc. — use the
  direct PDF link, not the landing page)

## Out of Scope

- **Summarization / text extraction** — use native Read instead
- **Certified digital signatures** — image stamping only
- **PDF creation** — this works on existing PDFs only$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/product-management/skills/competitive-brief', 'business', 'competitive-brief', '', 'competitive-brief', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Competitive Brief

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Create a competitive analysis brief for one or more competitors or a feature area.

## Usage

```
/competitive-brief $ARGUMENTS
```

## Workflow

### 1. Scope the Analysis

Ask the user:
- **Competitor(s)**: Which specific competitor(s) to analyze? Or a feature area to compare across competitors?
- **Focus**: Full product comparison, specific feature area, pricing/packaging, go-to-market, or positioning?
- **Context**: What decision will this inform? (product strategy, sales enablement, investor/board materials, feature prioritization)

### 2. Research

**Via web search**:
- Product pages and feature lists
- Pricing pages and packaging
- Recent product launches, blog posts, and changelogs
- Press coverage and analyst reports
- Customer reviews and ratings (G2, Capterra, TrustRadius)
- Job postings (signal of strategic direction)
- Social media and community discussions

If **~~knowledge base** is connected:
- Search for existing competitive analysis documents
- Find win/loss reports or sales battle cards
- Pull prior competitive research

If **~~chat** is connected:
- Search for competitive mentions in sales or product channels
- Find recent deal feedback involving competitors

### 3. Generate the Brief

#### Competitor Overview
For each competitor:
- Company summary: founding, size, funding/revenue if public, target market
- Product positioning: how they describe themselves, who they target
- Recent momentum: launches, funding, partnerships, customer wins

#### Feature Comparison
Compare capabilities across key areas relevant to the analysis. See **Feature Comparison Matrices** below for rating scales and matrix templates.

#### Positioning Analysis
Analyze how each competitor positions themselves — target customer, category claim, key differentiator, and value proposition. See **Positioning Analysis Frameworks** below for the positioning statement template and message architecture levels.

#### Strengths and Weaknesses
For each competitor:
- **Strengths**: Where they genuinely excel. What customers praise.
- **Weaknesses**: Where they fall short. What customers complain about.
- Be honest and evidence-based — do not dismiss competitors or inflate their weaknesses.

#### Opportunities
Based on the analysis:
- Where are there gaps in competitor offerings we could exploit?
- What are customers asking for that no one provides well?
- Where are competitors making bets we disagree with?
- What market shifts could advantage our approach?

#### Threats
- Where are competitors investing heavily?
- What competitive moves could disrupt our position?
- Where are we most vulnerable?
- What would a "nightmare scenario" competitive move look like?

#### Strategic Implications
Tie the analysis back to product strategy:
- What should we build, accelerate, or deprioritize based on this analysis?
- Where should we differentiate vs. achieve parity?
- How should we adjust positioning or messaging?
- What should we monitor going forward?

### 4. Follow Up

After generating the brief:
- Ask if the user wants to dive deeper on any section
- Offer to create a one-page summary for executives
- Offer to create sales battle cards for competitive deals
- Offer to draft a "how to win against [competitor]" guide
- Offer to set up a monitoring plan for competitive moves

## Competitive Landscape Mapping

### Identifying the Competitive Set
Define competitors at multiple levels:

**Direct competitors**: Products that solve the same problem for the same users in the same way.
- These are the products your customers actively evaluate against you
- They appear in your deals, in customer comparisons, in review site matchups

**Indirect competitors**: Products that solve the same problem but differently.
- Different approach to the same user need (e.g., spreadsheets vs dedicated project management tool)
- Include "non-consumption" — sometimes the competitor is doing nothing or using a manual process

**Adjacent competitors**: Products that do not compete today but could.
- Companies with similar technology, customer base, or distribution that could expand into your space
- Larger platforms that could add your functionality as a feature
- Startups attacking a niche that could grow into your core market

**Substitute solutions**: Entirely different ways users solve the underlying need.
- Hiring a person instead of buying software
- Using a general-purpose tool (Excel, email) instead of a specialized one
- Outsourcing the process entirely

### Landscape Map
Position competitors on meaningful dimensions:

**Common axes**:
- Breadth vs depth (suite vs point solution)
- SMB vs enterprise (market segment focus)
- Self-serve vs sales-led (go-to-market approach)
- Simple vs powerful (product complexity)
- Horizontal vs vertical (general purpose vs industry-specific)

Choose axes that reveal strategic positioning differences relevant to your market. The right axes make competitive dynamics visible.

### Monitoring the Landscape
Track competitive movements over time:
- Product launches and feature releases (changelogs, blog posts, press releases)
- Pricing and packaging changes
- Funding rounds and acquisitions
- Key hires and job postings (signal strategic direction)
- Customer wins and losses (especially your wins/losses)
- Analyst and review coverage
- Partnership announcements

## Feature Comparison Matrices

### Building a Feature Comparison
1. **Define capability areas**: Group features into functional categories that matter to buyers (not your internal architecture). Use the categories buyers use when evaluating.
2. **List specific capabilities**: Under each area, list the specific features or capabilities to compare.
3. **Rate each competitor**: Use a consistent rating scale.

### Rating Scale Options

**Simple (recommended for most cases)**:
- Strong: Market-leading capability. Deep functionality, well-executed.
- Adequate: Functional capability. Gets the job done but not differentiated.
- Weak: Exists but limited. Significant gaps or poor execution.
- Absent: Does not have this capability.

**Detailed (for deep-dive comparisons)**:
- 5: Best-in-class. Defines the standard others aspire to.
- 4: Strong. Fully-featured and well-executed.
- 3: Adequate. Meets basic needs without differentiation.
- 2: Limited. Exists but with significant gaps.
- 1: Minimal. Barely functional or in early beta.
- 0: Absent. Not available.

### Comparison Matrix Template
```
| Capability Area | Our Product | Competitor A | Competitor B |
|----------------|-------------|-------------|-------------|
| [Area 1]       |             |             |             |
|   [Feature 1]  | Strong      | Adequate    | Absent      |
|   [Feature 2]  | Adequate    | Strong      | Weak        |
| [Area 2]       |             |             |             |
|   [Feature 3]  | Strong      | Strong      | Adequate    |
```

### Tips for Feature Comparison
- Rate based on real product experience, customer feedback, and reviews — not just marketing claims
- Features exist on a spectrum. "Has feature X" is less useful than "How well does it do X?"
- Weight the comparison by what matters to your target customers, not by total feature count
- Update regularly — feature comparisons get stale fast
- Be honest about where competitors are ahead. A comparison that always shows you winning is not credible.
- Include the "why it matters" for each capability area. Not all features matter equally to buyers.

## Positioning Analysis Frameworks

### Positioning Statement Analysis
For each competitor, extract their positioning:

**Template**: For [target customer] who [need/problem], [Product] is a [category] that [key benefit]. Unlike [competitor/alternative], [Product] [key differentiator].

**Sources for positioning**:
- Homepage headline and subheadline
- Product description on app stores or review sites
- Sales pitch decks (sometimes leaked or shared by prospects)
- Analyst briefing materials
- Earnings call language (for public companies)

### Message Architecture Analysis
How does each competitor communicate value?

**Level 1 — Category**: What category do they claim? (CRM, project management, collaboration platform)
**Level 2 — Differentiator**: What makes them different within that category? (AI-powered, all-in-one, developer-first)
**Level 3 — Value Proposition**: What outcome do they promise? (Close deals faster, ship products faster, never miss a deadline)
**Level 4 — Proof Points**: What evidence do they provide? (Customer logos, metrics, awards, case studies)

### Positioning Gaps and Opportunities
Look for:
- **Unclaimed positions**: Value propositions no competitor owns that matter to buyers
- **Crowded positions**: Claims every competitor makes that have lost meaning
- **Emerging positions**: New value propositions driven by market changes (AI, remote work, compliance)
- **Vulnerable positions**: Claims competitors make that they cannot fully deliver on

## Win/Loss Analysis Methodology

### Conducting Win/Loss Analysis
Win/loss analysis reveals why you actually win and lose deals. It is the most actionable competitive intelligence.

**Data sources**:
- CRM notes from sales team (available immediately, but biased)
- Customer interviews shortly after decision (most valuable, least biased)
- Churned customer surveys or exit interviews
- Prospect surveys (for lost deals)

### Win/Loss Interview Questions
For wins:
- What problem were you trying to solve?
- What alternatives did you evaluate? (Reveals competitive set)
- Why did you choose us over alternatives?
- What almost made you choose someone else?
- What would we need to lose for you to reconsider?

For losses:
- What problem were you trying to solve?
- What did you end up choosing? Why?
- Where did our product fall short?
- What could we have done differently?
- Would you reconsider us in the future? Under what conditions?

### Analyzing Win/Loss Data
- Track win/loss reasons over time. Are patterns changing?
- Segment by deal type: enterprise vs SMB, new vs expansion, industry vertical
- Identify the top 3-5 reasons for wins and losses
- Distinguish between product reasons (features, quality) and non-product reasons (pricing, brand, relationship, timing)
- Calculate competitive win rates by competitor: what % of deals involving each competitor do you win?

### Common Win/Loss Patterns
- **Feature gap**: Competitor has a specific capability you lack that is a dealbreaker
- **Integration advantage**: Competitor integrates with tools the buyer already uses
- **Pricing structure**: Not always cheaper — sometimes different pricing model (per-seat vs usage-based) fits better
- **Incumbent advantage**: Buyer sticks with what they have because switching cost is too high
- **Sales execution**: Better demo, faster response, more relevant case studies
- **Brand/trust**: Buyer chooses the safer or more well-known option

## Market Trend Identification

### Sources for Trend Identification
- **Industry analyst reports**: Gartner, Forrester, IDC for market sizing and trends
- **Venture capital**: What are VCs funding? Investment themes signal where smart money sees opportunity.
- **Conference themes**: What are industry events focusing on? What topics draw the biggest audiences?
- **Technology shifts**: New platforms, APIs, or capabilities that enable new product categories
- **Regulatory changes**: New regulations that create requirements or opportunities
- **Customer behavior changes**: How are user expectations evolving? (e.g., mobile-first, AI-assisted, privacy-conscious)
- **Talent movement**: Where are top people going? What skills are in demand?

### Trend Analysis Framework
For each trend identified:

1. **What is changing?**: Describe the trend clearly and specifically
2. **Why now?**: What is driving this change? (Technology, regulation, behavior, economics)
3. **Who is affected?**: Which customer segments or market categories?
4. **What is the timeline?**: Is this happening now, in 1-2 years, or 3-5 years?
5. **What is the implication for us?**: How should this influence our product strategy?
6. **What are competitors doing?**: How are competitors responding to this trend?

### Separating Signal from Noise
- **Signals**: Trends backed by behavioral data, growing investment, regulatory action, or customer demand
- **Noise**: Trends backed only by media hype, conference buzz, or competitor announcements without customer traction
- Test trends against your own customer data: are YOUR customers asking for this or experiencing this change?
- Be wary of "trend of the year" hype cycles. Many trends that dominate industry conversation do not materially affect your customers for years.

### Strategic Response Options
For each significant trend:
- **Lead**: Invest early and try to define the category or approach. High risk, high reward.
- **Fast follow**: Wait for early signals of customer demand, then move quickly. Lower risk but harder to differentiate.
- **Monitor**: Track the trend but do not invest yet. Set triggers for when to act.
- **Ignore**: Explicitly decide this trend is not relevant to your strategy. Document why.

The right response depends on: your competitive position, your customer base, your resources, and how fast the trend is moving.

## Output Format

Use tables for feature comparisons. Use clear headers for each section. Keep the strategic implications section concise and actionable — this is where the value is for the reader.

## Tips

- Be honest about competitor strengths. Dismissing competitors makes the analysis useless.
- Focus on what matters to customers, not what matters to product teams. Customers do not care about architecture elegance.
- Pricing is hard to compare fairly. Note the caveats (different packaging, usage-based vs seat-based, enterprise custom pricing).
- Job postings are underrated competitive intelligence. A competitor hiring ML engineers signals a strategic direction.
- Customer reviews are gold. They reveal what real users love and hate, unfiltered by marketing.
- The most valuable part of competitive analysis is the "so what" — the strategic implications. Do not skip this.
- Competitive analysis has a shelf life. Note the date and flag areas that change quickly.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/product-management/skills/metrics-review', 'business', 'metrics-review', '', 'metrics-review', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Metrics Review

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Review and analyze product metrics, identify trends, and surface actionable insights.

## Usage

```
/metrics-review $ARGUMENTS
```

## Workflow

### 1. Gather Metrics Data

If **~~product analytics** is connected:
- Pull key product metrics for the relevant time period
- Get comparison data (previous period, same period last year, targets)
- Pull segment breakdowns if available

If no analytics tool is connected, ask the user to provide:
- The metrics and their values (paste a table, screenshot, or describe)
- Comparison data (previous period, targets)
- Any context on recent changes (launches, incidents, seasonality)

Ask the user:
- What time period to review? (last week, last month, last quarter)
- What metrics to focus on? Or should we review the full product metrics suite?
- Are there specific targets or goals to compare against?
- Any known events that might explain changes (launches, outages, marketing campaigns, seasonality)?

### 2. Organize the Metrics

Structure the review using a metrics hierarchy: North Star metric at the top, L1 health indicators (acquisition, activation, engagement, retention, revenue, satisfaction), and L2 diagnostic metrics for drill-down. See **Product Metrics Hierarchy** below for full definitions.

If the user has not defined their metrics hierarchy, help them identify their North Star and key L1 metrics before proceeding.

### 3. Analyze Trends

For each key metric:
- **Current value**: What is the metric today?
- **Trend**: Up, down, or flat compared to previous period? Over what timeframe?
- **vs Target**: How does it compare to the goal or target?
- **Rate of change**: Is the trend accelerating or decelerating?
- **Anomalies**: Any sudden changes, spikes, or drops?

Identify correlations:
- Do changes in one metric correlate with changes in another?
- Are there leading indicators that predict lagging metric changes?
- Do segment breakdowns reveal that an aggregate trend is driven by a specific cohort?

### 4. Generate the Review

#### Summary
2-3 sentences: overall product health, most notable changes, key callout.

#### Metric Scorecard
Table format for quick scanning:

| Metric | Current | Previous | Change | Target | Status |
|--------|---------|----------|--------|--------|--------|
| [Metric] | [Value] | [Value] | [+/- %] | [Target] | [On track / At risk / Miss] |

#### Trend Analysis
For each metric worth discussing:
- What happened and how significant is the change
- Why it likely happened (attribution based on known events, correlated metrics, segment analysis)
- Whether this is a one-time event or a sustained trend

#### Bright Spots
What is going well:
- Metrics beating targets
- Positive trends to sustain
- Segments or features showing strong performance

#### Areas of Concern
What needs attention:
- Metrics missing targets or trending negatively
- Early warning signals before they become problems
- Metrics where we lack visibility or understanding

#### Recommended Actions
Specific next steps based on the analysis:
- Investigations to run (dig deeper into a concerning trend)
- Experiments to launch (test hypotheses about what could improve a metric)
- Investments to make (double down on what is working)
- Alerts to set (monitor a metric more closely)

#### Context and Caveats
- Known data quality issues
- Events that affect comparability (outages, holidays, launches)
- Metrics we should be tracking but are not yet

### 5. Follow Up

After generating the review:
- Ask if any metric needs deeper investigation
- Offer to create a dashboard spec for ongoing monitoring
- Offer to draft experiment proposals for areas of concern
- Offer to set up a metrics review template for recurring use

## Product Metrics Hierarchy

### North Star Metric
The single metric that best captures the core value your product delivers to users. It should be:

- **Value-aligned**: Moves when users get more value from the product
- **Leading**: Predicts long-term business success (revenue, retention)
- **Actionable**: The product team can influence it through their work
- **Understandable**: Everyone in the company can understand what it means and why it matters

**Examples by product type**:
- Collaboration tool: Weekly active teams with 3+ members contributing
- Marketplace: Weekly transactions completed
- SaaS platform: Weekly active users completing core workflow
- Content platform: Weekly engaged reading/viewing time
- Developer tool: Weekly deployments using the tool

### L1 Metrics (Health Indicators)
The 5-7 metrics that together paint a complete picture of product health. These map to the key stages of the user lifecycle:

**Acquisition**: Are new users finding the product?
- New signups or trial starts (volume and trend)
- Signup conversion rate (visitors to signups)
- Channel mix (where are new users coming from)
- Cost per acquisition (for paid channels)

**Activation**: Are new users reaching the value moment?
- Activation rate: % of new users who complete the key action that predicts retention
- Time to activate: how long from signup to activation
- Setup completion rate: % who complete onboarding steps
- First value moment: when users first experience the core product value

**Engagement**: Are active users getting value?
- DAU / WAU / MAU: active users at different timeframes
- DAU/MAU ratio (stickiness): what fraction of monthly users come back daily
- Core action frequency: how often users do the thing that matters most
- Session depth: how much users do per session
- Feature adoption: % of users using key features

**Retention**: Are users coming back?
- D1, D7, D30 retention: % of users who return after 1 day, 7 days, 30 days
- Cohort retention curves: how retention evolves for each signup cohort
- Churn rate: % of users or revenue lost per period
- Resurrection rate: % of churned users who come back

**Monetization**: Is value translating to revenue?
- Conversion rate: free to paid (for freemium)
- MRR / ARR: monthly or annual recurring revenue
- ARPU / ARPA: average revenue per user or account
- Expansion revenue: revenue growth from existing customers
- Net revenue retention: revenue retention including expansion and contraction

**Satisfaction**: How do users feel about the product?
- NPS: Net Promoter Score
- CSAT: Customer Satisfaction Score
- Support ticket volume and resolution time
- App store ratings and review sentiment

### L2 Metrics (Diagnostic)
Detailed metrics used to investigate changes in L1 metrics:

- Funnel conversion at each step
- Feature-level usage and adoption
- Segment-specific breakdowns (by plan, company size, geography, user role)
- Performance metrics (page load time, error rate, API latency)
- Content-specific engagement (which features, pages, or content types drive engagement)

## Common Product Metrics

### DAU / WAU / MAU
**What they measure**: Unique users who perform a qualifying action in a day, week, or month.

**Key decisions**:
- What counts as "active"? A login? A page view? A core action? Define this carefully — different definitions tell different stories.
- Which timeframe matters most? DAU for daily-use products (messaging, email). WAU for weekly-use products (project management). MAU for less frequent products (tax software, travel booking).

**How to use them**:
- DAU/MAU ratio (stickiness): values above 0.5 indicate a daily habit. Below 0.2 suggests infrequent usage.
- Trend matters more than absolute number. Is active usage growing, flat, or declining?
- Segment by user type. Power users and casual users behave very differently.

### Retention
**What it measures**: Of users who started in period X, what % are still active in period Y?

**Common retention timeframes**:
- D1 (next day): Was the first experience good enough to come back?
- D7 (one week): Did the user establish a habit?
- D30 (one month): Is the user retained long-term?
- D90 (three months): Is this a durable user?

**How to use retention**:
- Plot retention curves by cohort. Look for: initial drop-off (activation problem), steady decline (engagement problem), or flattening (good — you have a stable retained base).
- Compare cohorts over time. Are newer cohorts retaining better than older ones? That means product improvements are working.
- Segment retention by activation behavior. Users who completed onboarding vs those who did not. Users who used feature X vs those who did not.

### Conversion
**What it measures**: % of users who move from one stage to the next.

**Common conversion funnels**:
- Visitor to signup
- Signup to activation (key value moment)
- Free to paid (trial conversion)
- Trial to paid subscription
- Monthly to annual plan

**How to use conversion**:
- Map the full funnel and measure conversion at each step
- Identify the biggest drop-off points — these are your highest-leverage improvement opportunities
- Segment conversion by source, plan, user type. Different segments convert very differently.
- Track conversion over time. Is it improving as you iterate on the experience?

### Activation
**What it measures**: % of new users who reach the moment where they first experience the product's core value.

**Defining activation**:
- Look at retained users vs churned users. What actions did retained users take that churned users did not?
- The activation event should be strongly predictive of long-term retention
- It should be achievable within the first session or first few days
- Examples: created first project, invited a teammate, completed first workflow, connected an integration

**How to use activation**:
- Track activation rate for every signup cohort
- Measure time to activate — faster is almost always better
- Build onboarding flows that guide users to the activation moment
- A/B test activation flows and measure impact on retention, not just activation rate

## Goal Setting Frameworks

### OKRs (Objectives and Key Results)

**Objectives**: Qualitative, aspirational goals that describe what you want to achieve.
- Inspiring and memorable
- Time-bound (quarterly or annually)
- Directional, not metric-specific

**Key Results**: Quantitative measures that tell you if you achieved the objective.
- Specific and measurable
- Time-bound with a clear target
- Outcome-based, not output-based
- 2-4 Key Results per Objective

**Example**:
```
Objective: Make our product indispensable for daily workflows

Key Results:
- Increase DAU/MAU ratio from 0.35 to 0.50
- Increase D30 retention for new users from 40% to 55%
- 3 core workflows with >80% task completion rate
```

### OKR Best Practices
- Set OKRs that are ambitious but achievable. 70% completion is the target for stretch OKRs.
- Key Results should measure outcomes (user behavior, business results), not outputs (features shipped, tasks completed).
- Do not have too many OKRs. 2-3 objectives with 2-4 KRs each is plenty.
- OKRs should be uncomfortable. If you are confident you will hit all of them, they are not ambitious enough.
- Review OKRs at mid-period. Adjust effort allocation if some KRs are clearly off track.
- Grade OKRs honestly at end of period. 0.0-0.3 = missed, 0.4-0.6 = progress, 0.7-1.0 = achieved.

### Setting Metric Targets
- **Baseline**: What is the current value? You need a reliable baseline before setting a target.
- **Benchmark**: What do comparable products achieve? Industry benchmarks provide context.
- **Trajectory**: What is the current trend? If the metric is already improving at 5% per month, a 6% target is not ambitious.
- **Effort**: How much investment are you putting behind this? Bigger bets warrant more ambitious targets.
- **Confidence**: How confident are you in hitting the target? Set a "commit" (high confidence) and a "stretch" (ambitious).

## Metric Review Cadences

### Weekly Metrics Check
**Purpose**: Catch issues quickly, monitor experiments, stay in touch with product health.
**Duration**: 15-30 minutes.
**Attendees**: Product manager, maybe engineering lead.

**What to review**:
- North Star metric: current value, week-over-week change
- Key L1 metrics: any notable movements
- Active experiments: results and statistical significance
- Anomalies: any unexpected spikes or drops
- Alerts: anything that triggered a monitoring alert

**Action**: If something looks off, investigate. Otherwise, note it and move on.

### Monthly Metrics Review
**Purpose**: Deeper analysis of trends, progress against goals, strategic implications.
**Duration**: 30-60 minutes.
**Attendees**: Product team, key stakeholders.

**What to review**:
- Full L1 metric scorecard with month-over-month trends
- Progress against quarterly OKR targets
- Cohort analysis: are newer cohorts performing better?
- Feature adoption: how are recent launches performing?
- Segment analysis: any divergence between user segments?

**Action**: Identify 1-3 areas to investigate or invest in. Update priorities if metrics reveal new information.

### Quarterly Business Review
**Purpose**: Strategic assessment of product performance, goal-setting for next quarter.
**Duration**: 60-90 minutes.
**Attendees**: Product, engineering, design, leadership.

**What to review**:
- OKR scoring for the quarter
- Trend analysis for all L1 metrics over the quarter
- Year-over-year comparisons
- Competitive context: market changes and competitor movements
- What worked and what did not

**Action**: Set OKRs for next quarter. Adjust product strategy based on what the data shows.

## Dashboard Design Principles

### Effective Product Dashboards
A good dashboard answers the question "How is the product doing?" at a glance.

**Principles**:

1. **Start with the question, not the data**. What decisions does this dashboard support? Design backwards from the decision.

2. **Hierarchy of information**. The most important metric should be the most visually prominent. North Star at the top, L1 metrics next, L2 metrics available on drill-down.

3. **Context over numbers**. A number without context is meaningless. Always show: current value, comparison (previous period, target, benchmark), trend direction.

4. **Fewer metrics, more insight**. A dashboard with 50 metrics helps no one. Focus on 5-10 that matter. Put everything else in a detailed report.

5. **Consistent time periods**. Use the same time period for all metrics on a dashboard. Mixing daily and monthly metrics creates confusion.

6. **Visual status indicators**. Use color to indicate health at a glance:
   - Green: on track or improving
   - Yellow: needs attention or flat
   - Red: off track or declining

7. **Actionability**. Every metric on the dashboard should be something the team can influence. If you cannot act on it, it does not belong on the product dashboard.

### Dashboard Layout

**Top row**: North Star metric with trend line and target.

**Second row**: L1 metrics scorecard — current value, change, target, status for each key metric.

**Third row**: Key funnels or conversion metrics — visual funnel showing drop-off at each stage.

**Fourth row**: Recent experiments and launches — active A/B tests, recent feature launches with early metrics.

**Bottom / drill-down**: L2 metrics, segment breakdowns, and detailed time series for investigation.

### Dashboard Anti-Patterns
- **Vanity metrics**: Metrics that always go up but do not indicate health (total signups ever, total page views)
- **Too many metrics**: Dashboards that require scrolling to see. If it does not fit on one screen, cut metrics.
- **No comparison**: Raw numbers without context (current value with no previous period or target)
- **Stale dashboards**: Metrics that have not been updated or reviewed in months
- **Output dashboards**: Measuring team activity (tickets closed, PRs merged) instead of user and business outcomes
- **One dashboard for all audiences**: Executives, PMs, and engineers need different views. One size does not fit all.

### Alerting
Set alerts for metrics that require immediate attention:

- **Threshold alerts**: Metric drops below or rises above a critical threshold (error rate > 1%, conversion < 5%)
- **Trend alerts**: Metric shows sustained decline over multiple days/weeks
- **Anomaly alerts**: Metric deviates significantly from expected range

**Alert hygiene**:
- Every alert should be actionable. If you cannot do anything about it, do not alert on it.
- Review and tune alerts regularly. Too many false positives and people ignore all alerts.
- Define an owner for each alert. Who responds when it fires?
- Set appropriate severity levels. Not everything is P0.

## Output Format

Use tables for the scorecard. Use clear status indicators. Keep the summary tight — the reader should get the essential story in 30 seconds.

## Tips

- Start with the "so what" — what is the most important thing in this metrics review? Lead with that.
- Absolute numbers without context are useless. Always show comparisons (vs previous period, vs target, vs benchmark).
- Be careful about attribution. Correlation is not causation. If a metric moved, acknowledge uncertainty about why.
- Segment analysis often reveals that an aggregate metric masks important differences. A flat overall number might hide one segment growing and another shrinking.
- Not all metric movements matter. Small fluctuations are noise. Focus attention on meaningful changes.
- If a metric is missing its target, do not just report the miss — recommend what to do about it.
- Metrics reviews should drive decisions. If the review does not lead to at least one action, it was not useful.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/product-management/skills/product-brainstorming', 'business', 'product-brainstorming', '', 'product-brainstorming', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Product Brainstorming Skill

You are a sharp product thinking partner — the kind of experienced PM or design lead who challenges assumptions, asks the hard questions, and pushes ideas further before anyone converges too early. You help product managers explore problem spaces, generate ideas, and stress-test thinking before it becomes a spec.

Your job is not to generate deliverables. Your job is to think alongside the PM. Be opinionated. Push back. Bring in unexpected angles. Help them arrive at ideas they would not have reached alone.

## Brainstorming Modes

Different situations call for different modes of thinking. Identify which mode fits the conversation and adapt. You can shift between modes as the conversation evolves.

### Problem Exploration

Use when the PM has a problem area but has not yet defined what to solve. The goal is to understand the problem space deeply before jumping to solutions.

**What to do:**
- Ask "who has this problem?" and "what are they doing about it today?" before anything else
- Map the problem ecosystem: who is involved, what triggers the problem, what are the consequences of not solving it
- Distinguish symptoms from root causes. PMs often describe symptoms. Keep asking "why" until you hit something structural.
- Surface adjacent problems the PM might not have considered
- Ask how the problem varies across user segments — it rarely affects everyone the same way

**Useful questions:**
- "What happens if we do nothing? Who suffers and how?"
- "Who has solved a version of this problem in a different context?"
- "Is this a problem of awareness, ability, or motivation?"
- "What would need to be true for this problem to not exist?"

### Solution Ideation

Use when the problem is well-defined and the PM needs to generate multiple possible solutions. The goal is divergent thinking — quantity over quality.

**What to do:**
- Generate at least 5-7 distinct approaches before evaluating any of them
- Vary the solutions along meaningful dimensions: scope (small tweak vs big bet), approach (product vs process vs policy), timing (quick win vs long-term investment)
- Include at least one "what if we did the opposite?" option
- Include at least one option that removes something rather than adding something
- Resist the urge to converge too early. If the PM latches onto the first decent idea, push them to keep going.

**Ideation techniques:**
- **Constraint removal**: "What would you build if you had no technical constraints? No budget constraints? No political constraints?" Then work backward to what is feasible.
- **Analogies**: "How does [another industry] solve this? What can we steal from that approach?"
- **Inversion**: "How would we make this problem worse? Now reverse each of those."
- **Decomposition**: Break the problem into subproblems and solve each independently. Then combine.
- **User hat-switching**: "How would a power user solve this? A brand new user? An admin? Someone who hates our product?"

### Assumption Testing

Use when the PM has an idea or direction and needs to stress-test it. The goal is to find the weak points before investing in execution.

**What to do:**
- List every assumption the idea depends on — stated and unstated
- For each assumption, ask: "How confident are we? What evidence do we have? What would disprove this?"
- Identify the riskiest assumption — the one that, if wrong, kills the idea entirely
- Suggest the cheapest way to test the riskiest assumption before building anything
- Play devil's advocate: argue the strongest possible case against the idea

**Assumption categories to probe:**
- **User assumptions**: "Users want this" — How do we know? From what evidence? How many users?
- **Problem assumptions**: "This is a real problem" — How often does it occur? How much do users care?
- **Solution assumptions**: "This solution will work" — Why this approach? What alternatives did we dismiss?
- **Business assumptions**: "This will move the metric" — Which metric? By how much? Over what timeline?
- **Feasibility assumptions**: "We can build this" — In what timeframe? With what trade-offs?
- **Adoption assumptions**: "Users will find and use this" — How? What behavior change does it require?

### Strategy Exploration

Use when the PM is thinking about direction, positioning, or big bets — not a specific feature. The goal is to explore the strategic landscape.

**What to do:**
- Map the playing field: what are the possible strategic moves, not just the obvious one
- Think in terms of bets: what are we betting on, what are the odds, what is the payoff
- Consider second-order effects: "If we do X, what does that enable or foreclose?"
- Bring in competitive dynamics: "If we do this, how do competitors respond?"
- Think in timeframes: "What is the right move for 3 months vs 12 months vs 3 years?"

## Brainstorming Frameworks

Use frameworks as thinking tools, not templates to fill in. Pull in a framework when it helps move the conversation forward. Do not force every conversation through every framework.

### How Might We (HMW)

Reframe problems as opportunities. Turn a pain point into an actionable question.

**Structure**: "How might we [desired outcome] for [user] without [constraint]?"

**Tips:**
- Too broad: "How might we improve onboarding?" — could mean anything
- Too narrow: "How might we add a tooltip to step 3?" — that is a solution, not a question
- Right level: "How might we help new users reach their first success within 10 minutes?"
- Generate 5-10 HMW questions from a single problem statement. Each reframing opens different solution spaces.

### Jobs-to-be-Done (JTBD)

Think from the user's job, not from features or demographics.

**Structure**: "When [situation], I want to [motivation] so I can [expected outcome]."

**Tips:**
- The job is stable even when solutions change. People have been "hiring" solutions to share updates with colleagues for decades — memos, email, Slack, shared docs.
- Functional jobs (get something done) are easier to identify. Emotional jobs (feel confident, look competent) and social jobs (be seen as a leader) are often more powerful.
- Ask "What did they fire to hire your product?" — this reveals the real competitive set.

### Opportunity Solution Trees

Map the path from outcome to experiment.

```
Desired Outcome
├── Opportunity A (user need / pain point)
│   ├── Solution A1
│   │   ├── Experiment: ...
│   │   └── Experiment: ...
│   └── Solution A2
│       └── Experiment: ...
├── Opportunity B
│   ├── Solution B1
│   └── Solution B2
└── Opportunity C
    └── Solution C1
```

**Tips:**
- Opportunities come from research, not imagination. Every opportunity should trace back to evidence.
- Multiple solutions per opportunity. If you only have one solution, you have not explored enough.
- Multiple experiments per solution. Find the cheapest way to test before building.
- The tree is a living artifact. Update it as you learn.

### First Principles Decomposition

Break a complex problem down to its fundamental truths and rebuild.

1. **State the problem or assumption** you want to examine
2. **Break it down**: What are the fundamental components or constraints?
3. **Question each component**: Why does this have to be this way? Is this a law of physics or a convention?
4. **Rebuild from the ground up**: Given only the fundamental truths, what solutions are possible?

**When to use**: When the team is stuck in incremental thinking. When everyone says "that is just how it works." When the category has not been reimagined in years.

### SCAMPER

Systematic ideation using seven lenses on an existing product or process:

- **Substitute**: What component could be replaced? What if a different user did this step?
- **Combine**: What if we merged two features? Two workflows? Two user roles?
- **Adapt**: What idea from another product or industry could we borrow?
- **Modify**: What if we made this 10x bigger? 10x smaller? 10x faster?
- **Put to other use**: Could this feature serve a different user or use case?
- **Eliminate**: What if we removed this entirely? Would anyone notice?
- **Reverse**: What if we did the opposite? Flipped the sequence? Inverted the default?

### OODA Loop (Observe–Orient–Decide–Act)

A decision-tempo framework from military strategy that excels in fast-moving, competitive product environments. The power of OODA is not in the steps — it is in cycling through them faster than the competition.

1. **Observe**: Gather raw signals — usage data, customer feedback, competitive moves, market shifts, support tickets. Do not filter yet. Cast wide.
2. **Orient**: Make sense of what you observed. This is the critical step. Orient through the lens of your mental models, prior experience, and cultural context. Challenge your own orientation — are you seeing what is actually there, or what you expect to see?
3. **Decide**: Choose a direction. Not a final commitment — a hypothesis to test. The decision should be proportional to what you know. Small bets when uncertain, bigger moves when the signal is clear.
4. **Act**: Execute the decision. Ship something. Run the experiment. Make the change. Then immediately return to Observe with new data.

**When to use in brainstorming:**
- When the team is over-deliberating and needs to move. OODA favors tempo over perfection.
- When competitive dynamics matter — a competitor just shipped something, a market window is closing, a customer is about to churn.
- When the brainstorm keeps circling without converging. OODA forces a decision and reframes it as reversible: act, observe new data, re-orient.
- When exploring strategy: "Given what we are observing in the market, how should we re-orient our product thinking?"

**The OODA advantage in product:** Most product teams get stuck in Orient — endlessly analyzing, debating frameworks, waiting for more data. OODA says: orient with what you have, decide, act, and let the next observation cycle correct your course. The team that cycles fastest learns fastest.

### Reverse Brainstorming

When stuck on how to solve a problem, brainstorm how to make it worse.

1. **Invert the problem**: "How could we make onboarding as confusing as possible?"
2. **Generate ideas**: List everything that would make the problem worse (more steps, jargon, hidden buttons, no feedback)
3. **Reverse each idea**: Each "make it worse" idea contains the seed of a "make it better" solution
4. **Evaluate**: Which reversed ideas are most promising?

**Why it works**: People are better at identifying what is wrong than imagining what is right. Inversion unlocks creative thinking when the team is stuck.

## Session Structure

A good brainstorming session has rhythm — it opens up before it narrows down.

### 1. Frame

Set boundaries before generating ideas. Good framing prevents wasted divergence.

- What are we exploring? (A specific problem, an opportunity area, a strategic question)
- Why now? (What triggered this brainstorm?)
- What do we already know? (Prior research, data, customer feedback)
- What are the constraints? (Timeline, technical, business, team)
- What would a great outcome from this session look like?

Spend enough time framing. A poorly framed brainstorm produces ideas that do not connect to real needs.

### 2. Diverge

Generate many ideas. No judgment. Quantity enables quality.

- Build on ideas rather than shooting them down
- Follow tangents — the best ideas often come from unexpected connections
- Push past the obvious. The first 3-5 ideas are usually the ones everyone would have thought of. Keep going.
- Ask provocative questions to unlock new directions
- Use frameworks (above) to systematically explore different angles

### 3. Provoke

Challenge and extend thinking. This is where the sparring partner role matters most.

- "What is the strongest argument against this?"
- "Who would hate this and why?"
- "What are we not seeing?"
- "What would [specific company or person] do differently?"
- "What if the opposite were true?"
- "What is the version of this that is 10x more ambitious?"

### 4. Converge

Narrow down. Evaluate ideas against what matters.

- Group related ideas into themes
- Evaluate against: user impact, feasibility, strategic alignment, evidence strength
- Do not kill ideas by committee. If one idea excites the PM, explore it — even if it is risky. The brainstorm is not the decision.
- Identify the top 2-3 ideas worth pursuing further
- For each, name the biggest unknown and the cheapest way to resolve it

### 5. Capture

Document what matters. A brainstorm with no capture is a brainstorm that never happened.

- Key ideas and why they are interesting
- Assumptions to test
- Questions to research
- Suggested next steps (research, prototype, talk to users, write a one-pager)
- What was explicitly set aside — ideas that were interesting but not for now

## Being a Good Thinking Partner

### Do

- **Be opinionated.** "I think approach B is stronger because..." is more useful than listing pros and cons.
- **Challenge constructively.** "That assumes X — are we confident?" not "That will not work."
- **Bring unexpected angles.** Cross-industry analogies, counterexamples, edge cases the PM has not considered.
- **Match energy.** If the PM is excited about an idea, explore it with them before poking holes.
- **Ask the next question.** When the PM finishes a thought, do not just agree. Push further: "And then what happens?"
- **Name the pattern.** If you recognize a common PM trap (solutioning too early, scope creep, feature parity thinking), name it directly.

### Do Not

- **Do not dump frameworks.** Use frameworks as thinking tools when they help, not as a checklist to work through.
- **Do not generate a list and hand it over.** Brainstorming is a conversation, not a deliverable.
- **Do not agree with everything.** A thinking partner who only validates is not a thinking partner.
- **Do not optimize prematurely.** In divergent mode, do not evaluate feasibility. That kills creative thinking.
- **Do not anchor on the first idea.** If the PM leads with a solution, acknowledge it, then ask "What else could solve this?"
- **Do not confuse brainstorming with decision-making.** The brainstorm generates options. The decision comes later with more data.

## Common Brainstorming Anti-Patterns

**Solutioning before framing**: The PM jumps to "we should build X" before defining the problem. Slow them down. Ask what user problem X solves and how we know.

**The feature parity trap**: "Competitor has X, so we need X." This is not brainstorming — it is copying. Ask what user need X serves and whether there is a better way to serve it.

**Anchoring on constraints**: "We cannot do that because of technical limitation Y." In divergent mode, set constraints aside. Explore freely first, then figure out feasibility.

**The one-idea brainstorm**: The PM comes in with a solution and calls it brainstorming. Acknowledge their idea, then push for alternatives. "That is one approach. What are three others?"

**Analysis paralysis**: Too much exploration, no convergence. If the session has been divergent for a while, prompt: "If you had to pick one direction right now, which would it be and why?"

**Brainstorming when you should be researching**: Some questions cannot be brainstormed — they need data. If the brainstorm keeps circling because no one knows the answer, stop and identify what research is needed.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/product-management/skills/roadmap-update', 'business', 'roadmap-update', '', 'roadmap-update', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Roadmap Update

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Update, create, or reprioritize a product roadmap.

## Usage

```
/roadmap-update $ARGUMENTS
```

## Workflow

### 1. Understand Current State

If **~~project tracker** is connected:
- Pull current roadmap items with their statuses, assignees, and dates
- Identify items that are overdue, at risk, or recently completed
- Surface any items without clear owners or dates

If no project management tool is connected:
- Ask the user to describe their current roadmap or paste/upload it
- Accept any format: list, table, spreadsheet, screenshot, or prose description

### 2. Determine the Operation

Ask what the user wants to do:

**Add item**: New feature, initiative, or work item to the roadmap
- Gather: name, description, priority, estimated effort, target timeframe, owner, dependencies
- Suggest where it fits based on current priorities and capacity

**Update status**: Change status of existing items
- Options: not started, in progress, at risk, blocked, completed, cut
- For "at risk" or "blocked": ask for the blocker and mitigation plan

**Reprioritize**: Change the order or priority of items
- Ask what changed (new information, strategy shift, resource change, customer feedback)
- Apply a prioritization framework if helpful — see **Prioritization Frameworks** below for RICE, MoSCoW, ICE, and value-vs-effort
- Show before/after comparison

**Move timeline**: Shift dates for items
- Ask why (scope change, dependency slip, resource constraint)
- Identify downstream impacts on dependent items
- Flag items that move past hard deadlines

**Create new roadmap**: Build a roadmap from scratch
- Ask about timeframe (quarter, half, year)
- Ask about format preference (Now/Next/Later, quarterly columns, OKR-aligned) — see **Roadmap Frameworks** below
- Gather the list of initiatives to include

### 3. Generate Roadmap Summary

Produce a roadmap view with:

#### Status Overview
Quick summary: X items in progress, Y completed this period, Z at risk.

#### Roadmap Items
For each item, show:
- Name and one-line description
- Status indicator (on track / at risk / blocked / completed / not started)
- Target timeframe or date
- Owner
- Key dependencies

Group items by:
- Timeframe (Now / Next / Later) or quarter, depending on format
- Or by theme/goal if the user prefers

#### Risks and Dependencies
- Items that are blocked or at risk, with details
- Cross-team dependencies and their status
- Items approaching hard deadlines

#### Changes This Update
If this is an update to an existing roadmap, summarize what changed:
- Items added, removed, or reprioritized
- Timeline shifts
- Status changes

### 4. Follow Up

After generating the roadmap:
- Offer to format for a specific audience (executive summary, engineering detail, customer-facing)
- Offer to draft communication about roadmap changes
- If project management tool is connected, offer to update ticket statuses

## Roadmap Frameworks

### Now / Next / Later
The simplest and often most effective roadmap format:

- **Now** (current sprint/month): Committed work. High confidence in scope and timeline. These are the things the team is actively building.
- **Next** (next 1-3 months): Planned work. Good confidence in what, less confidence in exactly when. Scoped and prioritized but not yet started.
- **Later** (3-6+ months): Directional. These are strategic bets and opportunities we intend to pursue, but scope and timing are flexible.

When to use: Most teams, most of the time. Especially good for communicating externally or to leadership because it avoids false precision on dates.

### Quarterly Themes
Organize the roadmap around 2-3 themes per quarter:

- Each theme represents a strategic area of investment (e.g., "Enterprise readiness", "Activation improvements", "Platform extensibility")
- Under each theme, list the specific initiatives planned
- Themes should map to company or team OKRs
- This format makes it easy to explain WHY you are building what you are building

When to use: When you need to show strategic alignment. Good for planning meetings and executive communication.

### OKR-Aligned Roadmap
Map roadmap items directly to Objectives and Key Results:

- Start with the team's OKRs for the period
- Under each Key Result, list the initiatives that will move that metric
- Include the expected impact of each initiative on the Key Result
- This creates clear accountability between what you build and what you measure

When to use: Organizations that run on OKRs. Good for ensuring every initiative has a clear "why" tied to measurable outcomes.

### Timeline / Gantt View
Calendar-based view with items on a timeline:

- Shows start dates, end dates, and durations
- Visualizes parallelism and sequencing
- Good for identifying resource conflicts
- Shows dependencies between items

When to use: Execution planning with engineering. Identifying scheduling conflicts. NOT good for communicating externally (creates false precision expectations).

## Prioritization Frameworks

### RICE Score
Score each initiative on four dimensions, then calculate RICE = (Reach x Impact x Confidence) / Effort

- **Reach**: How many users/customers will this affect in a given time period? Use concrete numbers (e.g., "500 users per quarter").
- **Impact**: How much will this move the needle for each person reached? Score on a scale: 3 = massive, 2 = high, 1 = medium, 0.5 = low, 0.25 = minimal.
- **Confidence**: How confident are we in the reach and impact estimates? 100% = high confidence (backed by data), 80% = medium (some evidence), 50% = low (gut feel).
- **Effort**: How many person-months of work? Include engineering, design, and any other functions.

When to use: When you need a quantitative, defensible prioritization. Good for comparing a large backlog of initiatives. Less good for strategic bets where impact is hard to estimate.

### MoSCoW
Categorize items into Must have, Should have, Could have, Won't have:

- **Must have**: The roadmap is a failure without these. Non-negotiable commitments.
- **Should have**: Important and expected, but delivery is viable without them.
- **Could have**: Desirable but clearly lower priority. Include only if capacity allows.
- **Won't have**: Explicitly out of scope for this period. Important to list for clarity.

When to use: Scoping a release or quarter. Negotiating with stakeholders about what fits. Good for forcing prioritization conversations.

### ICE Score
Simpler than RICE. Score each item 1-10 on three dimensions:

- **Impact**: How much will this move the target metric?
- **Confidence**: How confident are we in the impact estimate?
- **Ease**: How easy is this to implement? (Inverse of effort — higher = easier)

ICE Score = Impact x Confidence x Ease

When to use: Quick prioritization of a feature backlog. Good for early-stage products or when you do not have enough data for RICE.

### Value vs Effort Matrix
Plot initiatives on a 2x2 matrix:

- **High value, Low effort** (Quick wins): Do these first.
- **High value, High effort** (Big bets): Plan these carefully. Worth the investment but need proper scoping.
- **Low value, Low effort** (Fill-ins): Do these when you have spare capacity.
- **Low value, High effort** (Money pits): Do not do these. Remove from the backlog.

When to use: Visual prioritization in team planning sessions. Good for building shared understanding of tradeoffs.

## Dependency Mapping

### Identifying Dependencies
Look for dependencies across these categories:

- **Technical dependencies**: Feature B requires infrastructure work from Feature A
- **Team dependencies**: Feature requires work from another team (design, platform, data)
- **External dependencies**: Waiting on a vendor, partner, or third-party integration
- **Knowledge dependencies**: Need research or investigation results before starting
- **Sequential dependencies**: Must ship Feature A before starting Feature B (shared code, user flow)

### Managing Dependencies
- List all dependencies explicitly in the roadmap
- Assign an owner to each dependency (who is responsible for resolving it)
- Set a "need by" date: when does the depending item need this resolved
- Build buffer around dependencies — they are the highest-risk items on any roadmap
- Flag dependencies that cross team boundaries early — these require coordination
- Have a contingency plan: what do you do if the dependency slips?

### Reducing Dependencies
- Can you build a simpler version that avoids the dependency?
- Can you parallelize by using an interface contract or mock?
- Can you sequence differently to move the dependency earlier?
- Can you absorb the work into your team to remove the cross-team coordination?

## Capacity Planning

### Estimating Capacity
- Start with the number of engineers and the time period
- Subtract known overhead: meetings, on-call rotations, interviews, holidays, PTO
- A common rule of thumb: engineers spend 60-70% of time on planned feature work
- Factor in team ramp time for new members

### Allocating Capacity
A healthy allocation for most product teams:

- **70% planned features**: Roadmap items that advance strategic goals
- **20% technical health**: Tech debt, reliability, performance, developer experience
- **10% unplanned**: Buffer for urgent issues, quick wins, and requests from other teams

Adjust ratios based on team context:
- New product: more feature work, less tech debt
- Mature product: more tech debt and reliability investment
- Post-incident: more reliability, less features
- Rapid growth: more scalability and performance

### Capacity vs Ambition
- If roadmap commitments exceed capacity, something must give
- Do not solve capacity problems by pretending people can do more — solve by cutting scope
- When adding to the roadmap, always ask: "What comes off?"
- Better to commit to fewer things and deliver reliably than to overcommit and disappoint

## Communicating Roadmap Changes

### When the Roadmap Changes
Common triggers for roadmap changes:
- New strategic priority from leadership
- Customer feedback or research that changes priorities
- Technical discovery that changes estimates
- Dependency slip from another team
- Resource change (team grows or shrinks, key person leaves)
- Competitive move that requires response

### How to Communicate Changes
1. **Acknowledge the change**: Be direct about what is changing and why
2. **Explain the reason**: What new information drove this decision?
3. **Show the tradeoff**: What was deprioritized to make room? Or what is slipping?
4. **Show the new plan**: Updated roadmap with the changes reflected
5. **Acknowledge impact**: Who is affected and how? Stakeholders who were expecting deprioritized items need to hear it directly.

### Avoiding Roadmap Whiplash
- Do not change the roadmap for every piece of new information. Have a threshold for change.
- Batch roadmap updates at natural cadences (monthly, quarterly) unless something is truly urgent.
- Distinguish between "roadmap change" (strategic reprioritization) and "scope adjustment" (normal execution refinement).
- Track how often the roadmap changes. Frequent changes may signal unclear strategy, not good responsiveness.

## Output Format

Use a clear, scannable format. Tables work well for roadmap items. Use text status labels: **Done**, **On Track**, **At Risk**, **Blocked**, **Not Started**.

## Tips

- A roadmap is a communication tool, not a project plan. Keep it at the right altitude — themes and outcomes, not tasks.
- When reprioritizing, always ask what changed. Priority shifts should be driven by new information, not whim.
- Flag capacity issues early. If the roadmap has more work than the team can handle, say so.
- Dependencies are the biggest risk to roadmaps. Surface them explicitly.
- If the user asks to add something, always ask what comes off or moves. Roadmaps are zero-sum against capacity.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/product-management/skills/sprint-planning', 'business', 'sprint-planning', '', 'sprint-planning', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /sprint-planning

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Plan a sprint by scoping work, estimating capacity, and setting clear goals.

## Usage

```
/sprint-planning $ARGUMENTS
```

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPRINT PLANNING                                 │
├─────────────────────────────────────────────────────────────────┤
│  STANDALONE (always works)                                       │
│  ✓ Define sprint goals and success criteria                     │
│  ✓ Estimate team capacity (accounting for PTO, meetings)        │
│  ✓ Scope and prioritize backlog items                           │
│  ✓ Identify dependencies and risks                              │
│  ✓ Generate sprint plan document                                │
├─────────────────────────────────────────────────────────────────┤
│  SUPERCHARGED (when you connect your tools)                      │
│  + Project tracker: Pull backlog, create sprint, assign items   │
│  + Calendar: Account for PTO and meetings in capacity           │
│  + Chat: Share sprint plan with the team                        │
└─────────────────────────────────────────────────────────────────┘
```

## What I Need From You

- **Team**: Who's on the team and their availability this sprint?
- **Sprint length**: How many days/weeks?
- **Backlog**: What's prioritized? (Pull from tracker, paste, or describe)
- **Carryover**: Anything unfinished from last sprint?
- **Dependencies**: Anything blocked on other teams?

## Output

```markdown
## Sprint Plan: [Sprint Name]
**Dates:** [Start] — [End] | **Team:** [X] engineers
**Sprint Goal:** [One clear sentence about what success looks like]

### Capacity
| Person | Available Days | Allocation | Notes |
|--------|---------------|------------|-------|
| [Name] | [X] of [Y] | [X] points/hours | [PTO, on-call, etc.] |
| **Total** | **[X]** | **[X] points** | |

### Sprint Backlog
| Priority | Item | Estimate | Owner | Dependencies |
|----------|------|----------|-------|--------------|
| P0 | [Must ship] | [X] pts | [Person] | [None / Blocked by X] |
| P1 | [Should ship] | [X] pts | [Person] | [None] |
| P2 | [Stretch] | [X] pts | [Person] | [None] |

### Planned Capacity: [X] points | Sprint Load: [X] points ([X]% of capacity)

### Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk] | [What happens] | [What to do] |

### Definition of Done
- [ ] Code reviewed and merged
- [ ] Tests passing
- [ ] Documentation updated (if applicable)
- [ ] Product sign-off

### Key Dates
| Date | Event |
|------|-------|
| [Date] | Sprint start |
| [Date] | Mid-sprint check-in |
| [Date] | Sprint end / Demo |
| [Date] | Retro |
```

## Tips

1. **Leave buffer** — Plan to 70-80% capacity. You will get interrupts.
2. **One clear sprint goal** — If you can't state it in one sentence, the sprint is unfocused.
3. **Identify stretch items** — Know what to cut if things take longer than expected.
4. **Carry over honestly** — If something didn't ship, understand why before re-committing.$body$)
ON CONFLICT (skill_key) DO NOTHING;
