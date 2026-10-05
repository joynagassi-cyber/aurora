INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/cobrowse-sdk', 'business', 'cobrowse-sdk', '', 'cobrowse-sdk', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Cobrowse SDK - Web Development

Background reference for collaborative browsing on the web with Zoom Cobrowse SDK. Use this after the support workflow is clear and you need implementation detail.

**Official Documentation**: https://developers.zoom.us/docs/cobrowse-sdk/  
**API Reference**: https://marketplacefront.zoom.us/sdk/cobrowse/  
**Quickstart Repository**: https://github.com/zoom/CobrowseSDK-Quickstart  
**Auth Endpoint Sample**: https://github.com/zoom/cobrowsesdk-auth-endpoint-sample

## Quick Links

**New to Cobrowse SDK? Follow this path:**

1. **[Get Started Guide](get-started.md)** - Complete setup from credentials to first session
2. **[Session Lifecycle](concepts/session-lifecycle.md)** - Understanding customer and agent flows
3. **[JWT Authentication](concepts/jwt-authentication.md)** - Token generation and security
4. **[Customer Integration](examples/customer-integration.md)** - Integrate SDK into your website
5. **[Agent Integration](examples/agent-integration.md)** - Set up agent portal (iframe or npm)

**Core Concepts:**
- **[Two Roles Pattern](concepts/two-roles-pattern.md)** - Customer vs Agent architecture
- **[Session Lifecycle](concepts/session-lifecycle.md)** - PIN generation, connection, reconnection
- **[JWT Authentication](concepts/jwt-authentication.md)** - SDK Key vs API Key, role_type, claims
- **[Distribution Methods](concepts/distribution-methods.md)** - CDN vs npm (BYOP)

**Features:**
- **[Annotation Tools](examples/annotations.md)** - Drawing, highlighting, pointer tools
- **[Privacy Masking](examples/privacy-masking.md)** - Hide sensitive fields from agents
- **[Remote Assist](examples/remote-assist.md)** - Agent can scroll customer's page
- **[Multi-Tab Persistence](examples/multi-tab-persistence.md)** - Session continues across tabs
- **[BYOP Mode](examples/byop-custom-pin.md)** - Bring Your Own PIN with npm integration

**Troubleshooting:**
- **[Common Issues](troubleshooting/common-issues.md)** - Quick diagnostics and solutions
- **[Error Codes](troubleshooting/error-codes.md)** - Complete error reference
- **[CORS and CSP](troubleshooting/cors-csp.md)** - Cross-origin and security policy configuration
- **[Browser Compatibility](troubleshooting/browser-compatibility.md)** - Supported browsers and limitations
- **[5-Minute Runbook](RUNBOOK.md)** - Fast preflight checks before deep debugging

**Reference:**
- **[API Reference](references/api-reference.md)** - Complete SDK methods and events
- **[Settings Reference](references/settings-reference.md)** - All initialization settings
- **Integrated Index** - see the section below in this file

## SDK Overview

The Zoom Cobrowse SDK is a JavaScript library that provides:

- **Real-Time Co-Browsing**: Agent sees customer's browser activity live
- **PIN-Based Sessions**: Secure 6-digit PIN for customer-to-agent connection
- **Annotation Tools**: Drawing, highlighting, vanishing pen, rectangle, color picker
- **Privacy Masking**: CSS selector-based masking of sensitive form fields
- **Remote Assist**: Agent can scroll customer's page (with consent)
- **Multi-Tab Persistence**: Session continues when customer opens new tabs
- **Auto-Reconnection**: Session recovers from page refresh (2-minute window)
- **Session Events**: Real-time events for session state changes
- **HTTPS Required**: Secure connections (HTTP only works on loopback/local development hosts)
- **No Plugins**: Pure JavaScript, no browser extensions needed

## Two Roles Architecture

Cobrowse has **two distinct roles**, each with different integration patterns:

| Role | role_type | Integration | JWT Required | Purpose |
|------|-----------|-------------|--------------|---------|
| **Customer** | 1 | Website integration (CDN or npm) | Yes | User who shares their browser session |
| **Agent** | 2 | Iframe (CDN) or npm (BYOP only) | Yes | Support staff who views/assists customer |

**Key Insight**: Customer and agent use **different integration methods** but the same JWT authentication pattern.

## Read This First (Critical)

For customer/agent demos, treat the PIN from customer SDK event `pincode_updated` as the only user-facing PIN.

- Show one clearly labeled value in UI (for example, **Support PIN**).
- Use that same PIN for agent join.
- Do not expose provisional/debug PINs from backend pre-start records to users.

If these rules are ignored, agent desk often fails with `Pincode is not found` / code `30308`.

### Typical Production Flow (Most Common)

This is the flow most teams implement first, and what users usually expect in demos:

1. **Customer starts session first** (`role_type=1`)
   - Backend creates/records session
   - Backend returns customer JWT
   - Customer SDK starts and receives a PIN
2. **Agent joins second** (`role_type=2`)
   - Agent enters customer PIN
   - Backend validates PIN and session state
   - Backend returns agent JWT
   - Agent opens Zoom-hosted desk iframe (or custom npm agent UI in BYOP)

If a demo only has one generic "session" user, it is incomplete for real cobrowse operations.

## Prerequisites

### Platform Requirements

- **Supported Browsers**:
  - Chrome 80+ ✓
  - Firefox 78+ ✓
  - Safari 14+ ✓
  - Edge 80+ ✓
  - Internet Explorer ✗ (not supported)

- **Network Requirements**:
  - HTTPS required (HTTP works on loopback/local development hosts only)
  - Allow cross-origin requests to `*.zoom.us`
  - CSP headers must allow Zoom domains (see [CORS and CSP guide](troubleshooting/cors-csp.md))

- **Third-Party Cookies**:
  - Must enable third-party cookies for refresh reconnection
  - Privacy mode may limit certain features

### Zoom Account Requirements

1. **Zoom Workplace Account** with SDK Universal Credit
2. **Video SDK App** created in Zoom Marketplace
3. **Cobrowse SDK Credentials** from the app's Cobrowse tab

**Note**: Cobrowse SDK is a **feature of Video SDK** (not a separate product).

### Credentials Overview

You'll receive **4 credentials** from Zoom Marketplace → Video SDK App → Cobrowse tab:

| Credential | Type | Used For | Exposure Safe? |
|------------|------|----------|----------------|
| **SDK Key** | Public | CDN URL, JWT `app_key` claim | ✓ Yes (client-side) |
| **SDK Secret** | Private | Sign JWTs | ✗ No (server-side only) |
| **API Key** | Private | REST API calls (optional) | ✗ No (server-side only) |
| **API Secret** | Private | REST API calls (optional) | ✗ No (server-side only) |

**Critical**: SDK Key is **public** (embedded in CDN URL), but SDK Secret must **never** be exposed client-side.

## Quick Start

### Step 1: Get SDK Credentials

1. Go to [Zoom Marketplace](https://marketplace.zoom.us/)
2. Open your **Video SDK App** (or create one)
3. Navigate to the **Cobrowse** tab
4. Copy your credentials:
   - SDK Key
   - SDK Secret
   - API Key (optional)
   - API Secret (optional)

### Step 2: Set Up Token Server

Deploy a server-side endpoint to generate JWTs. Use the official sample:

```bash
git clone https://github.com/zoom/cobrowsesdk-auth-endpoint-sample.git
cd cobrowsesdk-auth-endpoint-sample
npm install

# Create .env file
cat > .env << EOF
ZOOM_SDK_KEY=your_sdk_key_here
ZOOM_SDK_SECRET=your_sdk_secret_here
PORT=4000
EOF

npm start
```

**Token endpoint:**
```javascript
// POST https://YOUR_TOKEN_SERVICE_BASE_URL
{
  "role": 1,           // 1 = customer, 2 = agent
  "userId": "user123",
  "userName": "John Doe"
}

// Response
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### Step 3: Customer Side Integration (CDN)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Customer - Cobrowse Demo</title>
  <script type="module">
    const ZOOM_SDK_KEY = 'YOUR_SDK_KEY';
    
    // Load SDK from CDN
    (function(r, a, b, f, c, d) {
      r[f] = r[f] || { init: function() { r.ZoomCobrowseSDKInitArgs = arguments }};
      var fragment = a.createDocumentFragment();
      function loadJs(url) {
        c = a.createElement(b);
        d = a.getElementsByTagName(b)[0];
        c["async"] = false;
        c.src = url;
        fragment.appendChild(c);
      }
      loadJs(`https://us01-zcb.zoom.us/static/resource/sdk/${ZOOM_SDK_KEY}/js/2.13.2`);
      d.parentNode.insertBefore(fragment, d);
    })(window, document, "script", "ZoomCobrowseSDK");
  </script>
</head>
<body>
  <h1>Customer Support</h1>
  <button id="cobrowse-btn" disabled>Loading...</button>
  
  <!-- Sensitive fields - will be masked from agent -->
  <label>SSN: <input type="text" class="pii-mask" placeholder="XXX-XX-XXXX"></label>
  <label>Credit Card: <input type="text" class="pii-mask" placeholder="XXXX-XXXX-XXXX-XXXX"></label>
  
  <script type="module">
    let sessionRef = null;
    
    const settings = {
      allowAgentAnnotation: true,
      allowCustomerAnnotation: true,
      piiMask: {
        maskCssSelectors: ".pii-mask",
        maskType: "custom_input"
      }
    };
    
    ZoomCobrowseSDK.init(settings, function({ success, session, error }) {
      if (success) {
        sessionRef = session;
        
        // Listen for PIN code
        session.on("pincode_updated", (payload) => {
          console.log("PIN Code:", payload.pincode);
          // IMPORTANT: this is the PIN agent should use
          alert(`Share this PIN with agent: ${payload.pincode}`);
        });
        
        // Listen for session events
        session.on("session_started", () => console.log("Session started"));
        session.on("agent_joined", () => console.log("Agent joined"));
        session.on("agent_left", () => console.log("Agent left"));
        session.on("session_ended", () => console.log("Session ended"));
        
        document.getElementById("cobrowse-btn").disabled = false;
        document.getElementById("cobrowse-btn").innerText = "Start Cobrowse Session";
      } else {
        console.error("SDK init failed:", error);
      }
    });
    
    document.getElementById("cobrowse-btn").addEventListener("click", async () => {
      // Fetch JWT from your server
      const response = await fetch("https://YOUR_TOKEN_SERVICE_BASE_URL", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          role: 1,
          userId: "customer_" + Date.now(),
          userName: "Customer"
        })
      });
      const { token } = await response.json();
      
      // Start cobrowse session
      sessionRef.start({ sdkToken: token });
    });
  </script>
</body>
</html>
```

### Step 4: Agent Side Integration (Iframe)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Agent Portal</title>
</head>
<body>
  <h1>Agent Portal</h1>
  <iframe 
    id="agent-iframe"
    width="1024" 
    height="768"
    allow="autoplay *; camera *; microphone *; display-capture *; geolocation *;"
  ></iframe>
  
  <script>
    async function connectAgent() {
      // Fetch JWT from your server
      const response = await fetch("https://YOUR_TOKEN_SERVICE_BASE_URL", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          role: 2,
          userId: "agent_" + Date.now(),
          userName: "Support Agent"
        })
      });
      const { token } = await response.json();
      
      // Load Zoom agent portal
      const iframe = document.getElementById("agent-iframe");
      iframe.src = `https://us01-zcb.zoom.us/sdkapi/zcb/frame-templates/desk?access_token=${token}`;
    }
    
    connectAgent();
  </script>
</body>
</html>
```

### Step 5: Test the Integration

1. Open **two separate browsers** (or incognito + normal)
2. **Customer browser**: Open customer page, click "Start Cobrowse Session"
3. **Customer browser**: Note the 6-digit PIN displayed
4. **Agent browser**: Open agent page, enter the PIN code
5. **Both browsers**: Session connects, agent can see customer's page
6. **Test features**: Annotations, data masking, remote assist

## Key Features

### 1. Annotation Tools

Both customer and agent can draw on the shared screen:

```javascript
const settings = {
  allowAgentAnnotation: true,      // Agent can draw
  allowCustomerAnnotation: true    // Customer can draw
};
```

**Available tools**:
- Pen (persistent)
- Vanishing pen (disappears after 4 seconds)
- Rectangle
- Color picker
- Eraser
- Undo/Redo

### 2. Privacy Masking

Hide sensitive fields from agents using CSS selectors:

```javascript
const settings = {
  piiMask: {
    maskType: "custom_input",           // Mask specific fields
    maskCssSelectors: ".pii-mask, #ssn", // CSS selectors
    maskHTMLAttributes: "data-sensitive=true" // HTML attributes
  }
};
```

**Supported masking**:
- Text nodes ✓
- Form inputs ✓
- Select elements ✓
- Images ✗ (not supported)
- Links ✗ (not supported)

### 3. Remote Assist

Agent can scroll the customer's page:

```javascript
const settings = {
  remoteAssist: {
    enable: true,
    enableCustomerConsent: true,        // Customer must approve
    remoteAssistTypes: ['scroll_page'], // Only scroll supported
    requireStopConfirmation: false      // Confirmation when stopping
  }
};
```

### 4. Multi-Tab Session Persistence

Session continues when customer opens new tabs:

```javascript
const settings = {
  multiTabSessionPersistence: {
    enable: true,
    stateCookieKey: '$$ZCB_SESSION$$'  // Cookie key (base64 encoded)
  }
};
```

## Session Lifecycle

### Customer Flow

1. **Load SDK** → CDN script loads `ZoomCobrowseSDK`
2. **Initialize** → `ZoomCobrowseSDK.init(settings, callback)`
3. **Fetch JWT** → Request token from your server (role_type=1)
4. **Start Session** → `session.start({ sdkToken })`
5. **PIN Generated** → `pincode_updated` event fires
6. **Share PIN** → Customer gives 6-digit PIN to agent
7. **Agent Joins** → `agent_joined` event fires
8. **Session Active** → Real-time synchronization begins
9. **End Session** → `session.end()` or agent leaves

### Agent Flow

1. **Fetch JWT** → Request token from your server (role_type=2)
2. **Load Iframe** → Point to Zoom agent portal with token
3. **Enter PIN** → Agent inputs customer's 6-digit PIN
4. **Connect** → `session_joined` event fires
5. **View Session** → Agent sees customer's browser
6. **Use Tools** → Annotations, remote assist, zoom
7. **Leave Session** → Click "Leave Cobrowse" button

### Session Recovery (Auto-Reconnect)

When customer refreshes the page:

```javascript
ZoomCobrowseSDK.init(settings, function({ success, session, error }) {
  if (success) {
    const sessionInfo = session.getSessionInfo();
    
    // Check if session is recoverable
    if (sessionInfo.sessionStatus === 'session_recoverable') {
      session.join();  // Auto-rejoin previous session
    } else {
      // Start new session
      session.start({ sdkToken });
    }
  }
});
```

**Recovery window**: 2 minutes. After 2 minutes, session ends.

## Critical Gotchas and Best Practices

### ⚠️ CRITICAL: SDK Secret Must Stay Server-Side

**Problem**: Developers often accidentally embed SDK Secret in frontend code.

**Solution**:
- ✓ **SDK Key** → Safe to expose (embedded in CDN URL)
- ✗ **SDK Secret** → Never expose (use for JWT signing server-side)

```javascript
// ❌ WRONG - Secret exposed in frontend
const jwt = signJWT(payload, 'YOUR_SDK_SECRET');  // Security risk!

// ✅ CORRECT - Secret stays on server
const response = await fetch('/api/token', {
  method: 'POST',
  body: JSON.stringify({ role: 1, userId, userName })
});
const { token } = await response.json();
```

### SDK Key vs API Key (Different Purposes!)

| Credential | Used For | JWT Claim |
|------------|----------|-----------|
| **SDK Key** | CDN URL, JWT `app_key` | `app_key: "SDK_KEY"` |
| **API Key** | REST API calls (optional) | Not used in JWT |

**Common mistake**: Using API Key instead of SDK Key in JWT `app_key` claim.

### Session Limits

| Limit | Value | What Happens |
|-------|-------|--------------|
| Customers per session | 1 | Error 1012: `SESSION_CUSTOMER_COUNT_LIMIT` |
| Agents per session | 5 | Error 1013: `SESSION_AGENT_COUNT_LIMIT` |
| Active sessions per browser | 1 | Error 1004: `SESSION_COUNT_LIMIT` |
| PIN code length | 10 chars max | Error 1008: `SESSION_PIN_INVALID_FORMAT` |

### Session Timeout Behavior

| Event | Timeout | What Happens |
|-------|---------|--------------|
| Agent waiting for customer | 3 minutes | Session ends automatically |
| Page refresh reconnection | 2 minutes | Session ends if not reconnected |
| Reconnection attempts | 2 times max | Session ends after 2 failed attempts |

### HTTPS Requirement

**Problem**: SDK doesn't load on HTTP sites.

**Solution**:
- Production: Use HTTPS ✓
- Development: Use a loopback host for local HTTP testing ✓
- Development: Use a local HTTPS endpoint with a trusted/self-signed cert if required ✓

### Third-Party Cookies Required

**Problem**: Refresh reconnection doesn't work.

**Solution**: Enable third-party cookies in browser settings.

**Affected scenarios**:
- Browser privacy mode
- Safari with "Prevent cross-site tracking" enabled
- Chrome with "Block third-party cookies" enabled

### Distribution Method Confusion

| Method | Use Case | Agent Integration | BYOP Required |
|--------|----------|-------------------|---------------|
| **CDN** | Most use cases | Zoom-hosted iframe | No (auto PIN) |
| **npm** | Custom agent UI, full control | Custom npm integration | Yes (required) |

**Key Insight**: If you want **npm** integration, you **must** use BYOP (Bring Your Own PIN) mode.

### Cross-Origin Iframe Handling

**Problem**: Cobrowse doesn't work in cross-origin iframes.

**Solution**: Inject SDK snippet into cross-origin iframes:

```html
<script>
const ZOOM_SDK_KEY = "YOUR_SDK_KEY_HERE";

(function(r,a,b,f,c,d){r[f]=r[f]||{init:function(){r.ZoomCobrowseSDKInitArgs=arguments}};
var fragment=a.createDocumentFragment();function loadJs(url) {c=a.createElement(b);d=a.getElementsByTagName(b)[0];c.async=false;c.src=url;fragment.appendChild(c);};
loadJs('https://us01-zcb.zoom.us/static/resource/sdk/${ZOOM_SDK_KEY}/js');d.parentNode.insertBefore(fragment,d);})(window,document,'script','ZoomCobrowseSDK');
</script>
```

**Same-origin iframes**: No extra setup needed.

## Known Limitations

### Synchronization Limits

**Not synchronized**:
- HTML5 Canvas elements
- WebGL content
- Audio and Video elements
- Shadow DOM
- PDF rendered with Canvas
- Web Components

**Partially synchronized**:
- Drop-down boxes (only selected result)
- Date pickers (only selected result)
- Color pickers (only selected result)

### Rendering Limits

- High-resolution images may be compressed
- Different screen sizes may cause CSS media query differences
- Cross-origin images may not render (CORS restrictions)
- Cross-origin fonts may not render (CORS restrictions)

### Masking Limits

**Supported**:
- Text nodes ✓
- Form inputs ✓
- Select elements ✓

**Not supported**:
- `<img>` elements ✗
- Links ✗

## Complete Documentation Library

This skill includes comprehensive guides organized by category:

### Core Concepts
- **[Two Roles Pattern](concepts/two-roles-pattern.md)** - Customer vs Agent architecture
- **[Session Lifecycle](concepts/session-lifecycle.md)** - Complete flow from start to end
- **[JWT Authentication](concepts/jwt-authentication.md)** - Token structure and signing
- **[Distribution Methods](concepts/distribution-methods.md)** - CDN vs npm (BYOP)

### Examples
- **[Customer Integration](examples/customer-integration.md)** - Complete customer-side setup
- **[Agent Integration](examples/agent-integration.md)** - Iframe and npm agent setups
- **[Annotations](examples/annotations.md)** - Drawing tools configuration
- **[Privacy Masking](examples/privacy-masking.md)** - Field masking patterns
- **[Remote Assist](examples/remote-assist.md)** - Agent page control
- **[Multi-Tab Persistence](examples/multi-tab-persistence.md)** - Cross-tab sessions
- **[BYOP Custom PIN](examples/byop-custom-pin.md)** - Custom PIN codes

### References
- **[API Reference](references/api-reference.md)** - Complete SDK methods and events
- **[Settings Reference](references/settings-reference.md)** - All initialization settings
- **[Error Codes](references/error-codes.md)** - Complete error reference
- **[Session Events](references/session-events.md)** - All event types

### Troubleshooting
- **[Common Issues](troubleshooting/common-issues.md)** - Quick diagnostics
- **[Error Codes](troubleshooting/error-codes.md)** - Error code reference
- **[CORS and CSP](troubleshooting/cors-csp.md)** - Cross-origin configuration
- **[Browser Compatibility](troubleshooting/browser-compatibility.md)** - Browser support

## Resources

- **Official Docs**: https://developers.zoom.us/docs/cobrowse-sdk/
- **API Reference**: https://marketplacefront.zoom.us/sdk/cobrowse/
- **Quickstart Repo**: https://github.com/zoom/CobrowseSDK-Quickstart
- **Auth Endpoint Sample**: https://github.com/zoom/cobrowsesdk-auth-endpoint-sample
- **Dev Forum**: https://devforum.zoom.us/
- **Developer Blog**: https://developers.zoom.us/blog/?category=zoom-cobrowse-sdk

---

**Need help?** Start with Integrated Index section below for complete navigation.

---

## Integrated Index

_This section was migrated from `SKILL.md`._

**Complete navigation guide for all Cobrowse SDK documentation.**

## Getting Started (Start Here!)

If you're new to Zoom Cobrowse SDK, follow this learning path:

1. **[SKILL.md](SKILL.md)** - Main overview and quick start
2. **[5-Minute Runbook](RUNBOOK.md)** - Preflight checks for common failures
3. **[Get Started Guide](get-started.md)** - Step-by-step setup from credentials to first session
4. **[Session Lifecycle](concepts/session-lifecycle.md)** - Understand the complete customer and agent flow
5. **[Customer Integration](examples/customer-integration.md)** - Integrate SDK into your website
6. **[Agent Integration](examples/agent-integration.md)** - Set up agent portal

## Core Concepts

Foundational concepts you need to understand:

- **[Two Roles Pattern](concepts/two-roles-pattern.md)** - Customer (role_type=1) vs Agent (role_type=2) architecture
- **[Session Lifecycle](concepts/session-lifecycle.md)** - Complete flow: init → start → PIN → connect → end
- **[JWT Authentication](concepts/jwt-authentication.md)** - Token structure, signing, SDK Key vs API Key
- **[Distribution Methods](concepts/distribution-methods.md)** - CDN vs npm (BYOP mode)

## Examples and Patterns

Complete working examples for common scenarios:

### Session Management
- **[Customer Integration](examples/customer-integration.md)** - Complete customer-side implementation (CDN and npm)
- **[Agent Integration](examples/agent-integration.md)** - Iframe and npm agent setup patterns
- **[Session Events](examples/session-events.md)** - Handle all session lifecycle events
- **[Auto-Reconnection](examples/auto-reconnection.md)** - Page refresh and session recovery

### Features
- **[Annotation Tools](examples/annotations.md)** - Enable drawing, highlighting, vanishing pen
- **[Privacy Masking](examples/privacy-masking.md)** - Mask sensitive fields with CSS selectors
- **[Remote Assist](examples/remote-assist.md)** - Agent can scroll customer's page
- **[Multi-Tab Persistence](examples/multi-tab-persistence.md)** - Session continues across browser tabs
- **[BYOP Custom PIN](examples/byop-custom-pin.md)** - Bring Your Own PIN with npm integration

## References

Complete API and configuration references:

### SDK Reference
- **[API Reference](references/api-reference.md)** - All SDK methods and interfaces
  - ZoomCobrowseSDK.init()
  - session.start()
  - session.join()
  - session.end()
  - session.on()
  - session.getSessionInfo()
  
- **[Settings Reference](references/settings-reference.md)** - All initialization settings
  - allowAgentAnnotation
  - allowCustomerAnnotation
  - piiMask
  - remoteAssist
  - multiTabSessionPersistence

- **[Session Events Reference](references/session-events.md)** - All event types
  - pincode_updated
  - session_started
  - session_ended
  - agent_joined
  - agent_left
  - session_error
  - session_reconnecting
  - remote_assist_started
  - remote_assist_stopped

### Error Reference
- **[Error Codes](references/error-codes.md)** - Complete error code reference
  - 1001-1017: Session errors
  - 2001: Token errors
  - 9999: Service errors

### Official Documentation
- **[Get Started](references/get-started.md)** - Official get started documentation (crawled)
- **[Features](references/features.md)** - Official features documentation (crawled)
- **[Authorization](references/authorization.md)** - Official JWT authorization docs (crawled)
- **[API Documentation](references/api.md)** - Crawled API reference docs

## Troubleshooting

Quick diagnostics and common issue resolution:

- **[Common Issues](troubleshooting/common-issues.md)** - Quick fixes for frequent problems
  - SDK not loading
  - Token generation fails
  - Agent can't connect
  - Fields not masked
  - Session doesn't reconnect after refresh

- **[Error Codes](troubleshooting/error-codes.md)** - Error code lookup and solutions
  - Session start/join failures (1001, 1011, 1016)
  - Session limit errors (1002, 1004, 1012, 1013, 1015)
  - PIN code errors (1006, 1008, 1009, 1010)
  - Token errors (2001)

- **[CORS and CSP](troubleshooting/cors-csp.md)** - Cross-origin and Content Security Policy setup
  - Access-Control-Allow-Origin headers
  - Content-Security-Policy headers
  - Cross-origin iframe handling
  - Same-origin iframe handling

- **[Browser Compatibility](troubleshooting/browser-compatibility.md)** - Browser requirements and limitations
  - Supported browsers (Chrome 80+, Firefox 78+, Safari 14+, Edge 80+)
  - Internet Explorer not supported
  - Privacy mode limitations
  - Third-party cookie requirements

## By Use Case

Find documentation by what you're trying to do:

### I want to...

**Set up cobrowse for the first time:**
- [Get Started Guide](get-started.md)
- [JWT Authentication](concepts/jwt-authentication.md)
- [Customer Integration](examples/customer-integration.md)
- [Agent Integration](examples/agent-integration.md)

**Add annotation tools:**
- [Annotation Tools Example](examples/annotations.md)
- [Settings Reference - allowAgentAnnotation](references/settings-reference.md#allowa gentannotation)
- [Settings Reference - allowCustomerAnnotation](references/settings-reference.md#allowcustomerannotation)

**Hide sensitive data from agents:**
- [Privacy Masking Example](examples/privacy-masking.md)
- [Settings Reference - piiMask](references/settings-reference.md#piimask)

**Let agents control customer's page:**
- [Remote Assist Example](examples/remote-assist.md)
- [Settings Reference - remoteAssist](references/settings-reference.md#remoteassist)

**Use custom PIN codes:**
- [BYOP Custom PIN Example](examples/byop-custom-pin.md)
- [JWT Authentication - enable_byop](concepts/jwt-authentication.md#enable-byop)

**Handle page refreshes:**
- [Auto-Reconnection Example](examples/auto-reconnection.md)
- [Session Lifecycle - Recovery](concepts/session-lifecycle.md#session-recovery)

**Integrate with npm (not CDN):**
- [BYOP Custom PIN Example](examples/byop-custom-pin.md)
- [Distribution Methods](concepts/distribution-methods.md#npm-integration)

**Debug session connection issues:**
- [Common Issues](troubleshooting/common-issues.md)
- [Error Codes](troubleshooting/error-codes.md)
- [Session Events - session_error](examples/session-events.md#session-error)

**Configure CORS and CSP headers:**
- [CORS and CSP Guide](troubleshooting/cors-csp.md)
- [Browser Compatibility](troubleshooting/browser-compatibility.md)

## By Error Code

Quick lookup for error code solutions:

### Session Errors
- **1001** (SESSION_START_FAILED) → [Error Codes](troubleshooting/error-codes.md#1001-session-start-failed)
- **1002** (SESSION_CONNECTING_IN_PROGRESS) → [Error Codes](troubleshooting/error-codes.md#1002-session-connecting-in-progress)
- **1004** (SESSION_COUNT_LIMIT) → [Error Codes](troubleshooting/error-codes.md#1004-session-count-limit)
- **1011** (SESSION_JOIN_FAILED) → [Error Codes](troubleshooting/error-codes.md#1011-session-join-failed)
- **1012** (SESSION_CUSTOMER_COUNT_LIMIT) → [Error Codes](troubleshooting/error-codes.md#1012-session-customer-count-limit)
- **1013** (SESSION_AGENT_COUNT_LIMIT) → [Error Codes](troubleshooting/error-codes.md#1013-session-agent-count-limit)
- **1015** (SESSION_DUPLICATE_USER) → [Error Codes](troubleshooting/error-codes.md#1015-session-duplicate-user)
- **1016** (NETWORK_ERROR) → [Error Codes](troubleshooting/error-codes.md#1016-network-error)
- **1017** (SESSION_CANCELING_IN_PROGRESS) → [Error Codes](troubleshooting/error-codes.md#1017-session-canceling-in-progress)

### PIN Errors
- **1006** (SESSION_JOIN_PIN_NOT_FOUND) → [Error Codes](troubleshooting/error-codes.md#1006-session-join-pin-not-found)
- **1008** (SESSION_PIN_INVALID_FORMAT) → [Error Codes](troubleshooting/error-codes.md#1008-session-pin-invalid-format)
- **1009** (SESSION_START_PIN_REQUIRED) → [Error Codes](troubleshooting/error-codes.md#1009-session-start-pin-required)
- **1010** (SESSION_START_PIN_CONFLICT) → [Error Codes](troubleshooting/error-codes.md#1010-session-start-pin-conflict)

### Auth Errors
- **2001** (TOKEN_INVALID) → [Error Codes](troubleshooting/error-codes.md#2001-token-invalid)

### Service Errors
- **9999** (UNDEFINED) → [Error Codes](troubleshooting/error-codes.md#9999-undefined)

## Official Resources

External documentation and samples:

- **Official Docs**: https://developers.zoom.us/docs/cobrowse-sdk/
- **API Reference**: https://marketplacefront.zoom.us/sdk/cobrowse/
- **Quickstart Repo**: https://github.com/zoom/CobrowseSDK-Quickstart
- **Auth Endpoint Sample**: https://github.com/zoom/cobrowsesdk-auth-endpoint-sample
- **Dev Forum**: https://devforum.zoom.us/
- **Developer Blog**: https://developers.zoom.us/blog/?category=zoom-cobrowse-sdk

## Documentation Structure

```
cobrowse-sdk/
├── SKILL.md                    # Main skill entry point
├── SKILL.md                    # This file - complete navigation
├── get-started.md              # Step-by-step setup guide
│
├── concepts/                   # Core concepts
│   ├── two-roles-pattern.md
│   ├── session-lifecycle.md
│   ├── jwt-authentication.md
│   └── distribution-methods.md
│
├── examples/                   # Working examples
│   ├── customer-integration.md
│   ├── agent-integration.md
│   ├── annotations.md
│   ├── privacy-masking.md
│   ├── remote-assist.md
│   ├── multi-tab-persistence.md
│   ├── byop-custom-pin.md
│   ├── session-events.md
│   └── auto-reconnection.md
│
├── references/                 # API and config references
│   ├── api-reference.md        # SDK methods
│   ├── settings-reference.md   # Init settings
│   ├── session-events.md       # Event types
│   ├── error-codes.md          # Error reference
│   ├── get-started.md          # Official docs (crawled)
│   ├── features.md             # Official docs (crawled)
│   ├── authorization.md        # Official docs (crawled)
│   └── api.md                  # API docs (crawled)
│
└── troubleshooting/            # Problem resolution
    ├── common-issues.md
    ├── error-codes.md
    ├── cors-csp.md
    └── browser-compatibility.md
```

## Search Tips

**Find by keyword:**
- "annotation" → [Annotation Tools](examples/annotations.md)
- "mask" or "privacy" → [Privacy Masking](examples/privacy-masking.md)
- "PIN" or "custom PIN" → [BYOP Custom PIN](examples/byop-custom-pin.md)
- "JWT" or "token" → [JWT Authentication](concepts/jwt-authentication.md)
- "error" → [Error Codes](troubleshooting/error-codes.md)
- "CORS" or "CSP" → [CORS and CSP](troubleshooting/cors-csp.md)
- "iframe" → [Agent Integration](examples/agent-integration.md)
- "npm" → [Distribution Methods](concepts/distribution-methods.md), [BYOP](examples/byop-custom-pin.md)
- "refresh" or "reconnect" → [Auto-Reconnection](examples/auto-reconnection.md)
- "agent" → [Agent Integration](examples/agent-integration.md), [Two Roles Pattern](concepts/two-roles-pattern.md)
- "customer" → [Customer Integration](examples/customer-integration.md), [Two Roles Pattern](concepts/two-roles-pattern.md)

---

**Not finding what you need?** Check the [Official Documentation](https://developers.zoom.us/docs/cobrowse-sdk/) or ask on the [Dev Forum](https://devforum.zoom.us/).

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/contact-center/android', 'business', 'android', '', 'android', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Contact Center SDK - Android

Official docs:
- https://developers.zoom.us/docs/contact-center/android/
- https://marketplacefront.zoom.us/sdk/contact/android/index.html

## Quick Links

1. [concepts/sdk-lifecycle.md](concepts/sdk-lifecycle.md)
2. [examples/service-patterns.md](examples/service-patterns.md)
3. [references/android-reference-map.md](references/android-reference-map.md)
4. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## SDK Surface Summary

- SDK manager: `ZoomCCInterface`
- Channel services:
- `getZoomCCChatService()`
- `getZoomCCVideoService()`
- `getZoomCCZVAService()`
- `getZoomCCScheduledCallbackService()`
- Campaign support via web campaign service and campaign metadata.

## Hard Guardrails

- Initialize SDK in `Application.onCreate`.
- Use `ZoomCCItem` to define channel + identifiers.
- Use `entryId` for chat/video/ZVA.
- Use `apiKey` for scheduled callback and campaign mode.
- Release services on teardown.

## Common Chains

- Contact Center app and engagement context: [../../zoom-apps-sdk/SKILL.md](../../zoom-apps-sdk/SKILL.md)
- Contact Center API automation: [../../rest-api/SKILL.md](../../rest-api/SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/contact-center/ios', 'business', 'ios', '', 'ios', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Contact Center SDK - iOS

Official docs:
- https://developers.zoom.us/docs/contact-center/ios/
- https://marketplacefront.zoom.us/sdk/contact/ios/index.html

## Quick Links

1. [concepts/sdk-lifecycle.md](concepts/sdk-lifecycle.md)
2. [examples/service-patterns.md](examples/service-patterns.md)
3. [references/ios-reference-map.md](references/ios-reference-map.md)
4. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## SDK Surface Summary

- Manager: `ZoomCCInterface.sharedInstance()`
- Context: `ZoomCCContext`
- Items: `ZoomCCItem`
- Services:
- `chatService`
- `zvaService`
- `videoService`
- `scheduledCallbackService`

## Hard Guardrails

- Set `ZoomCCContext` before channel operations.
- Forward app lifecycle calls (`appDidBecomeActive`, `appDidEnterBackgroud`, `appWillResignActive`, `appWillTerminate`).
- Use item-based initialization for channels.
- Keep rejoin URL handling connected to the video service path.

## Common Chains

- Contact Center apps in Zoom client: [../../zoom-apps-sdk/SKILL.md](../../zoom-apps-sdk/SKILL.md)
- OAuth and identity: [../../oauth/SKILL.md](../../oauth/SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/contact-center', 'business', 'contact-center', '', 'contact-center', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-contact-center-app

Background reference for Zoom Contact Center integrations across app, web, and native mobile surfaces.

Implementation guidance for Zoom Contact Center across:
- Contact Center apps in the Zoom client (Zoom Apps SDK path)
- Web channel embeds (chat/video/campaign)
- Native mobile SDKs (Android/iOS)

Official docs:
- https://developers.zoom.us/docs/contact-center/
- https://developers.zoom.us/docs/contact-center/web/sdk-reference/
- https://marketplacefront.zoom.us/sdk/contact/android/index.html
- https://marketplacefront.zoom.us/sdk/contact/ios/index.html

## Routing Guardrail

- If the user is building an app inside the Zoom Contact Center desktop client, stay on the Zoom Apps SDK path and use this skill plus `zoom-apps-sdk`.
- If the user is embedding chat/video widgets on a website, route to [web/SKILL.md](web/SKILL.md).
- If the user is integrating native Android or iOS SDK binaries, route to [android/SKILL.md](android/SKILL.md) or [ios/SKILL.md](ios/SKILL.md).
- If the user needs Contact Center call-control or queue APIs, chain with [../rest-api/SKILL.md](../rest-api/SKILL.md).

## Quick Links

Start here:
1. [concepts/architecture-and-lifecycle.md](concepts/architecture-and-lifecycle.md)
2. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
3. [references/forum-top-questions.md](references/forum-top-questions.md)
4. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
5. [references/samples-validation.md](references/samples-validation.md)
6. [references/environment-variables.md](references/environment-variables.md)
7. [troubleshooting/common-drift-and-breaks.md](troubleshooting/common-drift-and-breaks.md)
8. [RUNBOOK.md](RUNBOOK.md)

Platform skills:
- [android/SKILL.md](android/SKILL.md)
- [ios/SKILL.md](ios/SKILL.md)
- [web/SKILL.md](web/SKILL.md)

## Documentation Structure

```
contact-center/
├── SKILL.md
├── RUNBOOK.md
├── concepts/
│   └── architecture-and-lifecycle.md
├── scenarios/
│   └── high-level-scenarios.md
├── references/
│   ├── versioning-and-compatibility.md
│   ├── samples-validation.md
│   └── environment-variables.md
├── troubleshooting/
│   └── common-drift-and-breaks.md
├── android/
│   ├── SKILL.md
│   ├── concepts/sdk-lifecycle.md
│   ├── examples/service-patterns.md
│   ├── references/android-reference-map.md
│   └── troubleshooting/common-issues.md
├── ios/
│   ├── SKILL.md
│   ├── concepts/sdk-lifecycle.md
│   ├── examples/service-patterns.md
│   ├── references/ios-reference-map.md
│   └── troubleshooting/common-issues.md
└── web/
    ├── SKILL.md
    ├── concepts/lifecycle-and-events.md
    ├── examples/app-context-and-state.md
    ├── references/web-reference-map.md
    └── troubleshooting/common-issues.md
```

## Common Lifecycle Pattern

1. Initialize platform context early.
2. Build a channel item (`entryId` for chat/video/ZVA, `apiKey` for scheduled callback and campaign flows).
3. Get service/client instance.
4. Register listeners/delegates before user interaction.
5. Start flow (`fetchUI`, `startVideo`, or web SDK open/show path).
6. Handle engagement state changes (`start`, `hold`, `resume`, `end`) and context switching.
7. End flow and release resources (`endChat`/`endVideo`, `logout/logoff`, uninitialize/release).

## High-Level Scenarios

- Agent side-panel app that stores notes per `engagementId` and survives context switching.
- Browser chat/video campaigns launched from web tags.
- Native mobile customer app for chat/video/scheduled callback.
- Campaign-driven channel selection (chat, ZVA, video, scheduled callback).
- Rejoin flow for dropped video engagements on mobile.
- Smart Embed CRM softphone with postMessage event contracts.

See [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md) for details.

## Chaining

- Auth and in-client app identity: [../zoom-apps-sdk/SKILL.md](../zoom-apps-sdk/SKILL.md) and [../oauth/SKILL.md](../oauth/SKILL.md)
- Contact Center REST workflows: [../rest-api/SKILL.md](../rest-api/SKILL.md)
- Cobrowse on web voice/chat channels: [../cobrowse-sdk/SKILL.md](../cobrowse-sdk/SKILL.md)

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/contact-center/web', 'business', 'web', '', 'web', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Contact Center SDK - Web

Official docs:
- https://developers.zoom.us/docs/contact-center/web/
- https://developers.zoom.us/docs/contact-center/web/sdk-reference/

## Quick Links

1. [concepts/lifecycle-and-events.md](concepts/lifecycle-and-events.md)
2. [examples/app-context-and-state.md](examples/app-context-and-state.md)
3. [references/web-reference-map.md](references/web-reference-map.md)
4. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Integration Modes

1. Contact Center App in Zoom client:
- Zoom Apps SDK engagement APIs/events.

2. External website embed:
- Campaign SDK/web scripts (`zoomCampaignSdk` pattern).
- Video client initialization pattern.

3. Smart Embed:
- iframe + `postMessage` event contract.

## Hard Guardrails

- For campaign SDK, gate calls behind `zoomCampaignSdk:ready`.
- Persist state by `engagementId`.
- Expect context switching and background app behavior.
- Validate CSP and allow-list settings before debugging logic.

## Chaining

- For in-client app APIs and auth flows: [../../zoom-apps-sdk/SKILL.md](../../zoom-apps-sdk/SKILL.md)
- For identity and OAuth: [../../oauth/SKILL.md](../../oauth/SKILL.md)
- For cobrowse workflow: [../../cobrowse-sdk/SKILL.md](../../cobrowse-sdk/SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/debug-zoom', 'business', 'debug-zoom', '', 'debug-zoom', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /debug-zoom

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Debug Zoom auth, API, webhook, SDK, or MCP issues without wandering through the entire docs set.

## Usage

```text
/debug-zoom $ARGUMENTS
```

## Workflow

1. Identify the failing layer: auth, API request, webhook, SDK init, media/session behavior, or MCP transport.
2. Ask for the minimum missing evidence: exact error, platform, request/response, event payload, or code path.
3. Produce 2-4 plausible causes ranked by likelihood.
4. Route to the most relevant deep references in `skills/`.
5. Give a short verification plan so the user can confirm the fix.

## Output

- Most likely failure layer
- Ranked hypotheses
- Targeted fix steps
- Verification checklist
- Relevant skill links

## Related Skills

- [debug-zoom-integration](../debug-zoom-integration/SKILL.md)
- [setup-zoom-oauth](../setup-zoom-oauth/SKILL.md)
- [design-mcp-workflow](../design-mcp-workflow/SKILL.md)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/debug-zoom-integration', 'business', 'debug-zoom-integration', '', 'debug-zoom-integration', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Debug Zoom Integration

Use this skill when the user already built something and it is failing.

## Triage Order

1. Auth and app configuration
2. Request construction or event verification
3. SDK initialization or platform mismatch
4. Media/session behavior
5. MCP transport and capability assumptions

## Evidence To Request

- Exact error text
- Platform and SDK/runtime
- Relevant request or payload sample
- What worked versus what failed
- Whether the issue is reproducible or intermittent

## Reference Routing

- [oauth](../oauth/SKILL.md)
- [rest-api](../rest-api/SKILL.md)
- [webhooks](../webhooks/SKILL.md)
- [meeting-sdk](../meeting-sdk/SKILL.md)
- [video-sdk](../video-sdk/SKILL.md)
- [rtms](../rtms/SKILL.md)
- [zoom-mcp](../zoom-mcp/SKILL.md)

## Output

- Most likely failing layer
- Ranked hypotheses
- Short fix plan
- Verification steps$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/design-mcp-workflow', 'business', 'design-mcp-workflow', '', 'design-mcp-workflow', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Design MCP Workflow

Use this skill when the user wants Claude or another MCP-capable client to interact with Zoom via tool calls instead of only deterministic API code.

## Covers

- MCP fit assessment
- REST API vs MCP boundaries
- Hybrid architectures
- Connector expectations
- Whiteboard-specific MCP routing

## Workflow

1. Decide whether the problem is agentic tooling, deterministic automation, or both.
2. Route MCP-only tasks to [zoom-mcp](../zoom-mcp/SKILL.md).
3. Route hybrid tasks to both [zoom-mcp](../zoom-mcp/SKILL.md) and [rest-api](../rest-api/SKILL.md).
4. If Whiteboard is central, route to [zoom-mcp/whiteboard](../zoom-mcp/whiteboard/SKILL.md).
5. Call out transport, auth, and client capability assumptions explicitly.

## Common Mistakes

- Using MCP for deterministic backend jobs that should stay in REST
- Treating MCP as a replacement for all API design
- Ignoring client transport support and auth requirements$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/general', 'business', 'general', '', 'general', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom General (Cross-Product Skills)

Background reference for cross-product Zoom questions. Prefer the workflow skills first, then use this file for shared platform guidance and routing detail.

## How `zoom-general` Routes a Complex Developer Query

Use `zoom-general` as the classifier and chaining layer:

1. detect product signals in the query
2. pick one primary skill
3. attach secondary skills for auth, events, or deployment edges
4. ask one short clarifier only when two routes match with similar confidence

Minimal implementation:

```ts
type SkillId =
  | 'zoom-general'
  | 'zoom-rest-api'
  | 'zoom-webhooks'
  | 'zoom-oauth'
  | 'zoom-meeting-sdk-web-component-view'
  | 'zoom-video-sdk'
  | 'zoom-mcp';

const hasAny = (q: string, words: string[]) => words.some((w) => q.includes(w));

function detectSignals(rawQuery: string) {
  const q = rawQuery.toLowerCase();
  return {
    meetingCustomUi: hasAny(q, ['zoom meeting', 'custom ui', 'component view', 'embed meeting']),
    customVideo: hasAny(q, ['video sdk', 'custom video session', 'peer-video-state-change']),
    restApi: hasAny(q, ['rest api', '/v2/', 'create meeting', 'list users', 's2s oauth']),
    webhooks: hasAny(q, ['webhook', 'x-zm-signature', 'event subscription', 'crc']),
    oauth: hasAny(q, ['oauth', 'pkce', 'token refresh', 'account_credentials']),
    mcp: hasAny(q, ['zoom mcp', 'agentic retrieval', 'tools/list', 'semantic meeting search']),
  };
}

function pickPrimarySkill(s: ReturnType<typeof detectSignals>): SkillId {
  if (s.meetingCustomUi) return 'zoom-meeting-sdk-web-component-view';
  if (s.mcp) return 'zoom-mcp';
  if (s.restApi) return 'zoom-rest-api';
  if (s.customVideo) return 'zoom-video-sdk';
  return 'zoom-general';
}

function buildChain(primary: SkillId, s: ReturnType<typeof detectSignals>): SkillId[] {
  const chain = [primary];
  if (s.oauth && !chain.includes('zoom-oauth')) chain.push('zoom-oauth');
  if (s.webhooks && !chain.includes('zoom-webhooks')) chain.push('zoom-webhooks');
  return chain;
}
```

Example:

- `Create a meeting, configure webhooks, and handle OAuth token refresh` ->
  `zoom-rest-api -> zoom-oauth -> zoom-webhooks`
- `Build a custom video UI for a Zoom meeting on web` ->
  `zoom-meeting-sdk-web-component-view`

For the full TypeScript implementation and handoff contract, use
[references/routing-implementation.md](references/routing-implementation.md).

## Choose Your Path

| I want to... | Use this skill |
|--------------|----------------|
| Build a custom web UI around a real Zoom meeting | **[zoom-meeting-sdk-web-component-view](../meeting-sdk/web/component-view/SKILL.md)** |
| Build deterministic automation/configuration/reporting with explicit request control | **[zoom-rest-api](../rest-api/SKILL.md)** |
| Receive event notifications (HTTP push) | **[zoom-webhooks](../webhooks/SKILL.md)** |
| Receive event notifications (WebSocket, low-latency) | **[zoom-websockets](../websockets/SKILL.md)** |
| Embed Zoom meetings in my app | **[zoom-meeting-sdk](../meeting-sdk/SKILL.md)** |
| Build custom video experiences (Web, React Native, Flutter, Android, iOS, macOS, Unity, Linux) | **[zoom-video-sdk](../video-sdk/SKILL.md)** |
| Build an app that runs inside Zoom client | **[zoom-apps-sdk](../zoom-apps-sdk/SKILL.md)** |
| Transcribe uploaded or stored media with AI Services Scribe | **[scribe](../scribe/SKILL.md)** |
| Access live audio/video/transcripts from meetings | **[zoom-rtms](../rtms/SKILL.md)** |
| Enable collaborative browsing for support | **[zoom-cobrowse-sdk](../cobrowse-sdk/SKILL.md)** |
| Build Contact Center apps and channel integrations | **[contact-center](../contact-center/SKILL.md)** |
| Build Virtual Agent web/mobile chatbot experiences | **[virtual-agent](../virtual-agent/SKILL.md)** |
| Build Zoom Phone integrations (Smart Embed, Phone API, webhooks, URI flows) | **[phone](../phone/SKILL.md)** |
| Build Team Chat apps and integrations | **[zoom-team-chat](../team-chat/SKILL.md)** |
| Build server-side integrations with Rivet (auth + webhooks + APIs) | **[rivet-sdk](../rivet-sdk/SKILL.md)** |
| Run browser/device/network preflight diagnostics before join | **[probe-sdk](../probe-sdk/SKILL.md)** |
| Add pre-built UI components for Video SDK | **[zoom-ui-toolkit](../ui-toolkit/SKILL.md)** |
| Implement OAuth authentication (all grant types) | **[zoom-oauth](../oauth/SKILL.md)** |
| Build AI-driven tool workflows (AI Companion/agents) over Zoom data | **[zoom-mcp](../zoom-mcp/SKILL.md)** |
| Build AI-driven Whiteboard workflows over Zoom Whiteboard MCP | **[zoom-mcp/whiteboard](../zoom-mcp/whiteboard/SKILL.md)** |
| Build enterprise AI systems with stable API core + AI tool layer | **[zoom-rest-api](../rest-api/SKILL.md)** + **[zoom-mcp](../zoom-mcp/SKILL.md)** |

## Planning Checkpoint: Rivet SDK (Optional)

When a user starts planning a server-side integration that combines auth + webhooks + API calls, ask this first:

- `Rivet SDK is a Node.js framework that bundles Zoom auth handling, webhook receivers, and typed API wrappers.`
- `Do you want to use Rivet SDK for faster scaffolding, or do you prefer a direct OAuth + REST implementation without Rivet?`

Routing after answer:

- If user chooses Rivet: chain `rivet-sdk` + `oauth` + `rest-api`.
- If user declines Rivet: chain `oauth` + `rest-api` (+ `webhooks` or product skill as needed).

### SDK vs REST Routing Matrix (Hard Stop)

| User intent | Correct path | Do not route to |
|-------------|--------------|-----------------|
| Embed Zoom meeting in app UI | `zoom-meeting-sdk` | REST-only `join_url` flow |
| Build custom web UI for a real Zoom meeting | `zoom-meeting-sdk-web-component-view` | `zoom-video-sdk` |
| Build custom video UI/session app | `zoom-video-sdk` | Meeting SDK or REST meeting links |
| Get browser join links / manage meeting resources | `zoom-rest-api` | Meeting SDK join implementation |

Routing guardrails:
- If user asks for SDK embed/join behavior, stay in SDK path.
- If the prompt says **meeting** plus **custom UI/video/layout/embed**, prefer `zoom-meeting-sdk-web-component-view`.
- Only use `zoom-video-sdk` when the user is building a custom session product rather than a Zoom meeting.
- Only use REST path for resource management, reporting, or link distribution unless user explicitly requests a mixed architecture.
- For executable classification/chaining logic and error handling, see [references/routing-implementation.md](references/routing-implementation.md).

### API vs MCP Routing Matrix (Hard Stop)

| User intent | Correct path | Why |
|-------------|--------------|-----|
| Deterministic backend automation, account/user configuration, reporting, scheduled jobs | `zoom-rest-api` | Explicit request/response control and repeatable behavior |
| AI agent chooses tools dynamically, cross-platform AI tool interoperability | `zoom-mcp` | MCP is optimized for dynamic tool discovery and agentic workflows |
| Enterprise AI architecture (stable core + adaptive AI layer) | `zoom-rest-api + zoom-mcp` | APIs run core system actions; MCP exposes curated AI tools/context |

Routing guardrails:
- Do not replace deterministic backend APIs with MCP-only routing.
- Do not force raw REST-first routing when the task is AI-agent tool orchestration.
- Prefer hybrid routing when the user needs both stable automation and AI-driven interactions.
- MCP remote server works over Streamable HTTP/SSE; use this path when the target client/agent supports MCP transports (for example Claude or VS Code).
- Do not design per-tenant custom MCP endpoint provisioning; Zoom MCP endpoints are shared at instance/cluster level.
- Source: https://developers.zoom.us/docs/mcp/library/resources/apis-vs-mcp/

### Ambiguity Resolution (Ask Before Routing)

When a prompt matches both API and MCP paths with similar confidence, ask one short clarifier before execution:

- `Do you want deterministic REST API automation, AI-agent MCP tooling, or a hybrid of both?`

Then route as:
- REST answer → `zoom-rest-api`
- MCP answer → `zoom-mcp`
- Hybrid answer → `zoom-rest-api + zoom-mcp`

### MCP Availability and Topology Notes

- Zoom-hosted MCP access is evolving; docs indicate a model where Zoom exposes product-scoped MCP servers (for example Meetings, Team Chat, Whiteboard).
- Use `zoom-mcp` as the parent MCP entry point.
- Route Whiteboard-specific MCP requests to **[zoom-mcp/whiteboard](../zoom-mcp/whiteboard/SKILL.md)**.
- When a request is product-specific and MCP coverage exists, route to that MCP product surface first; otherwise use REST/SDK skills for deterministic implementation.

### Webhooks vs WebSockets

Both receive event notifications, but differ in approach:

| Aspect | webhooks | zoom-websockets |
|--------|---------------|-----------------|
| Connection | HTTP POST to your endpoint | Persistent WebSocket |
| Latency | Higher | Lower |
| Security | Requires public endpoint | No exposed endpoint |
| Setup | Simpler | More complex |
| Best for | Most use cases | Real-time, security-sensitive |

## Common Use Cases

| Use Case | Description | Skills Needed |
|----------|-------------|---------------|
| [Meeting + Webhooks + OAuth Refresh](references/meeting-webhooks-oauth-refresh-orchestration.md) | Create a meeting, process real-time updates, and refresh OAuth tokens safely in one design | [zoom-rest-api](../rest-api/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) + [zoom-webhooks](../webhooks/SKILL.md) |
| [Scribe Transcription Pipeline](use-cases/scribe-transcription-pipeline.md) | Transcribe uploaded files or S3 archives with AI Services Scribe using fast mode or batch jobs | [scribe](../scribe/SKILL.md) + optional [zoom-rest-api](../rest-api/SKILL.md) + optional [zoom-webhooks](../webhooks/SKILL.md) |
| [APIs vs MCP Routing](use-cases/apis-vs-mcp-routing.md) | Decide whether to route to deterministic Zoom APIs, AI-driven MCP, or a hybrid design | [zoom-rest-api](../rest-api/SKILL.md) and/or [zoom-mcp](../zoom-mcp/SKILL.md) |
| [Custom Meeting UI (Web)](use-cases/custom-meeting-ui-web.md) | Build a custom video UI for a real Zoom meeting in a web app using Meeting SDK Component View | [zoom-meeting-sdk-web-component-view](../meeting-sdk/web/component-view/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [Meeting Automation](use-cases/meeting-automation.md) | Schedule, update, delete meetings programmatically | [zoom-rest-api](../rest-api/SKILL.md) |
| [Meeting Bots](use-cases/meeting-bots.md) | Build bots that join meetings for AI/transcription/recording | [meeting-sdk/linux](../meeting-sdk/linux/SKILL.md) + [zoom-rest-api](../rest-api/SKILL.md) + optional [zoom-webhooks](../webhooks/SKILL.md) |
| [High-Volume Meeting Platform](use-cases/high-volume-meeting-platform.md) | Design distributed meeting creation and event processing with retries, queues, and reconciliation | [zoom-rest-api](../rest-api/SKILL.md) + [zoom-webhooks](../webhooks/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [Recording & Transcription](use-cases/recording-transcription.md) | Download recordings, get transcripts | [zoom-webhooks](../webhooks/SKILL.md) + [zoom-rest-api](../rest-api/SKILL.md) |
| [Recording Download Pipeline](use-cases/recording-download-pipeline.md) | Auto-download recordings to your own storage (S3, GCS, etc.) | [zoom-webhooks](../webhooks/SKILL.md) + [zoom-rest-api](../rest-api/SKILL.md) |
| [Real-Time Media Streams](use-cases/real-time-media-streams.md) | Access live audio, video, transcripts via WebSocket | [zoom-rtms](../rtms/SKILL.md) + [zoom-webhooks](../webhooks/SKILL.md) |
| [In-Meeting Apps](use-cases/in-meeting-apps.md) | Build apps that run inside Zoom meetings | [zoom-apps-sdk](../zoom-apps-sdk/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [React Native Meeting Embed](use-cases/react-native-meeting-embed.md) | Embed meetings into iOS/Android React Native apps | [zoom-meeting-sdk-react-native](../meeting-sdk/react-native/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [Native Meeting SDK Multi-Platform Delivery](use-cases/native-meeting-sdk-multi-platform.md) | Align Android, iOS, macOS, and Unreal Meeting SDK implementations under one auth/version strategy | [zoom-meeting-sdk](../meeting-sdk/SKILL.md) + platform skills |
| [Native Video SDK Multi-Platform Delivery](use-cases/native-video-sdk-multi-platform.md) | Align Android, iOS, macOS, and Unity Video SDK implementations under one auth/version strategy | [zoom-video-sdk](../video-sdk/SKILL.md) + platform skills |
| [Electron Meeting Embed](use-cases/electron-meeting-embed.md) | Embed meetings into desktop Electron apps | [zoom-meeting-sdk-electron](../meeting-sdk/electron/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [Flutter Video Sessions](use-cases/flutter-video-sessions.md) | Build custom mobile video sessions in Flutter | [zoom-video-sdk-flutter](../video-sdk/flutter/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [React Native Video Sessions](use-cases/react-native-video-sessions.md) | Build custom mobile video sessions in React Native | [zoom-video-sdk-react-native](../video-sdk/react-native/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [Immersive Experiences](use-cases/immersive-experiences.md) | Custom video layouts with Layers API | [zoom-apps-sdk](../zoom-apps-sdk/SKILL.md) |
| [Collaborative Apps](use-cases/collaborative-apps.md) | Real-time shared state in meetings | [zoom-apps-sdk](../zoom-apps-sdk/SKILL.md) |
| [Contact Center App Lifecycle and Context Switching](use-cases/contact-center-app-lifecycle-and-context-switching.md) | Build Contact Center apps that handle engagement events and multi-engagement state | [contact-center](../contact-center/SKILL.md) + [zoom-apps-sdk](../zoom-apps-sdk/SKILL.md) |
| [Virtual Agent Campaign Web and Mobile Wrapper](use-cases/virtual-agent-campaign-web-mobile-wrapper.md) | Deliver one campaign-driven bot flow across web and native mobile wrappers | [virtual-agent](../virtual-agent/SKILL.md) + [contact-center](../contact-center/SKILL.md) |
| [Virtual Agent Knowledge Base Sync Pipeline](use-cases/virtual-agent-knowledge-base-sync-pipeline.md) | Sync external knowledge content into Zoom Virtual Agent using web sync or custom API connectors | [virtual-agent](../virtual-agent/SKILL.md) + [zoom-rest-api](../rest-api/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) |
| [Zoom Phone Smart Embed CRM Integration](use-cases/zoom-phone-smart-embed-crm.md) | Build CRM dialer and call logging flows using Smart Embed plus Phone APIs | [phone](../phone/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) + [zoom-webhooks](../webhooks/SKILL.md) |
| [Rivet Event-Driven API Orchestrator](use-cases/rivet-event-driven-api-orchestrator.md) | Build a Node.js backend that combines webhooks and API actions through Rivet module clients | [rivet-sdk](../rivet-sdk/SKILL.md) + [zoom-oauth](../oauth/SKILL.md) + [zoom-rest-api](../rest-api/SKILL.md) |
| [Probe SDK Preflight Readiness Gate](use-cases/probe-sdk-preflight-readiness-gate.md) | Add browser/device/network diagnostics and readiness policy before Meeting SDK or Video SDK joins | [probe-sdk](../probe-sdk/SKILL.md) + [zoom-meeting-sdk](../meeting-sdk/SKILL.md) or [zoom-video-sdk](../video-sdk/SKILL.md) |

## Complete Use-Case Index

- [APIs vs MCP Routing](use-cases/apis-vs-mcp-routing.md): choose API-only, MCP-only, or hybrid routing using official Zoom criteria.
- [AI Companion Integration](use-cases/ai-companion-integration.md): connect Zoom AI Companion capabilities into your app workflow.
- [AI Integration](use-cases/ai-integration.md): add summarization, transcription, or assistant logic using Zoom data surfaces.
- [Backend Automation (S2S OAuth)](use-cases/backend-automation-s2s-oauth.md): run server-side jobs with account-level OAuth credentials.
- [Collaborative Apps](use-cases/collaborative-apps.md): build shared in-meeting app state and interactions.
- [Contact Center Integration](use-cases/contact-center-integration.md): connect Zoom Contact Center signals into external systems.
- [Contact Center App Lifecycle and Context Switching](use-cases/contact-center-app-lifecycle-and-context-switching.md): implement event-driven engagement state and safe context switching in Contact Center apps.
- [Virtual Agent Campaign Web and Mobile Wrapper](use-cases/virtual-agent-campaign-web-mobile-wrapper.md): deploy campaign-based Virtual Agent chat across website and Android/iOS WebView wrappers.
- [Virtual Agent Knowledge Base Sync Pipeline](use-cases/virtual-agent-knowledge-base-sync-pipeline.md): automate knowledge-base ingestion with web sync strategy or custom API connector.
- [Zoom Phone Smart Embed CRM Integration](use-cases/zoom-phone-smart-embed-crm.md): integrate Smart Embed events, Phone APIs, and CRM workflows with migration-safe data handling.
- [Rivet Event-Driven API Orchestrator](use-cases/rivet-event-driven-api-orchestrator.md): build a Node.js backend that combines webhook handling and API orchestration with Rivet.
- [Probe SDK Preflight Readiness Gate](use-cases/probe-sdk-preflight-readiness-gate.md): run browser/device/network diagnostics before launching meeting or video session workflows.
- [Custom Video](use-cases/custom-video.md): decide between Video SDK and related components for custom session UX.
- [Custom Meeting UI (Web)](use-cases/custom-meeting-ui-web.md): use Meeting SDK Component View for a custom UI around a real Zoom meeting.
- [Scribe Transcription Pipeline](use-cases/scribe-transcription-pipeline.md): use AI Services Scribe for on-demand file transcription and batch archive processing.
- [Video SDK Bring Your Own Storage](use-cases/video-sdk-bring-your-own-storage.md): configure Video SDK cloud recordings to write directly to your own S3 bucket.
- [Customer Support Cobrowsing](use-cases/customer-support-cobrowsing.md): implement customer-agent collaborative browsing support flows.
- [Embed Meetings](use-cases/embed-meetings.md): embed Zoom meeting experience into your app.
- [Form Completion Assistant](use-cases/form-completion-assistant.md): build guided flows for form filling and completion assistance.
- [HD Video Resolution](use-cases/hd-video-resolution.md): enable and troubleshoot high-definition video requirements.
- [High-Volume Meeting Platform](use-cases/high-volume-meeting-platform.md): build distributed meeting creation and event processing with concrete fallback patterns.
- [Immersive Experiences](use-cases/immersive-experiences.md): use Zoom Apps Layers APIs for custom in-meeting visuals.
- [In-Meeting Apps](use-cases/in-meeting-apps.md): build Zoom Apps that run directly inside meeting and webinar contexts.
- [Marketplace Publishing](use-cases/marketplace-publishing.md): prepare and ship a Zoom app through Marketplace review.
- [Meeting Automation](use-cases/meeting-automation.md): create, update, and manage meetings programmatically.
- [Meeting Bots](use-cases/meeting-bots.md): build bots for meeting join, capture, and real-time analysis.
- [Native Meeting SDK Multi-Platform Delivery](use-cases/native-meeting-sdk-multi-platform.md): standardize Android, iOS, macOS, and Unreal Meeting SDK delivery with shared auth and version controls.
- [Native Video SDK Multi-Platform Delivery](use-cases/native-video-sdk-multi-platform.md): standardize Android, iOS, macOS, and Unity Video SDK delivery with shared auth and version controls.
- [Meeting Details with Events](use-cases/meeting-details-with-events.md): combine REST retrieval with webhook event streams.
- [Minutes Calculation](use-cases/minutes-calculation.md): compute usage and minute metrics across meetings/sessions.
- [Prebuilt Video UI](use-cases/prebuilt-video-ui.md): use UI Toolkit for faster Video SDK-based UI delivery.
- [QSS Monitoring](use-cases/qss-monitoring.md): monitor Zoom quality statistics and performance indicators.
- [Raw Recording](use-cases/raw-recording.md): capture raw streams for custom recording and processing pipelines.
- [Electron Meeting Embed](use-cases/electron-meeting-embed.md): embed meetings in an Electron desktop application.
- [Flutter Video Sessions](use-cases/flutter-video-sessions.md): build Video SDK sessions in Flutter mobile apps.
- [React Native Meeting Embed](use-cases/react-native-meeting-embed.md): embed Meeting SDK into React Native apps.
- [React Native Video Sessions](use-cases/react-native-video-sessions.md): build custom video sessions in React Native.
- [Real-Time Media Streams](use-cases/real-time-media-streams.md): consume live media/transcript streams via RTMS.
- [Recording Download Pipeline](use-cases/recording-download-pipeline.md): automate recording retrieval and storage pipelines.
- [Recording & Transcription](use-cases/recording-transcription.md): manage post-meeting recordings and transcript workflows.
- [Retrieve Meeting and Subscribe Events](use-cases/retrieve-meeting-and-subscribe-events.md): join REST meeting fetch with event subscriptions.
- [SaaS App OAuth Integration](use-cases/saas-app-oauth-integration.md): implement user-level OAuth in multi-tenant SaaS apps.
- [SDK Size Optimization](use-cases/sdk-size-optimization.md): reduce bundle/runtime footprint for SDK-based apps.
- [SDK Wrappers and GUI](use-cases/sdk-wrappers-gui.md): evaluate wrapper patterns and GUI frameworks around SDKs.
- [Team Chat LLM Bot](use-cases/team-chat-llm-bot.md): build a Team Chat bot with LLM-powered responses.
- [Testing and Development](use-cases/testing-development.md): local testing patterns, mocks, and safe development loops.
- [Token and Scope Troubleshooting](use-cases/token-and-scope-troubleshooting.md): debug OAuth scope and token mismatch issues.
- [Transcription Bot (Linux)](use-cases/transcription-bot-linux.md): run Linux meeting bots for live transcription workloads.
- [Usage Reporting and Analytics](use-cases/usage-reporting-analytics.md): collect and analyze usage/reporting data.
- [User and Meeting Creation](use-cases/user-and-meeting-creation.md): provision users and schedule meetings in one flow.
- [Web SDK Embedding](use-cases/web-sdk-embedding.md): embed meeting experiences in browser-based web apps.
- [Server-to-Server OAuth with Webhooks](use-cases/server-to-server-oauth-with-webhooks.md): combine account OAuth with event-driven backend processing.
- [Meeting Links vs Embedding](use-cases/meeting-links-vs-embedding.md): choose between `join_url` distribution and SDK embedding.
- [Enterprise App Deployment](use-cases/enterprise-app-deployment.md): deploy, govern, and operate Zoom integrations at enterprise scale.

## Prerequisites

1. Zoom account (Pro, Business, or Enterprise)
2. App created in [Zoom App Marketplace](https://marketplace.zoom.us/)
3. OAuth credentials (Client ID and Secret)

## References

- [Known Limitations & Quirks](references/known-limitations.md)

## Quick Start

1. Go to [marketplace.zoom.us](https://marketplace.zoom.us/)
2. Click **Develop** → **Build App**
3. Select app type (see [references/app-types.md](references/app-types.md))
4. Configure OAuth and scopes
5. Copy credentials to your application

## Detailed References

- **[references/authentication.md](references/authentication.md)** - OAuth 2.0, S2S OAuth, JWT patterns
- **[references/app-types.md](references/app-types.md)** - Decision guide for app types
- **[references/scopes.md](references/scopes.md)** - OAuth scopes reference
- **[references/marketplace.md](references/marketplace.md)** - Marketplace portal navigation
- **[references/query-routing-playbook.md](references/query-routing-playbook.md)** - Route complex queries to the right specialized skills
- **[references/interview-answer-routing.md](references/interview-answer-routing.md)** - Short interview-ready answer pattern for zoom-general routing
- **[references/routing-implementation.md](references/routing-implementation.md)** - Concrete TypeScript query classification and skill handoff contract
- **[references/automatic-skill-chaining-rest-webhooks.md](references/automatic-skill-chaining-rest-webhooks.md)** - Executable process for REST + webhook chained workflows
- **[references/meeting-webhooks-oauth-refresh-orchestration.md](references/meeting-webhooks-oauth-refresh-orchestration.md)** - Concrete design for meeting creation + webhook updates + OAuth token refresh
- **[references/distributed-meeting-fallback-architecture.md](references/distributed-meeting-fallback-architecture.md)** - High-volume distributed architecture with retries, circuit breakers, and reconciliation fallbacks
- **[references/community-repos.md](references/community-repos.md)** - Curated official Zoom sample repositories by product

## SDK Maintenance

- **[references/sdk-upgrade-guide.md](references/sdk-upgrade-guide.md)** - Version policy, upgrade steps
- **[references/sdk-upgrade-workflow.md](references/sdk-upgrade-workflow.md)** - Changelog + RSS, version-by-version reusable upgrade workflow
- **[references/sdk-logs-troubleshooting.md](references/sdk-logs-troubleshooting.md)** - Collecting SDK logs

## Resources

- **Official docs**: https://developers.zoom.us/
- **Marketplace**: https://marketplace.zoom.us/
- **Developer forum**: https://devforum.zoom.us/

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/android', 'business', 'android', '', 'android', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (Android)

Use this skill when building Android apps with embedded Zoom meeting capabilities.

## Start Here

1. [android.md](android.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/join-start-pattern.md](examples/join-start-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/android-reference-map.md](references/android-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Routing Notes

- Use **default UI** first for first successful join/start validation.
- Move to **custom UI** once auth, meeting state transitions, and permissions are stable.
- For signature/JWT mistakes, chain with [../../oauth/SKILL.md](../../oauth/SKILL.md) and [../references/signature-playbook.md](../references/signature-playbook.md).

## Key Sources

- Docs: https://developers.zoom.us/docs/meeting-sdk/android/
- API reference: https://marketplacefront.zoom.us/sdk/meeting/android/index.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$)
ON CONFLICT (skill_key) DO NOTHING;
