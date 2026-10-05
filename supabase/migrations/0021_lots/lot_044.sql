INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/setup-zoom-mcp', 'business', 'setup-zoom-mcp', '', 'setup-zoom-mcp', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /setup-zoom-mcp

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Plan a Zoom MCP workflow and decide when to use MCP alone versus a hybrid REST API + MCP architecture.

## Usage

```text
/setup-zoom-mcp $ARGUMENTS
```

## Workflow

1. Determine whether the goal is deterministic automation, AI tool orchestration, or a hybrid.
2. If MCP is appropriate, identify the likely Zoom MCP surface and transport assumptions.
3. If MCP alone is not enough, define the REST API responsibilities separately.
4. Call out auth, scope, and client capability constraints.
5. End with a minimal proof-of-concept sequence.

## Output

- Recommended MCP strategy
- Connector expectations
- Hybrid boundaries if REST is also required
- Risks and setup notes
- Relevant skill links

## Related Skills

- [design-mcp-workflow](../design-mcp-workflow/SKILL.md)
- [choose-zoom-approach](../choose-zoom-approach/SKILL.md)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/setup-zoom-oauth', 'business', 'setup-zoom-oauth', '', 'setup-zoom-oauth', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /setup-zoom-oauth

Use this skill when auth is the blocker or when auth choices will shape the entire integration.

## Scope

- App type selection
- OAuth grant selection
- Scope planning
- Token exchange and refresh
- Auth debugging and environment assumptions

## Workflow

1. Determine the app model and who is authorizing whom.
2. Choose the correct grant flow.
3. Identify minimum scopes for the user flow.
4. Define token storage and refresh behavior.
5. Route into the deepest relevant reference docs only after the above is clear.

## Primary References

- [oauth](../oauth/SKILL.md)
- [general](../general/SKILL.md)
- [rest-api](../rest-api/SKILL.md)

## Common Mistakes

- Picking a grant before clarifying the actor and tenant model
- Asking for broad scopes before confirming the exact workflow
- Forgetting refresh-token behavior and token lifecycle handling
- Reusing an old refresh token after a successful refresh instead of storing the newly returned one
- Treating auth failures as API failures without checking app configuration first$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/start', 'business', 'start', '', 'start', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Start

Use this as the default entry skill for the plugin.

## What This Skill Does

- Classifies the request by job-to-be-done, not by product name alone
- Routes into the right implementation skill
- Pulls in product-specific Zoom references only after the route is clear
- Prevents common early mistakes, especially Meeting SDK vs Video SDK and REST API vs MCP confusion

## Routing Table

| If the user wants to... | Route to |
|---|---|
| Choose the right Zoom surface for a new project | [plan-zoom-product](../plan-zoom-product/SKILL.md) |
| Set up OAuth, tokens, scopes, or app credentials | [setup-zoom-oauth](../setup-zoom-oauth/SKILL.md) |
| Embed or customize a Zoom meeting flow | [build-zoom-meeting-app](../build-zoom-meeting-app/SKILL.md) |
| Build a bot, recorder, or real-time meeting processor | [build-zoom-bot](../build-zoom-bot/SKILL.md) |
| Use Zoom-hosted MCP for AI workflows | [setup-zoom-mcp](../setup-zoom-mcp/SKILL.md) |
| Debug a broken integration | [debug-zoom](../debug-zoom/SKILL.md) |

## Supporting Zoom References

Use these only after selecting the workflow:

- [general](../general/SKILL.md)
- [rest-api](../rest-api/SKILL.md)
- [meeting-sdk](../meeting-sdk/SKILL.md)
- [video-sdk](../video-sdk/SKILL.md)
- [webhooks](../webhooks/SKILL.md)
- [websockets](../websockets/SKILL.md)
- [oauth](../oauth/SKILL.md)
- [zoom-mcp](../zoom-mcp/SKILL.md)

## Operating Rules

1. Prefer one clear recommendation over a product catalog dump.
2. Ask a short clarifier only when the route is genuinely ambiguous.
3. Keep the first response architectural and actionable, then go deep.
4. Pull in deeper references only when they directly help the current decision or implementation.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/team-chat', 'business', 'team-chat', '', 'team-chat', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-team-chat-app

Background reference for Zoom Team Chat integrations. Use this after the workflow is clear, especially when the Team Chat API versus Chatbot API distinction matters.

## Read This First (Critical)

There are two different integration types and they are not interchangeable:

1. **Team Chat API (user type)**
   - Sends messages as a real authenticated user
   - Uses **User OAuth** (`authorization_code`)
   - Endpoint family: `/v2/chat/users/...`

2. **Chatbot API (bot type)**
   - Sends messages as your bot identity
   - Uses **Client Credentials** (`client_credentials`)
   - Endpoint family: `/v2/im/chat/messages`

If you choose the wrong type early, auth/scopes/endpoints all mismatch and implementation fails.

**Official Documentation**: https://developers.zoom.us/docs/team-chat/  
**Chatbot Documentation**: https://developers.zoom.us/docs/team-chat/chatbot/extend/  
**API Reference**: https://developers.zoom.us/docs/api/rest/reference/chatbot/

## Quick Links

**New to Team Chat? Follow this path:**

1. **[Get Started](get-started.md)** - End-to-end fast path (user type vs bot type)
2. **[Choose Your API](concepts/api-selection.md)** - Team Chat API vs Chatbot API
3. **[Environment Setup](concepts/environment-setup.md)** - Credentials, scopes, app configuration
4. **[OAuth Setup](examples/oauth-setup.md)** - Complete authentication flow
5. **[Send First Message](examples/send-message.md)** - Working code to send messages

**Reference:**
- **[Chatbot Message Cards](references/message-cards.md)** - Complete card component reference
- **[Webhook Events](references/webhook-events.md)** - All webhook event types
- **[API Reference](references/api-reference.md)** - Endpoints, methods, parameters
- **[Sample Applications](references/samples.md)** - 10+ official sample apps
- **Integrated Index** - see the section below in this file

**Having issues?**
- Authentication errors → [OAuth Troubleshooting](troubleshooting/oauth-issues.md)
- Webhook not receiving events → [Webhook Setup Guide](troubleshooting/webhook-issues.md)
- Messages not sending → [Common Issues](troubleshooting/common-issues.md)
- Start with quick checks → [5-Minute Runbook](RUNBOOK.md)

**OAuth endpoint sanity check:**
- Authorize URL: `https://zoom.us/oauth/authorize`
- Token URL: `https://zoom.us/oauth/token`
- If `/oauth/token` returns 404/HTML, use `https://zoom.us/oauth/token`.

**Building Interactive Bots?**
- [Button Actions](examples/button-actions.md) - Handle button clicks
- [Form Submissions](examples/form-submissions.md) - Process form data
- [Slash Commands](examples/slash-commands.md) - Create custom commands

## Quick Decision: Which API?

| Use Case | API to Use |
|----------|------------|
| Send notifications from scripts/CI/CD | **Team Chat API** |
| Automate messages as a user | **Team Chat API** |
| Build an interactive chatbot | **Chatbot API** |
| Respond to slash commands | **Chatbot API** |
| Create messages with buttons/forms | **Chatbot API** |
| Handle user interactions | **Chatbot API** |

### Team Chat API (User-Level)
- Messages appear as sent by **authenticated user**
- Requires **User OAuth** (authorization_code flow)
- Endpoint: `POST https://api.zoom.us/v2/chat/users/me/messages`
- Scopes: `chat_message:write`, `chat_channel:read`

### Chatbot API (Bot-Level)
- Messages appear as sent by your **bot**
- Requires **Client Credentials** grant
- Endpoint: `POST https://api.zoom.us/v2/im/chat/messages`
- Scopes: `imchat:bot` (auto-added)
- **Rich cards**: buttons, forms, dropdowns, images

## Prerequisites

### System Requirements

- Zoom account
- Account owner, admin, or **Zoom for developers** role enabled
  - To enable: **User Management** → **Roles** → **Role Settings** → **Advanced features** → Enable **Zoom for developers**

### Create Zoom App

1. Go to [Zoom App Marketplace](https://marketplace.zoom.us/)
2. Click **Develop** → **Build App**
3. Select **General App** (OAuth)

> ⚠️ **Do NOT use Server-to-Server OAuth** - S2S apps don't have the Chatbot/Team Chat feature. Only General App (OAuth) supports chatbots.

### Required Credentials

From Zoom Marketplace → Your App:

| Credential | Location | Used By |
|------------|----------|---------|
| Client ID | App Credentials → Development | Both APIs |
| Client Secret | App Credentials → Development | Both APIs |
| Account ID | App Credentials → Development | Chatbot API |
| Bot JID | Features → Chatbot → Bot Credentials | Chatbot API |
| Secret Token | Features → Team Chat Subscriptions | Chatbot API |

**See**: [Environment Setup Guide](concepts/environment-setup.md) for complete configuration steps.

## Quick Start: Team Chat API

Send a message as a user:

```javascript
// 1. Get access token via OAuth
const accessToken = await getOAuthToken(); // See examples/oauth-setup.md

// 2. Send message to channel
const response = await fetch('https://api.zoom.us/v2/chat/users/me/messages', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    message: 'Hello from CI/CD pipeline!',
    to_channel: 'CHANNEL_ID'
  })
});

const data = await response.json();
// { "id": "msg_abc123", "date_time": "2024-01-15T10:30:00Z" }
```

**Complete example**: [Send Message Guide](examples/send-message.md)

## Quick Start: Chatbot API

Build an interactive chatbot:

```javascript
// 1. Get chatbot token (client_credentials)
async function getChatbotToken() {
  const credentials = Buffer.from(
    `${CLIENT_ID}:${CLIENT_SECRET}`
  ).toString('base64');
  
  const response = await fetch('https://zoom.us/oauth/token', {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: 'grant_type=client_credentials'
  });
  
  return (await response.json()).access_token;
}

// 2. Send chatbot message with buttons
const response = await fetch('https://api.zoom.us/v2/im/chat/messages', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    robot_jid: process.env.ZOOM_BOT_JID,
    to_jid: payload.toJid,           // From webhook
    account_id: payload.accountId,   // From webhook
    content: {
      head: {
        text: 'Build Notification',
        sub_head: { text: 'CI/CD Pipeline' }
      },
      body: [
        { type: 'message', text: 'Deployment successful!' },
        {
          type: 'fields',
          items: [
            { key: 'Branch', value: 'main' },
            { key: 'Commit', value: 'abc123' }
          ]
        },
        {
          type: 'actions',
          items: [
            { text: 'View Logs', value: 'view_logs', style: 'Primary' },
            { text: 'Dismiss', value: 'dismiss', style: 'Default' }
          ]
        }
      ]
    }
  })
});
```

**Complete example**: [Chatbot Setup Guide](examples/chatbot-setup.md)

## Key Features

### Team Chat API

| Feature | Description |
|---------|-------------|
| **Send Messages** | Post messages to channels or direct messages |
| **List Channels** | Get user's channels with metadata |
| **Create Channels** | Create public/private channels programmatically |
| **Threaded Replies** | Reply to specific messages in threads |
| **Edit/Delete** | Modify or remove messages |

### Chatbot API

| Feature | Description |
|---------|-------------|
| **Rich Message Cards** | Headers, images, fields, buttons, forms |
| **Slash Commands** | Custom `/commands` trigger webhooks |
| **Button Actions** | Interactive buttons with webhook callbacks |
| **Form Submissions** | Collect user input with forms |
| **Dropdown Selects** | Channel, member, date/time pickers |
| **LLM Integration** | Easy integration with Claude, GPT, etc. |

## Webhook Events (Chatbot API)

| Event | Trigger | Use Case |
|-------|---------|----------|
| `bot_notification` | User messages bot or uses slash command | Process commands, integrate LLM |
| `bot_installed` | Bot added to account | Initialize bot state |
| `interactive_message_actions` | Button clicked | Handle button actions |
| `chat_message.submit` | Form submitted | Process form data |
| `app_deauthorized` | Bot removed | Cleanup |

**See**: [Webhook Events Reference](references/webhook-events.md)

## Message Card Components

Build rich interactive messages with these components:

| Component | Description |
|-----------|-------------|
| **header** | Title and subtitle |
| **message** | Plain text |
| **fields** | Key-value pairs |
| **actions** | Buttons (Primary, Danger, Default styles) |
| **section** | Colored sidebar grouping |
| **attachments** | Images with links |
| **divider** | Horizontal line |
| **form_field** | Text input |
| **dropdown** | Select menu |
| **date_picker** | Date selection |

**See**: [Message Cards Reference](references/message-cards.md) for complete component catalog

## Architecture Patterns

### Chatbot Lifecycle

```
User types /command → Webhook receives bot_notification
                            ↓
                     payload.cmd = "user's input"
                            ↓
                     Process command
                            ↓
                     Send response via sendChatbotMessage()
```

### LLM Integration Pattern

```javascript
case 'bot_notification': {
  const { toJid, cmd, accountId } = payload;
  
  // 1. Call your LLM
  const llmResponse = await callClaude(cmd);
  
  // 2. Send response back
  await sendChatbotMessage(toJid, accountId, {
    body: [{ type: 'message', text: llmResponse }]
  });
}
```

**See**: [LLM Integration Guide](examples/llm-integration.md)

## Sample Applications

| Sample | Description | Link |
|--------|-------------|------|
| **Chatbot Quickstart** | Official tutorial (recommended start) | [GitHub](https://github.com/zoom/chatbot-nodejs-quickstart) |
| **Claude Chatbot** | AI chatbot with Anthropic Claude | [GitHub](https://github.com/zoom/zoom-chatbot-claude-sample) |
| **Unsplash Chatbot** | Image search with database | [GitHub](https://github.com/zoom/unsplash-chatbot) |
| **ERP Chatbot** | Oracle ERP with scheduled alerts | [GitHub](https://github.com/zoom/zoom-erp-chatbot-sample) |
| **Task Manager** | Full CRUD app | [GitHub](https://github.com/zoom/task-manager-sample) |

**See**: [Sample Applications Guide](references/samples.md) for analysis of all 10 samples

## Common Operations

### Send Message to Channel

```javascript
// Team Chat API
await fetch('https://api.zoom.us/v2/chat/users/me/messages', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: JSON.stringify({
    message: 'Hello!',
    to_channel: 'CHANNEL_ID'
  })
});
```

### Handle Button Click

```javascript
// Webhook handler
case 'interactive_message_actions': {
  const { actionItem, toJid, accountId } = payload;
  
  if (actionItem.value === 'approve') {
    await sendChatbotMessage(toJid, accountId, {
      body: [{ type: 'message', text: '✅ Approved!' }]
    });
  }
}
```

### Verify Webhook Signature

```javascript
function verifyWebhook(req) {
  const message = `v0:${req.headers['x-zm-request-timestamp']}:${JSON.stringify(req.body)}`;
  const hash = crypto.createHmac('sha256', process.env.ZOOM_VERIFICATION_TOKEN)
    .update(message)
    .digest('hex');
  return req.headers['x-zm-signature'] === `v0=${hash}`;
}
```

## Deployment

### ngrok for Local Development

```bash
# Install ngrok
npm install -g ngrok

# Expose local server
ngrok http 4000

# Use HTTPS URL as Bot Endpoint URL in Zoom Marketplace
# Example: https://abc123.ngrok.io/webhook
```

### Production Deployment

**See**: [Deployment Guide](concepts/deployment.md) for:
- Nginx reverse proxy setup
- Base path configuration
- OAuth redirect URI setup

## Limitations

| Limit | Value |
|-------|-------|
| Message length | 4,096 characters |
| File size | 512 MB |
| Members per channel | 10,000 |
| Channels per user | 500 |

## Security Best Practices

1. **Verify webhook signatures** - Always validate using `x-zm-signature` header
2. **Sanitize messages** - Limit to 4096 chars, remove control characters
3. **Validate JIDs** - Check format: `user@domain` or `channel@domain`
4. **Environment variables** - Never hardcode credentials
5. **Use HTTPS** - Required for production webhooks

**See**: [Security Best Practices](concepts/security.md)

## Complete Documentation Library

### Core Concepts (Start Here!)
- **[API Selection Guide](concepts/api-selection.md)** - Choose Team Chat API vs Chatbot API
- **[Environment Setup](concepts/environment-setup.md)** - Complete credentials guide
- **[Authentication Flows](concepts/authentication.md)** - OAuth vs Client Credentials
- **[Webhook Architecture](concepts/webhooks.md)** - How webhooks work
- **[Message Card Structure](concepts/message-structure.md)** - Card component hierarchy

### Complete Examples
- **[OAuth Setup](examples/oauth-setup.md)** - Full OAuth implementation
- **[Send Message](examples/send-message.md)** - Team Chat API message sending
- **[Chatbot Setup](examples/chatbot-setup.md)** - Complete chatbot with webhooks
- **[Button Actions](examples/button-actions.md)** - Handle interactive buttons
- **[Form Submissions](examples/form-submissions.md)** - Process form data
- **[Slash Commands](examples/slash-commands.md)** - Create custom commands
- **[LLM Integration](examples/llm-integration.md)** - Claude/GPT integration
- **[Scheduled Alerts](examples/scheduled-alerts.md)** - Cron + incoming webhooks
- **[Channel Management](examples/channel-management.md)** - Create/manage channels

### References
- **[API Reference](references/api-reference.md)** - All endpoints and methods
- **[Webhook Events](references/webhook-events.md)** - Complete event reference
- **[Message Cards](references/message-cards.md)** - All card components
- **[Sample Applications](references/samples.md)** - Analysis of 10 official samples
- **[Error Codes](references/error-codes.md)** - Error handling guide

### Troubleshooting
- **[OAuth Issues](troubleshooting/oauth-issues.md)** - Authentication failures
- **[Webhook Issues](troubleshooting/webhook-issues.md)** - Webhook debugging
- **[Common Issues](troubleshooting/common-issues.md)** - Quick diagnostics

## Resources

- **Official Docs**: https://developers.zoom.us/docs/team-chat/
- **API Reference**: https://developers.zoom.us/docs/api/rest/reference/chatbot/
- **Dev Forum**: https://devforum.zoom.us/
- **App Marketplace**: https://marketplace.zoom.us/

---

**Need help?** Start with Integrated Index section below for complete navigation.

---

## Integrated Index

_This section was migrated from `SKILL.md`._

Complete navigation guide for the Zoom Team Chat skill.

## Quick Start Paths

- Start here: [Get Started](get-started.md)
- Fast troubleshooting first: [5-Minute Runbook](RUNBOOK.md)

### Path 1: Team Chat API (User-Level Messaging)

For sending messages as a user account.

1. [API Selection Guide](concepts/api-selection.md) - Confirm Team Chat API is right
2. [Environment Setup](concepts/environment-setup.md) - Get credentials
3. [OAuth Setup Example](examples/oauth-setup.md) - Implement authentication
4. [Send Message Example](examples/send-message.md) - Send your first message

### Path 2: Chatbot API (Interactive Bots)

For building interactive chatbots with rich messages.

1. [API Selection Guide](concepts/api-selection.md) - Confirm Chatbot API is right
2. [Environment Setup](concepts/environment-setup.md) - Get credentials (including Bot JID)
3. [Webhook Architecture](concepts/webhooks.md) - Understand webhook events
4. [Chatbot Setup Example](examples/chatbot-setup.md) - Build your first bot
5. [Message Cards Reference](references/message-cards.md) - Create rich messages

## Core Concepts

Essential understanding for both APIs.

| Document | Description |
|----------|-------------|
| [API Selection Guide](concepts/api-selection.md) | Choose Team Chat API vs Chatbot API |
| [Environment Setup](concepts/environment-setup.md) | Complete credentials and app configuration |
| [Authentication Flows](concepts/authentication.md) | OAuth vs Client Credentials |
| [Webhook Architecture](concepts/webhooks.md) | How webhooks work (Chatbot API) |
| [Message Card Structure](concepts/message-structure.md) | Card component hierarchy |
| [Deployment Guide](concepts/deployment.md) | Production deployment strategies |
| [Security Best Practices](concepts/security.md) | Secure your integration |

## Complete Examples

Working code for common scenarios.

### Authentication
| Example | Description |
|---------|-------------|
| [OAuth Setup](examples/oauth-setup.md) | User OAuth flow implementation |
| [Token Management](examples/token-management.md) | Refresh tokens, expiration handling |

### Basic Operations
| Example | Description |
|---------|-------------|
| [Send Message](examples/send-message.md) | Team Chat API message sending |
| [Chatbot Setup](examples/chatbot-setup.md) | Complete chatbot with webhooks |
| [List Channels](examples/channel-management.md) | Get user's channels |
| [Create Channel](examples/channel-management.md) | Create public/private channels |

### Interactive Features (Chatbot API)
| Example | Description |
|---------|-------------|
| [Button Actions](examples/button-actions.md) | Handle button clicks |
| [Form Submissions](examples/form-submissions.md) | Process form data |
| [Slash Commands](examples/slash-commands.md) | Create custom commands |
| [Dropdown Selects](examples/dropdown-selects.md) | Channel/member pickers |

### Advanced Integration
| Example | Description |
|---------|-------------|
| [LLM Integration](examples/llm-integration.md) | Integrate Claude/GPT |
| [Scheduled Alerts](examples/scheduled-alerts.md) | Cron + incoming webhooks |
| [Database Integration](examples/database-integration.md) | Store conversation state |
| [Multi-Step Workflows](examples/multi-step-workflows.md) | Complex user interactions |

## References

### API Documentation
| Reference | Description |
|-----------|-------------|
| [API Reference](references/api-reference.md) | Pointers and common endpoints |
| [Webhook Events](references/webhook-events.md) | Event types and handling checklist |
| [Message Cards](references/message-cards.md) | All card components |
| [Error Codes](references/error-codes.md) | Error handling guide |

### Sample Applications
| Reference | Description |
|-----------|-------------|
| [Sample Applications](references/samples.md) | Sample app index/notes |

### Field Guides
| Reference | Description |
|-----------|-------------|
| [JID Formats](references/jid-formats.md) | Understanding JID identifiers |
| [Scopes Reference](references/scopes.md) | Common scopes |
| [Rate Limits](references/rate-limits.md) | Throttling guidance |

## Troubleshooting

| Guide | Description |
|-------|-------------|
| [Common Issues](troubleshooting/common-issues.md) | Quick diagnostics and solutions |
| [OAuth Issues](troubleshooting/oauth-issues.md) | Authentication failures |
| [Webhook Issues](troubleshooting/webhook-issues.md) | Webhook debugging |
| [Message Issues](troubleshooting/message-issues.md) | Message sending problems |
| [Deployment Issues](troubleshooting/deployment-issues.md) | Production problems |

## Architecture Patterns

### Chatbot Lifecycle

```
User Action → Webhook → Process → Response
```

### LLM Integration Pattern

```
User Input → Chatbot receives → Call LLM → Send response
```

### Approval Workflow Pattern

```
Request → Send card with buttons → User clicks → Update status → Notify
```

## Common Use Cases

### Notifications
- CI/CD build notifications
- Server monitoring alerts
- Scheduled reports
- System health checks

### Workflows
- Approval requests
- Task assignment
- Status updates
- Form submissions

### Integrations
- LLM-powered assistants
- Database queries
- External API integration
- File/image sharing

### Automation
- Scheduled messages
- Auto-responses
- Data collection
- Report generation

## Resource Links

### Official Documentation
- **[Team Chat Docs](https://developers.zoom.us/docs/team-chat/)** - Official overview
- **[Chatbot Docs](https://developers.zoom.us/docs/team-chat/chatbot/extend/)** - Chatbot guide
- **[API Reference](https://developers.zoom.us/docs/api/rest/reference/chatbot/)** - REST API docs
- **[App Marketplace](https://marketplace.zoom.us/)** - Create and manage apps

### Sample Code
- **[Chatbot Quickstart](https://github.com/zoom/chatbot-nodejs-quickstart)** - Official tutorial
- **[Claude Chatbot](https://github.com/zoom/zoom-chatbot-claude-sample)** - AI integration
- **[Unsplash Chatbot](https://github.com/zoom/unsplash-chatbot)** - Image search bot
- **[ERP Chatbot](https://github.com/zoom/zoom-erp-chatbot-sample)** - Enterprise integration
- **[Task Manager](https://github.com/zoom/task-manager-sample)** - Full CRUD app

### Tools
- **[App Card Builder](https://appssdk.zoom.us/cardbuilder/)** - Visual card designer
- **[ngrok](https://ngrok.com/)** - Local webhook testing
- **[Postman](https://www.postman.com/)** - API testing

### Community
- **[Developer Forum](https://devforum.zoom.us/)** - Ask questions
- **[GitHub Discussions](https://github.com/zoom)** - Community support
- **[Developer Support](https://devsupport.zoom.us)** - Official support

## Documentation Status

### ✅ Complete
- Main skill.md entry point
- API Selection Guide
- Environment Setup
- Webhook Architecture
- Chatbot Setup Example (complete working code)
- Message Cards Reference
- Common Issues Troubleshooting

### 📝 Pending (High Priority)
- OAuth Setup Example
- Send Message Example
- Button Actions Example
- LLM Integration Example
- Webhook Events Reference
- API Reference
- Sample Applications Analysis

### 📋 Planned (Lower Priority)
- Form Submissions Example
- Channel Management Examples
- Database Integration Example
- Error Codes Reference
- Rate Limits Guide
- Deployment troubleshooting

## Getting Started Checklist

### For Team Chat API

- [ ] Read [API Selection Guide](concepts/api-selection.md)
- [ ] Complete [Environment Setup](concepts/environment-setup.md)
- [ ] Obtain Client ID, Client Secret
- [ ] Add required scopes
- [ ] Implement OAuth flow
- [ ] Send first message

### For Chatbot API

- [ ] Read [API Selection Guide](concepts/api-selection.md)
- [ ] Complete [Environment Setup](concepts/environment-setup.md)
- [ ] Obtain Client ID, Client Secret, Bot JID, Secret Token, Account ID
- [ ] Enable Team Chat in Features
- [ ] Configure Bot Endpoint URL and Slash Command
- [ ] Set up ngrok for local testing
- [ ] Implement webhook handler
- [ ] Send first chatbot message

## Version History

- **v1.0** (2026-02-09) - Initial comprehensive documentation
  - Core concepts (API selection, environment setup, webhooks)
  - Complete chatbot setup example
  - Message cards reference
  - Common issues troubleshooting

## Support

Use this SKILL.md as the navigation hub for Team Chat API selection, setup, examples, and troubleshooting.

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/ui-toolkit', 'business', 'ui-toolkit', '', 'ui-toolkit', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK UI Toolkit

Background reference for the prebuilt Zoom Video SDK UI Toolkit on web. Prefer `choose-zoom-approach` first when the user might still need Meeting SDK instead.

**Official Documentation**: https://developers.zoom.us/docs/video-sdk/web/ui-toolkit/
**API Reference**: https://marketplacefront.zoom.us/sdk/uitoolkit/web/
**NPM Package**: https://www.npmjs.com/package/@zoom/videosdk-zoom-ui-toolkit
**Live Demo**: https://sdk.zoom.com/videosdk-uitoolkit

## Quick Links

**New to UI Toolkit? Follow this path:**

1. **Quick Start** - Get running in 5 minutes (see below)
2. **JWT Authentication** - Server-side token generation (required)
3. **Composite vs Components** - Choose your approach  
4. **Framework Integration** - React, Vue, Angular, Next.js patterns
5. **Integrated Index** - see the section below in this file

**Having issues?**
- Session not joining → Check JWT Authentication (most common issue)
- React 18 peer dependency error → See Installation section
- CSS not loading → See [Troubleshooting](troubleshooting/common-issues.md)
- Components not showing → Check Component Lifecycle
- Start with preflight checks → [5-Minute Runbook](RUNBOOK.md)

## Overview

The Zoom Video SDK UI Toolkit is a **pre-built video UI library** that renders complete video conferencing experiences with minimal code. Unlike the raw Video SDK, the UI Toolkit provides:

- ✅ **Ready-to-use UI** - Professional video interface out of the box
- ✅ **Zero UI code** - No need to build video layouts, controls, or participant management
- ✅ **Framework agnostic** - Works with React, Vue, Angular, Next.js, vanilla JS
- ✅ **Highly customizable** - Choose which features to enable, customize themes
- ✅ **Built-in features** - Chat, screen share, settings, virtual backgrounds included

**When to use UI Toolkit:**
- You want a complete video solution quickly
- You need Zoom-like UI consistency
- You don't want to build custom video UI
- You need standard features (chat, share, participants)

**When to use raw Video SDK instead:**
- You need complete custom UI control
- You're building a non-standard video experience
- You need access to raw video/audio data
- You want to build your own rendering pipeline

## Installation

```bash
npm install @zoom/videosdk-zoom-ui-toolkit jsrsasign
npm install -D @types/jsrsasign
```

**Note**: React support depends on the UI Toolkit version. Check the package peer dependencies for your installed version (React 18 is commonly required).

## Quick Start

### Basic Usage (Vanilla JS)

```javascript
import uitoolkit from "@zoom/videosdk-zoom-ui-toolkit";
import "@zoom/videosdk-ui-toolkit/dist/videosdk-zoom-ui-toolkit.css";

const container = document.getElementById("sessionContainer");

const config = {
  videoSDKJWT: "your_jwt_token",
  sessionName: "my-session",
  userName: "John Doe",
  sessionPasscode: "",
  features: ["video", "audio", "share", "chat", "users", "settings"],
};

uitoolkit.joinSession(container, config);

uitoolkit.onSessionJoined(() => {
  console.log("Session joined");
});

uitoolkit.onSessionClosed(() => {
  console.log("Session closed");
});
```

### Next.js / React Integration

```typescript
'use client';

import { useEffect, useRef } from 'react';

export default function VideoSession({ jwt, sessionName, userName }) {
  const containerRef = useRef<HTMLDivElement>(null);
  const uitoolkitRef = useRef<any>(null);

  useEffect(() => {
    let isMounted = true;

    const init = async () => {
      const uitoolkitModule = await import('@zoom/videosdk-zoom-ui-toolkit');
      const uitoolkit = uitoolkitModule.default;
      uitoolkitRef.current = uitoolkit;
      
      // If TypeScript complains about CSS imports, configure your app to allow them
      // (for example via a global `declare module \"*.css\";`), or import the CSS from
      // a global entrypoint (Next.js layout/_app) instead of inlining here.
      await import('@zoom/videosdk-ui-toolkit/dist/videosdk-zoom-ui-toolkit.css');

      if (!isMounted || !containerRef.current) return;

      const config: any = {
        videoSDKJWT: jwt,
        sessionName: sessionName,
        userName: userName,
        sessionPasscode: '',
        features: ['video', 'audio', 'share', 'chat', 'users', 'settings'],
      };

      uitoolkit.joinSession(containerRef.current, config);
      uitoolkit.onSessionJoined(() => console.log('Joined'));
      uitoolkit.onSessionClosed(() => console.log('Closed'));
    };

    init();

    return () => {
      isMounted = false;
      if (uitoolkitRef.current && containerRef.current) {
        try {
          uitoolkitRef.current.closeSession(containerRef.current);
        } catch (e) {}
      }
    };
  }, [jwt, sessionName, userName]);

  return <div ref={containerRef} style={{ width: '100%', height: '100vh' }} />;
}
```

## Available Features

| Feature | Description |
|---------|-------------|
| `video` | Enable video layout and send/receive video |
| `audio` | Show audio button, send/receive audio |
| `share` | Screen sharing |
| `chat` | In-session messaging |
| `users` | Participant list |
| `settings` | Device selection, virtual background |
| `preview` | Pre-join camera/mic preview |
| `recording` | Cloud recording (paid plan) |
| `leave` | Leave/end session button |

## Troubleshooting

- **[troubleshooting/common-issues.md](troubleshooting/common-issues.md)** - CSS, SSR, JWT/session join, customization limits

## JWT Token Generation (Server-Side)

**Required**: Generate JWT tokens on your server, never expose SDK secret client-side.

### Node.js / Next.js API Route

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { KJUR } from 'jsrsasign';

const ZOOM_VIDEO_SDK_KEY = process.env.ZOOM_VIDEO_SDK_KEY;
const ZOOM_VIDEO_SDK_SECRET = process.env.ZOOM_VIDEO_SDK_SECRET;

export async function POST(request: NextRequest) {
  const { sessionName, role, userName } = await request.json();

  if (!sessionName || role === undefined) {
    return NextResponse.json({ error: 'Missing params' }, { status: 400 });
  }

  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 60 * 60 * 2; // 2 hours

  const oHeader = { alg: 'HS256', typ: 'JWT' };
  const oPayload = {
    app_key: ZOOM_VIDEO_SDK_KEY,
    role_type: role, // 0 = participant, 1 = host
    tpc: sessionName,
    version: 1,
    iat,
    exp,
    user_identity: userName || 'User',
  };

  const signature = KJUR.jws.JWS.sign(
    'HS256',
    JSON.stringify(oHeader),
    JSON.stringify(oPayload),
    ZOOM_VIDEO_SDK_SECRET
  );

  return NextResponse.json({ signature });
}
```

### JWT Payload Fields

| Field | Required | Description |
|-------|----------|-------------|
| `app_key` | Yes | Your Video SDK Key |
| `role_type` | Yes | 0 = participant, 1 = host |
| `tpc` | Yes | Session/topic name |
| `version` | Yes | Always 1 |
| `iat` | Yes | Issued at (Unix timestamp) |
| `exp` | Yes | Expiration (Unix timestamp) |
| `user_identity` | No | User identifier |

## API Reference

### Core Methods

```javascript
uitoolkit.joinSession(container, config);
uitoolkit.closeSession(container);
```

### Event Listeners

```javascript
uitoolkit.onSessionJoined(callback);
uitoolkit.onSessionClosed(callback);
uitoolkit.offSessionJoined(callback);
uitoolkit.offSessionClosed(callback);
```

### Component Methods

```javascript
uitoolkit.showChatComponent(container);
uitoolkit.hideChatComponent(container);
uitoolkit.showUsersComponent(container);
uitoolkit.hideUsersComponent(container);
uitoolkit.showControlsComponent(container);
uitoolkit.hideControlsComponent(container);
uitoolkit.showSettingsComponent(container);
uitoolkit.hideSettingsComponent(container);
uitoolkit.hideAllComponents();
```

## CDN Usage (No Build Step)

```html
<link rel="stylesheet" href="https://source.zoom.us/uitoolkit/2.3.5-1/videosdk-zoom-ui-toolkit.css" />
<script src="https://source.zoom.us/uitoolkit/2.3.5-1/videosdk-zoom-ui-toolkit.min.umd.js"></script>

<div id="sessionContainer"></div>

<script>
  const uitoolkit = window.UIToolkit;
  
  uitoolkit.joinSession(document.getElementById('sessionContainer'), {
    videoSDKJWT: 'your_jwt',
    sessionName: 'my-session',
    userName: 'User',
    features: ['video', 'audio', 'chat']
  });
</script>
```

## Next.js with basePath

When deploying Next.js under a subpath:

```typescript
// next.config.ts
const nextConfig = {
  basePath: "/your-app-path",
  assetPrefix: "/your-app-path",
};
```

Fetch API routes with full path:
```typescript
fetch('/your-app-path/api/token', { ... })
```

## Prerequisites

1. **Zoom Video SDK credentials** from [Zoom Marketplace](https://marketplace.zoom.us/)
2. **React** version compatible with your installed UI Toolkit package (check peer deps; React 18 is common)
3. **Server-side JWT generation** (never expose SDK secret)
4. **Modern browser** with WebRTC support

## Browser Support

| Browser | Version |
|---------|---------|
| Chrome | 78+ |
| Firefox | 76+ |
| Safari | 14.1+ |
| Edge | 79+ |

## Common Issues

| Issue | Solution |
|-------|----------|
| `peer react@"^18.0.0"` error | Use the React version required by the installed UI Toolkit package (check peer deps; React 18 is common) |
| CSS import TypeScript error | Configure TS/CSS handling (prefer a global `*.css` module declaration); avoid `@ts-ignore` except in throwaway demos |
| Config type error | Type config as `any` |
| API returns HTML not JSON | Check basePath in fetch URL |

## Resources

- **GitHub**: https://github.com/zoom/videosdk-zoom-ui-toolkit-web
- **UI Toolkit Docs**: https://developers.zoom.us/docs/video-sdk/web/ui-toolkit/
- **Auth Endpoint Sample**: https://github.com/zoom/videosdk-auth-endpoint-sample
- **Marketplace**: https://marketplace.zoom.us/

---

## Integrated Index

_This section was migrated from `SKILL.md`._

Complete navigation for all UI Toolkit documentation.

## 📚 Start Here

New to the UI Toolkit? Follow this learning path:

1. **[SKILL.md](SKILL.md)** - Main overview and quick start
2. **[5-Minute Runbook](RUNBOOK.md)** - Preflight checks before deep debugging
3. **Quick Start Guide** - Working code in 5 minutes (see skill.md)
4. **JWT Authentication** - Server-side token generation (see skill.md)
5. **Choose Your Mode** - Composite vs Components (see skill.md)

## 🎯 Core Concepts

Understanding how UI Toolkit works:

- **Composite vs Components** - Two ways to use UI Toolkit (see skill.md)
- **UI Toolkit Architecture** - How it wraps Video SDK internally
- **Feature Configuration** - Understanding featuresOptions structure
- **Session Lifecycle** - Join → Active → Leave/Close → Destroy flow

## 📖 Complete Guides

### Getting Started
- **Installation** - NPM install and React 18 setup (see skill.md)
- **Quick Start - Composite** - Full UI in one container (see skill.md)
- **Quick Start - Components** - Individual UI pieces (see skill.md)
- **JWT Authentication** - Server-side token generation (see skill.md)

### Framework Integration
- **React Integration** - Hooks, useEffect patterns (see skill.md)
- **Vue.js Integration** - Composition API and Options API (see skill.md)
- **Angular Integration** - Component lifecycle (see skill.md)
- **Next.js Integration** - App Router, Server Components (see skill.md)
- **Vanilla JavaScript** - No framework usage (see skill.md)

### Advanced Topics
- **Component Lifecycle** - Mount, unmount, cleanup patterns
- **Event Listeners** - React to session events
- **Session Management** - Programmatic control
- **Quality Statistics** - Monitor connection quality
- **Custom Themes** - Theme customization
- **Virtual Backgrounds** - Custom background images

## 📚 API Reference

Complete API documentation:

- **Core Methods** (see skill.md)
  - `joinSession()` - Start a video session
  - `closeSession()` - End session and remove UI
  - `destroy()` - Clean up UI Toolkit instance
  - `leaveSession()` - Leave without destroying UI

- **Component Methods** (see skill.md)
  - `showControlsComponent()` - Display control bar
  - `showChatComponent()` - Display chat panel
  - `showUsersComponent()` - Display participants list
  - `showSettingsComponent()` - Display settings panel
  - `hideAllComponents()` - Hide all components

- **Event Listeners** (see skill.md)
  - `onSessionJoined()` - Session joined successfully
  - `onSessionClosed()` - Session ended
  - `onSessionDestroyed()` - UI Toolkit destroyed
  - `onViewTypeChange()` - View mode changed
  - `on()` - Subscribe to Video SDK events
  - `off()` - Unsubscribe from events

- **Information Methods** (see skill.md)
  - `getSessionInfo()` - Get session details
  - `getCurrentUserInfo()` - Get current user
  - `getAllUser()` - Get all participants
  - `getClient()` - Get underlying Video SDK client
  - `version()` - Get version info

- **Control Methods** (see skill.md)
  - `changeViewType()` - Switch view mode
  - `mirrorVideo()` - Mirror self video
  - `isSupportCustomLayout()` - Check device support

- **Statistics Methods** (see skill.md)
  - `subscribeAudioStatisticData()` - Audio quality stats
  - `subscribeVideoStatisticData()` - Video quality stats
  - `subscribeShareStatisticData()` - Share quality stats

## 🔧 Configuration

- **Feature Configuration** (see skill.md)
  - `featuresOptions` structure
  - Audio/Video options
  - Chat, Users, Settings
  - Virtual Background
  - Recording, Captions (paid features)
  - Theme customization
  - View modes

- **Session Configuration** (see skill.md)
  - Required: `videoSDKJWT`, `sessionName`, `userName`
  - Optional: `sessionPasscode`, `sessionIdleTimeoutMins`
  - Debug mode
  - Web endpoint
  - Language settings

## ⚠️ Troubleshooting

### Common Issues
- React 18 peer dependency error
- JWT token invalid
- CSS not loading
- Components not showing
- Session join failures

See: **[troubleshooting/common-issues.md](troubleshooting/common-issues.md)**

### Framework-Specific Issues
- React: SSR, hydration, cleanup
- Vue: Reactivity, lifecycle
- Angular: Module imports, AOT
- Next.js: App Router, basePath

### Session Issues
- Authentication failures
- Connection problems
- Video/audio not working
- Screen share issues

## 📦 Sample Applications

**Official Repositories**:

| Framework | Repository | Key Features |
|-----------|------------|--------------|
| React | [videosdk-zoom-ui-toolkit-react-sample](https://github.com/zoom/videosdk-zoom-ui-toolkit-react-sample) | Hooks, TypeScript |
| Vue.js | [videosdk-zoom-ui-toolkit-vuejs-sample](https://github.com/zoom/videosdk-zoom-ui-toolkit-vuejs-sample) | Composition API |
| Angular | [videosdk-zoom-ui-toolkit-angular-sample](https://github.com/zoom/videosdk-zoom-ui-toolkit-angular-sample) | Services, Guards |
| JavaScript | [videosdk-zoom-ui-toolkit-javascript-sample](https://github.com/zoom/videosdk-zoom-ui-toolkit-javascript-sample) | Vanilla JS |
| Auth Endpoint | [videosdk-auth-endpoint-sample](https://github.com/zoom/videosdk-auth-endpoint-sample) | Node.js JWT |

## 🌐 External Resources

- **Official Documentation**: https://developers.zoom.us/docs/video-sdk/web/ui-toolkit/
- **API Reference**: https://marketplacefront.zoom.us/sdk/uitoolkit/web/
- **NPM Package**: https://www.npmjs.com/package/@zoom/videosdk-zoom-ui-toolkit
- **Marketplace**: https://marketplace.zoom.us/
- **Developer Forum**: https://devforum.zoom.us/
- **Live Demo**: https://sdk.zoom.com/videosdk-uitoolkit
- **Changelog**: https://developers.zoom.us/changelog/ui-toolkit/web/

## 🎓 Learning Path

### Beginner
1. Read [SKILL.md](SKILL.md) overview
2. Follow Quick Start - Composite
3. Generate JWT on server
4. Join your first session
5. Explore available features

### Intermediate
1. Try Component Mode
2. Add event listeners
3. Customize theme
4. Add virtual backgrounds
5. Integrate with your framework

### Advanced
1. Access underlying Video SDK
2. Subscribe to quality statistics
3. Handle all edge cases
4. Implement custom layouts
5. Build production-ready app

## 📋 Quick Reference Card

### Minimal Working Example

```javascript
import uitoolkit from "@zoom/videosdk-zoom-ui-toolkit";
import "@zoom/videosdk-ui-toolkit/dist/videosdk-zoom-ui-toolkit.css";

const config = {
  videoSDKJWT: "YOUR_JWT",
  sessionName: "test-session",
  userName: "User",
  featuresOptions: {
    video: { enable: true },
    audio: { enable: true }
  }
};

uitoolkit.joinSession(document.getElementById("container"), config);
uitoolkit.onSessionJoined(() => console.log("Joined"));
uitoolkit.onSessionClosed(() => uitoolkit.destroy());
```

### Must-Remember Rules

1. ✅ **Always** generate JWT server-side
2. ✅ **Always** call `destroy()` on cleanup
3. ✅ **Always** use React 18 (not 17/19)
4. ✅ **Always** import CSS file
5. ❌ **Never** expose SDK secret client-side
6. ❌ **Never** skip `onSessionClosed` cleanup
7. ❌ **Never** call components before `joinSession`

## 📞 Support

- **Developer Forum**: https://devforum.zoom.us/
- **Developer Support**: https://developers.zoom.us/support/
- **Premier Support**: https://explore.zoom.us/en/support-plans/developer/

---

**Navigation**: [← Back to SKILL.md](SKILL.md)

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/android', 'business', 'android', '', 'android', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK (Android)

Use this skill when building Android apps with custom real-time video sessions.

## Start Here

1. [android.md](android.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/session-join-pattern.md](examples/session-join-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/android-reference-map.md](references/android-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Key Sources

- Docs: https://developers.zoom.us/docs/video-sdk/android/
- API reference: https://marketplacefront.zoom.us/sdk/custom/android/index.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/flutter', 'business', 'flutter', '', 'flutter', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK (Flutter)

Use this skill for Flutter apps that build custom real-time video session experiences with Zoom Video SDK.

## Quick Links

1. **[Lifecycle Workflow](concepts/lifecycle-workflow.md)** - init -> joinSession -> media/control -> leave -> cleanup
2. **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - helper-based API surface and event model
3. **[High-Level Scenarios](concepts/high-level-scenarios.md)** - common product patterns
4. **[Setup Guide](examples/setup-guide.md)** - package setup + platform prerequisites
5. **[Session Join Pattern](examples/session-join-pattern.md)** - tokenized session join flow
6. **[Event Handling Pattern](examples/event-handling-pattern.md)** - listener mapping and action routing
7. **[SKILL.md](SKILL.md)** - complete navigation

## Core Notes

- Video SDK sessions are custom sessions, not Zoom Meetings.
- Keep SDK credentials server-side; generate JWT token on backend.
- Integration is strongly event-driven; bind listener flows early.
- Feature support and enum names can drift by wrapper/native version.

## References

- [Flutter Reference Index](references/flutter-reference.md)
- [Module Map](references/module-map.md)
- [Official Sources](references/official-sources.md)
- [Deprecated and Contradictions](troubleshooting/deprecated-and-contradictions.md)

## Related Skills

- [zoom-video-sdk](../SKILL.md)
- [zoom-oauth](../../oauth/SKILL.md)
- [zoom-general](../../general/SKILL.md)


## Merged from video-sdk/flutter/SKILL.md

# Zoom Video SDK Flutter - Documentation Index

## Start Here

1. [SKILL.md](SKILL.md)
2. [Lifecycle Workflow](concepts/lifecycle-workflow.md)
3. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)
4. [Setup Guide](examples/setup-guide.md)

## Concepts

- [Lifecycle Workflow](concepts/lifecycle-workflow.md)
- [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)
- [High-Level Scenarios](concepts/high-level-scenarios.md)

## Examples

- [Setup Guide](examples/setup-guide.md)
- [Session Join Pattern](examples/session-join-pattern.md)
- [Event Handling Pattern](examples/event-handling-pattern.md)

## References

- [Flutter Reference Index](references/flutter-reference.md)
- [Module Map](references/module-map.md)
- [Official Sources](references/official-sources.md)

## Troubleshooting

- [Common Issues](troubleshooting/common-issues.md)
- [Version Drift](troubleshooting/version-drift.md)
- [Deprecated and Contradictions](troubleshooting/deprecated-and-contradictions.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/ios', 'business', 'ios', '', 'ios', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK (iOS)

Use this skill when building custom iOS video session experiences.

## Start Here

1. [ios.md](ios.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/session-join-pattern.md](examples/session-join-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/ios-reference-map.md](references/ios-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Key Sources

- Docs: https://developers.zoom.us/docs/video-sdk/ios/
- API reference: https://marketplacefront.zoom.us/sdk/custom/ios/annotated.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/linux', 'business', 'linux', '', 'linux', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK - Linux Development

Expert guidance for developing with the Zoom Video SDK on Linux. Build headless bots, raw media capture/injection applications, and custom UI integrations with Qt/GTK.

**Official Documentation**: https://developers.zoom.us/docs/video-sdk/linux/
**API Reference**: https://marketplacefront.zoom.us/sdk/custom/linux/
**Sample Repository**: https://github.com/zoom/videosdk-linux-raw-recording-sample

## Quick Links

**New to Video SDK? Follow this path:**

1. **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - Universal 3-step pattern for ANY feature
2. **[Session Join Pattern](examples/session-join-pattern.md)** - Complete working code to join a session
3. **[Raw Data vs Canvas](concepts/raw-data-vs-canvas.md)** - **CRITICAL**: Linux has NO Canvas API - raw data ONLY
4. **[Raw Video Capture](examples/raw-video-capture.md)** - Capture and process YUV420 frames

**Reference:**
- **[Singleton Hierarchy](concepts/singleton-hierarchy.md)** - 5-level SDK navigation map
- **[API Reference](references/linux-reference.md)** - Complete API documentation
- **[Qt/GTK Integration](examples/qt-gtk-integration.md)** - UI framework patterns
- **[Troubleshooting](troubleshooting/common-issues.md)** - Quick diagnostics
- **[SKILL.md](SKILL.md)** - Complete documentation navigation

**Having issues?**
- PulseAudio setup → [PulseAudio Guide](troubleshooting/pulseaudio-setup.md)
- Qt dependencies → [Qt Dependencies](troubleshooting/qt-dependencies.md)
- Build errors → [Build Errors Guide](troubleshooting/build-errors.md)

## Key Differences from Windows/macOS

| Feature | Linux | Windows/Mac |
|---------|-------|-------------|
| **Canvas API** | ❌ Not available | ✅ Available |
| **Raw Data Pipe** | ✅ **ONLY option** | ✅ Available |
| **UI Integration** | Qt, GTK, SDL2, OpenGL | Win32/WinForms/WPF, Cocoa |
| **Headless Support** | ✅ Excellent (Docker) | Limited |
| **Audio** | PulseAudio required | Native |
| **Virtual Devices** | ✅ Required for headless | Optional |

## SDK Overview

The Zoom Video SDK for Linux is a C++ library optimized for:
- **Headless Bots**: Docker/WSL support, no display required
- **Raw Data Access**: Capture YUV420 video, PCM audio
- **Raw Data Injection**: Virtual camera/mic for custom media
- **Screen Sharing**: Capture or inject share data
- **Cloud Recording**: Record sessions to Zoom cloud
- **Live Streaming**: Stream to RTMP endpoints
- **Live Transcription**: Real-time speech-to-text
- **Qt/GTK Integration**: Full UI framework support

## Prerequisites

### System Requirements

- **OS**: Ubuntu 20.04+, Debian 11+, or compatible
- **Architecture**: x64 (recommended), ARM64
- **Compiler**: GCC 9+, Clang 10+
- **CMake**: 3.14 or later
- **Qt5**: Bundled with SDK (do NOT install system Qt5)

### Dependencies

```bash
sudo apt update
sudo apt install -y build-essential gcc cmake libglib2.0-dev liblzma-dev \
    libxcb-image0 libxcb-keysyms1 libxcb-xfixes0 libxcb-xkb1 libxcb-shape0 \
    libxcb-shm0 libxcb-randr0 libxcb-xtest0 libgbm1 libxtst6 libgl1 libnss3 \
    libasound2 libpulse0

# For headless Linux
sudo apt install -y pulseaudio

# PulseAudio configuration (CRITICAL for audio)
mkdir -p ~/.config
echo "[General]" > ~/.config/zoomus.conf
echo "system.audio.type=default" >> ~/.config/zoomus.conf

# Log directory
mkdir -p ~/.zoom/logs
```

## Quick Start

```cpp
#include "zoom_video_sdk_api.h"
#include "zoom_video_sdk_interface.h"
#include "zoom_video_sdk_delegate_interface.h"

USING_ZOOM_VIDEO_SDK_NAMESPACE

// 1. Create SDK
IZoomVideoSDK* sdk = CreateZoomVideoSDKObj();

// 2. Initialize
ZoomVideoSDKInitParams init_params;
init_params.domain = "https://zoom.us";
init_params.enableLog = true;
init_params.logFilePrefix = "bot";
init_params.videoRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.shareRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.audioRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;

sdk->initialize(init_params);

// 3. Add delegate
sdk->addListener(myDelegate);

// 4. Join session
ZoomVideoSDKSessionContext ctx;
ctx.sessionName = "my-session";
ctx.userName = "Linux Bot";
ctx.token = "jwt-token";
ctx.audioOption.connect = true;
ctx.audioOption.mute = false;
ctx.videoOption.localVideoOn = false;

// For headless: Virtual audio speaker
ctx.virtualAudioSpeaker = new VirtualSpeaker();

IZoomVideoSDKSession* session = sdk->joinSession(ctx);
```

See **[Session Join Pattern](examples/session-join-pattern.md)** for complete code.

## Key Features

| Feature | Linux Support | Guide |
|---------|---------------|-------|
| **Session Management** | ✅ Full | [Session Join](examples/session-join-pattern.md) |
| **Raw Video (YUV420)** | ✅ ONLY rendering option | [Raw Video](examples/raw-video-capture.md) |
| **Raw Audio (PCM)** | ✅ Full | [Raw Audio](examples/raw-audio-capture.md) |
| **Virtual Camera/Mic** | ✅ Full | [Virtual Devices](examples/virtual-audio-video.md) |
| **Cloud Recording** | ✅ Full | [Recording](examples/cloud-recording.md) |
| **Live Streaming** | ✅ Full | [Live Stream](examples/live-streaming.md) |
| **Live Transcription** | ✅ Full | [Transcription](examples/transcription.md) |
| **Command Channel** | ✅ Full | [Commands](examples/command-channel.md) |
| **Chat** | ✅ Full | [Chat](examples/chat.md) |
| **Qt Integration** | ✅ Recommended | [Qt/GTK](examples/qt-gtk-integration.md) |
| **GTK Integration** | ✅ Supported | [Qt/GTK](examples/qt-gtk-integration.md) |
| **Docker/Headless** | ✅ Excellent | [Virtual Devices](examples/virtual-audio-video.md) |

## Critical Gotchas

### ⚠️ CRITICAL #1: No Canvas API on Linux

**Problem**: Linux SDK does NOT have Canvas API like Windows/Mac.

**Solution**: You MUST use Raw Data Pipe and implement your own rendering.

See: **[Raw Data vs Canvas](concepts/raw-data-vs-canvas.md)**

### ⚠️ CRITICAL #2: PulseAudio Required for Audio

**Problem**: SDK requires PulseAudio for raw audio functions.

**Solution**:
```bash
sudo apt install -y pulseaudio
mkdir -p ~/.config
echo "[General]" > ~/.config/zoomus.conf
echo "system.audio.type=default" >> ~/.config/zoomus.conf
```

See: **[PulseAudio Setup](troubleshooting/pulseaudio-setup.md)**

### ⚠️ CRITICAL #3: Qt5 Dependencies

**Problem**: SDK requires Qt5 libraries (bundled, NOT system Qt5).

**Solution**:
```bash
# Copy from SDK package
cp -r samples/qt_libs/Qt/lib/* lib/zoom_video_sdk/

# Create symlinks
cd lib/zoom_video_sdk
for lib in libQt5*.so.5; do ln -sf $lib ${lib%.5}; done
```

See: **[Qt Dependencies](troubleshooting/qt-dependencies.md)**

### ⚠️ CRITICAL #4: Heap Memory Mode

Always use heap mode for raw data:

```cpp
init_params.videoRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.shareRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
init_params.audioRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
```

### ⚠️ CRITICAL #5: Virtual Audio for Headless

**Problem**: Docker/headless environments have no audio devices.

**Solution**: Use virtual audio speaker and mic.

```cpp
session_context.virtualAudioSpeaker = new VirtualSpeaker();
session_context.virtualAudioMic = new VirtualMic();
```

See: **[Virtual Audio/Video](examples/virtual-audio-video.md)**

## Sample Repositories

### Official Samples

| Repository | Description |
|-----------|-------------|
| **[raw-recording-sample](https://github.com/zoom/videosdk-linux-raw-recording-sample)** | Raw audio/video capture |
| **[qt-quickstart](https://github.com/tanchunsiong/videosdk-linux-qt-quickstart)** | Qt6 UI integration |
| **[gtk-quickstart](https://github.com/tanchunsiong/videosdk-linux-gtk-quickstart)** | GTK3 UI integration |

### Sample Architecture

```
Headless Bot (Docker):
┌──────────────────────────────────┐
│  Virtual Audio Speaker/Mic       │
├──────────────────────────────────┤
│  Raw Data Processing             │
│  - YUV420 → File/Stream   


## Merged from video-sdk/linux/SKILL.md

# Zoom Video SDK Linux - Complete Documentation Index

## Quick Start Path

**If you're new to the SDK, follow this order:**

1. **Read the architecture pattern** → [concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)
   - Universal formula: Singleton → Delegate → Subscribe
   - Once you understand this, you can implement any feature

2. **Understand Linux specifics** → [concepts/raw-data-vs-canvas.md](concepts/raw-data-vs-canvas.md)
   - **CRITICAL**: Linux has NO Canvas API - raw data ONLY

3. **Implement session join** → [examples/session-join-pattern.md](examples/session-join-pattern.md)
   - Complete working JWT + session join code

4. **Setup environment** → [troubleshooting/pulseaudio-setup.md](troubleshooting/pulseaudio-setup.md)
   - PulseAudio configuration (required for audio)
   - [troubleshooting/qt-dependencies.md](troubleshooting/qt-dependencies.md)
   - Qt5 library setup (bundled with SDK)

5. **Implement features** → Choose from examples below

---

## Documentation Structure

```
video-sdk/linux/
├── SKILL.md                          # Main skill overview
├── SKILL.md                          # This file - navigation guide
├── linux.md                          # Platform summary
│
├── concepts/                         # Core architectural patterns
│   ├── sdk-architecture-pattern.md  # Universal formula for ANY feature
│   ├── singleton-hierarchy.md       # 5-level navigation guide
│   └── raw-data-vs-canvas.md        # Linux-specific: raw data ONLY
│
├── examples/                         # Complete working code
│   ├── session-join-pattern.md      # JWT auth + session join
│   └── command-channel.md           # Command channel with threading
│
├── troubleshooting/                  # Problem solving guides
│   ├── pulseaudio-setup.md          # Audio configuration
│   ├── qt-dependencies.md           # Qt5 library setup
│   ├── build-errors.md              # Common build issues
│   └── common-issues.md             # Quick diagnostic workflow
│
└── references/                       # Reference documentation
    └── linux-reference.md           # API hierarchy, methods, error codes
```

---

## By Use Case

### I want to build a headless bot
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Understand the pattern
2. [Session Join Pattern](examples/session-join-pattern.md) - Join sessions
3. [PulseAudio Setup](troubleshooting/pulseaudio-setup.md) - Configure audio
4. [Raw Data vs Canvas](concepts/raw-data-vs-canvas.md) - Understand Linux differences

### I'm getting build errors
1. [Build Errors Guide](troubleshooting/build-errors.md) - SDK build issues
2. [Qt Dependencies](troubleshooting/qt-dependencies.md) - Qt5 setup
3. [Common Issues](troubleshooting/common-issues.md) - Quick diagnostics

### I'm getting runtime errors
1. [PulseAudio Setup](troubleshooting/pulseaudio-setup.md) - Audio not working
2. [Qt Dependencies](troubleshooting/qt-dependencies.md) - Library not found
3. [Common Issues](troubleshooting/common-issues.md) - Error code tables

### I want to use command channel
1. [Command Channel](examples/command-channel.md) - Send/receive commands
2. [Common Issues](troubleshooting/common-issues.md) - Threading requirements

### I want to implement a specific feature
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - **START HERE!**
2. [Singleton Hierarchy](concepts/singleton-hierarchy.md) - Navigate to the feature
3. [API Reference](references/linux-reference.md) - Method signatures

---

## Most Critical Documents

### 1. SDK Architecture Pattern (MASTER DOCUMENT)
**[concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)**

The universal 3-step pattern:
1. Get singleton (SDK, helpers, session, users)
2. Implement delegate (event callbacks)
3. Subscribe and use

### 2. Raw Data vs Canvas (LINUX-SPECIFIC)
**[concepts/raw-data-vs-canvas.md](concepts/raw-data-vs-canvas.md)**

**CRITICAL**: Unlike Windows/Mac, Linux SDK has NO Canvas API. You MUST use raw data pipe.

### 3. PulseAudio Setup (MOST COMMON ISSUE)
**[troubleshooting/pulseaudio-setup.md](troubleshooting/pulseaudio-setup.md)**

Audio requires PulseAudio configuration.

### 4. Qt Dependencies
**[troubleshooting/qt-dependencies.md](troubleshooting/qt-dependencies.md)**

SDK requires bundled Qt5 libraries, NOT system Qt5.

---

## Key Learnings

### Critical Discoveries:

1. **Linux has NO Canvas API**
   - Windows/Mac have Canvas API for SDK-rendered video
   - Linux MUST use Raw Data Pipe
   - See: [Raw Data vs Canvas](concepts/raw-data-vs-canvas.md)

2. **PulseAudio is MANDATORY**
   - SDK requires PulseAudio for raw audio
   - Must configure ~/.config/zoomus.conf
   - See: [PulseAudio Setup](troubleshooting/pulseaudio-setup.md)

3. **Use Bundled Qt5, NOT System Qt5**
   - SDK includes specific Qt5 versions
   - Copy from samples/qt_libs/
   - See: [Qt Dependencies](troubleshooting/qt-dependencies.md)

4. **Helpers Control YOUR Streams Only**
   - `videoHelper->startVideo()` starts YOUR camera
   - To see others, subscribe to their VideoPipe
   - See: [Singleton Hierarchy](concepts/singleton-hierarchy.md)

5. **Virtual Devices for Headless**
   - Docker/headless needs virtual audio speaker/mic
   - Set before joining session
   - See: [Session Join Pattern](examples/session-join-pattern.md)

6. **Always Use Heap Memory Mode**
   ```cpp
   init_params.videoRawDataMemoryMode = ZoomVideoSDKRawDataMemoryModeHeap;
   ```

7. **GLib Main Loop Required**
   - while/sleep loops don't dispatch SDK events
   - Must use g_main_loop_run()
   - See: [Common Issues](troubleshooting/common-issues.md)

8. **All SDK Calls Must Be on Main Thread**
   - Background thread SDK calls return error 2 (Internal_Error)
   - Use g_idle_add() to schedule on GLib main thread
   - See: [Command Channel](examples/command-channel.md)

9. **Command Channel is Session-Scoped**
   - Does NOT span across different sessions
   - Both sender and receiver must be in the same session
   - See: [Command Channel](examples/command-channel.md)

---

## Sample Repositories

- **[raw-recording-sample](https://github.com/zoom/videosdk-linux-raw-recording-sample)** - Official raw data sample
- **[qt-quickstart](https://github.com/tanchunsiong/videosdk-linux-qt-quickstart)** - Qt6 UI integration
- **[gtk-quickstart](https://github.com/tanchunsiong/videosdk-linux-gtk-quickstart)** - GTK3 UI integration

---

## Quick Reference

### "My code won't compile"
→ [Build Errors Guide](troubleshooting/build-errors.md)

### "Audio not working"
→ [PulseAudio Setup](troubleshooting/pulseaudio-setup.md)

### "Library not found"
→ [Qt Dependencies](troubleshooting/qt-dependencies.md)

### "How do I implement [feature]?"
→ [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

### "What error code means what?"
→ [Common Issues](troubleshooting/common-issues.md)

---

## Document Version

Based on **Zoom Video SDK for Linux v2.x**

---

**Happy coding!**

Remember: The [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) is your key to unlocking the entire SDK. Read it first!

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/video-sdk/macos', 'business', 'macos', '', 'macos', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Video SDK (macOS)

Use this skill when building custom macOS desktop video session apps.

## Start Here

1. [macos.md](macos.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/session-join-pattern.md](examples/session-join-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/macos-reference-map.md](references/macos-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Key Sources

- Docs: https://developers.zoom.us/docs/video-sdk/macos/
- API reference: https://marketplacefront.zoom.us/sdk/custom/macos/annotated.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$)
ON CONFLICT (skill_key) DO NOTHING;
