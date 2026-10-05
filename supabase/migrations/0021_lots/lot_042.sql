INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/electron', 'business', 'electron', '', 'electron', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (Electron)

Use this skill when building Electron desktop apps that embed Zoom Meeting SDK capabilities through the Electron wrapper.

## Start Here

1. **[Lifecycle Workflow](concepts/lifecycle-workflow.md)** - init -> auth -> join/start -> in-meeting -> cleanup
2. **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - service/controller/event model in Electron
3. **[Setup Guide](examples/setup-guide.md)** - dependency and build expectations
4. **[Authentication Pattern](examples/authentication-pattern.md)** - SDK JWT generation and auth callbacks
5. **[Join Meeting Pattern](examples/join-meeting-pattern.md)** - start/join meeting execution flow
6. **[SKILL.md](SKILL.md)** - full navigation

## Core Notes

- Electron wrapper is built on top of native Meeting SDK with Node addon bridges.
- Keep SDK key/secret server-side; generate SDK JWT on backend.
- Feature support differs by platform/version; check module docs before implementation.
- Raw data and IPC patterns require explicit security hardening in production.

## References

- [Electron API Reference Index](references/electron-reference.md)
- [Module Map](references/module-map.md)
- [Deprecated and Contradictions](troubleshooting/deprecated-and-contradictions.md)

## Related Skills

- [zoom-meeting-sdk](../SKILL.md)
- [zoom-oauth](../../oauth/SKILL.md)
- [zoom-general](../../general/SKILL.md)


## Merged from meeting-sdk/electron/SKILL.md

# Zoom Meeting SDK Electron - Documentation Index

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
- [Authentication Pattern](examples/authentication-pattern.md)
- [Join Meeting Pattern](examples/join-meeting-pattern.md)
- [Raw Data Pattern](examples/raw-data-pattern.md)

## References

- [Electron API Reference](references/electron-reference.md)
- [Module Map](references/module-map.md)

## Troubleshooting

- [Common Issues](troubleshooting/common-issues.md)
- [Version Drift](troubleshooting/version-drift.md)
- [Deprecated and Contradictions](troubleshooting/deprecated-and-contradictions.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/ios', 'business', 'ios', '', 'ios', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (iOS)

Use this skill when building iOS apps with embedded Zoom meeting capabilities.

## Start Here

1. [ios.md](ios.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/join-start-pattern.md](examples/join-start-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/ios-reference-map.md](references/ios-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Key Sources

- Docs: https://developers.zoom.us/docs/meeting-sdk/ios/
- API reference: https://marketplacefront.zoom.us/sdk/meeting/ios/annotated.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/linux', 'business', 'linux', '', 'linux', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK - Linux Development

Expert guidance for building headless meeting bots with the Zoom Meeting SDK on Linux. This SDK enables server-side meeting participation, raw media capture, transcription, and AI-powered meeting automation.

## How to Build a Meeting Bot That Automatically Joins and Records

Use this skill when the requirement is:
- visible bot joins a real Zoom meeting
- the bot records raw media itself
- or the bot triggers a Zoom-managed cloud-recording workflow after join

Skill chain:
- primary: `meeting-sdk/linux`
- add `zoom-rest-api` for OBF/ZAK lookup, scheduling, or cloud-recording settings
- add `zoom-webhooks` when post-meeting cloud recording retrieval is required

Minimal raw-recording flow:

```cpp
JoinParam join_param;
join_param.userType = SDK_UT_WITHOUT_LOGIN;
auto& params = join_param.param.withoutloginuserJoin;
params.meetingNumber = meeting_number;
params.userName = "Recording Bot";
params.psw = meeting_password.c_str();
params.app_privilege_token = obf_token.c_str();

SDKError join_err = meeting_service->Join(join_param);
if (join_err != SDKERR_SUCCESS) {
    throw std::runtime_error("join_failed");
}

// In MEETING_STATUS_INMEETING callback:
auto* record_ctrl = meeting_service->GetMeetingRecordingController();
if (!record_ctrl) {
    throw std::runtime_error("recording_controller_unavailable");
}

if (record_ctrl->CanStartRawRecording() != SDKERR_SUCCESS) {
    throw std::runtime_error("raw_recording_not_permitted");
}

SDKError record_err = record_ctrl->StartRawRecording();
if (record_err != SDKERR_SUCCESS) {
    throw std::runtime_error("start_raw_recording_failed");
}

GetAudioRawdataHelper()->subscribe(new MyAudioDelegate());
```

Use **raw recording** when the bot must own PCM/YUV media or feed an AI pipeline directly.  
Use **cloud recording + webhooks** when the requirement is Zoom-managed MP4/M4A/transcript assets after the meeting.

**Official Documentation**: https://developers.zoom.us/docs/meeting-sdk/linux/  
**API Reference**: https://marketplacefront.zoom.us/sdk/meeting/linux/  
**Sample Repository (Raw Recording)**: https://github.com/zoom/meetingsdk-linux-raw-recording-sample  
**Sample Repository (Headless)**: https://github.com/zoom/meetingsdk-headless-linux-sample

## Quick Links

**New to Meeting SDK Linux? Follow this path:**

1. **[linux.md](linux.md)** - Quick start guide with complete workflow
2. **[concepts/high-level-scenarios.md](concepts/high-level-scenarios.md)** - Production bot architectures
3. **[meeting-sdk-bot.md](meeting-sdk-bot.md)** - Resilient bot with retry logic
4. **[references/linux-reference.md](references/linux-reference.md)** - Dependencies, Docker, CMake

**Common Use Cases:**
- **Transcription Bot** → [high-level-scenarios.md#scenario-1-transcription-bot](concepts/high-level-scenarios.md)
- **Recording Bot** → [high-level-scenarios.md#scenario-2-recording-bot](concepts/high-level-scenarios.md)
- **AI Meeting Assistant** → [high-level-scenarios.md#scenario-3-ai-meeting-assistant](concepts/high-level-scenarios.md)
- **Quality Monitoring** → [high-level-scenarios.md#scenario-4-monitoring-quality-bot](concepts/high-level-scenarios.md)
- **Auto-Join + Recording Bot** → [meeting-sdk-bot.md](meeting-sdk-bot.md) for raw recording orchestration, retry, and cloud-recording handoff

**Having issues?**
- Docker audio issues → [references/linux-reference.md#pulseaudio-setup](references/linux-reference.md)
- Raw recording permission denied → [meeting-sdk-bot.md#raw-recording-permission-denied](meeting-sdk-bot.md)
- Build errors → [references/linux-reference.md#troubleshooting](references/linux-reference.md)

## Routing Rule for Bots

If the user asks to build a bot that **automatically joins a Zoom meeting and records it**, start with
[meeting-sdk-bot.md](meeting-sdk-bot.md).

- Use **Meeting SDK Linux** for the visible participant, join flow, and raw recording control.
- Chain **zoom-rest-api** when the bot must fetch OBF/ZAK tokens, schedule meetings, or enable account-side recording settings.
- Chain **zoom-webhooks** when the requirement is Zoom cloud recording retrieval after meeting end.

## SDK Overview

The Zoom Meeting SDK for Linux is a **C++ library optimized for headless server environments**:
- **Headless Operation**: No GUI required, perfect for Docker/cloud
- **Raw Data Access**: YUV420 video, PCM audio at 32kHz
- **GLib Event Loop**: Async event handling for callbacks
- **Docker-Ready**: Pre-configured Dockerfiles for CentOS/Ubuntu
- **PulseAudio Integration**: Virtual audio devices for headless environments

### Key Differences from Video SDK

| Feature | Meeting SDK (Linux) | Video SDK |
|---------|-------------------|-----------|
| **Primary Use** | Join existing meetings as bot | Host custom video sessions |
| **Visibility** | Visible participant | Session participant |
| **UI** | Headless (no UI) | Optional custom UI |
| **Authentication** | JWT + OBF/ZAK for external meetings | JWT only |
| **Recording Control** | `StartRawRecording()` required | Direct raw data access |
| **Platform** | Linux only | Windows, macOS, iOS, Android |

## Prerequisites

### System Requirements
- **OS**: Ubuntu 22+, CentOS 8/9, Oracle Linux 8
- **Architecture**: x86_64
- **Compiler**: gcc/g++ with C++11 support
- **Build Tools**: cmake 3.16+

### Development Dependencies
```bash
# Ubuntu
apt-get install -y build-essential cmake \
    libx11-xcb1 libxcb-xfixes0 libxcb-shape0 libxcb-shm0 \
    libxcb-randr0 libxcb-image0 libxcb-keysyms1 libxcb-xtest0 \
    libglib2.0-dev libcurl4-openssl-dev pulseaudio

# CentOS
yum install -y cmake gcc gcc-c++ \
    libxcb-devel xcb-util-image xcb-util-keysyms \
    glib2-devel libcurl-devel pulseaudio
```

### Required Credentials
1. **Zoom Meeting SDK App** (Client ID & Secret) → [Create at Marketplace](https://marketplace.zoom.us/)
2. **JWT Token** → Generate from Client ID/Secret
3. **For External Meetings**: OBF token OR ZAK token → [Get via REST API](../references/bot-authentication.md)
4. **For Raw Recording**: Meeting Recording Token (optional) → [Get via API](https://developers.zoom.us/docs/meeting-sdk/apis/#operation/meetingLocalRecordingJoinToken)

## Quick Start

### 1. Download & Extract SDK

```bash
# Download from https://marketplace.zoom.us/
tar xzf zoom-meeting-sdk-linux_x86_64-{version}.tar

# Organize files
mkdir -p demo/include/h demo/lib/zoom_meeting_sdk
cp -r h/* demo/include/h/
cp lib*.so demo/lib/zoom_meeting_sdk/
cp -r qt_libs demo/lib/zoom_meeting_sdk/
cp translation.json demo/lib/zoom_meeting_sdk/json/

# Create required symlink
cd demo/lib/zoom_meeting_sdk && ln -s libmeetingsdk.so libmeetingsdk.so.1
```

### 2. Initialize & Auth

```cpp
#include "zoom_sdk.h"

USING_ZOOM_SDK_NAMESPACE

// Initialize SDK
InitParam init_params;
init_params.strWebDomain = "https://zoom.us";
init_params.enableLogByDefault = true;
init_params.rawdataOpts.audioRawDataMemoryMode = ZoomSDKRawDataMemoryModeHeap;
InitSDK(init_params);

// Authenticate with JWT
AuthContext auth_ctx;
auth_ctx.jwt_token = your_jwt_token;
CreateAuthService(&auth_service);
auth_service->SDKAuth(auth_ctx);
```

### 3. Join Meeting

```cpp
// In onAuthenticationReturn callback
void onAuthenticationReturn(AuthResult ret) {
    if (ret == AUTHRET_SUCCESS) {
        JoinParam join_param;
        join_param.userType = SDK_UT_WITHOUT_LOGIN;
        
        auto& params = join_param.param.withoutloginuserJoin;
        params.meetingNumber = 1234567890;
        params.userName = "Bot";
        params.psw = "password";
        params.isVideoOff = true;
        params.isAudioOff = false;
        
        meeting_service->Join(join_param);
    }
}
```

### 4. Access Raw Data

```cpp
// In onMeetingStatusChanged callback
void onMeetingStatusChanged(MeetingStatus status, int iResult) {
    if (status == MEETING_STATUS_INMEETING) {
        auto* record_ctrl = meeting_service->GetMeetingRecordingController();
        
        // Start raw recording (enables raw data access)
        if (record_ctrl->CanStartRawRecording() == SDKERR_SUCCESS) {
            record_ctrl->StartRawRecording();
            
            // Subscribe to audio
            auto* audio_helper = GetAudioRawdataHelper();
            audio_helper->subscribe(new MyAudioDelegate());
            
            // Subscribe to video
            IZoomSDKRenderer* video_renderer;
            createRenderer(&video_renderer, new MyVideoDelegate());
            video_renderer->setRawDataResolution(ZoomSDKResolution_720P);
            video_renderer->subscribe(user_id, RAW_DATA_TYPE_VIDEO);
        }
    }
}
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Headless Operation** | No GUI, perfect for Docker/server deployments |
| **Raw Audio (PCM)** | Capture mixed or per-user audio at 32kHz |
| **Raw Video (YUV420)** | Capture video frames in contiguous planar format |
| **GLib Event Loop** | Async callback handling |
| **Docker Support** | Pre-built Dockerfiles for CentOS/Ubuntu |
| **PulseAudio Virtual Devices** | Audio in headless environments |
| **Breakout Rooms** | Programmatic breakout room management |
| **Chat** | Send/receive in-meeting chat |
| **Recording Control** | Local, cloud, and raw recording |

## Critical Gotchas & Best Practices

### ⚠️ CRITICAL: PulseAudio for Docker/Headless

**The #1 issue for raw audio in Docker:**

Raw audio requires PulseAudio and a config file, even in headless environments.

**Solution**:
```bash
# Install PulseAudio
apt-get install -y pulseaudio pulseaudio-utils

# Create config file
mkdir -p ~/.config
cat > ~/.config/zoomus.conf << EOF
[General]
system.audio.type=default
EOF

# Start PulseAudio with virtual devices
pulseaudio --start --exit-idle-time=-1
pactl load-module module-null-sink sink_name=virtual_speaker
pactl load-module module-null-sink sink_name=virtual_mic
```

See: [references/linux-reference.md#pulseaudio-setup](references/linux-reference.md)

### Raw Recording Permission Required

Unlike Video SDK, Meeting SDK requires explicit permission to access raw data:

```cpp
// MUST call StartRawRecording() first
auto* record_ctrl = meeting_service->GetMeetingRecordingController();

SDKError can_record = record_ctrl->CanStartRawRecording();
if (can_record == SDKERR_SUCCESS) {
    record_ctrl->StartRawRecording();
    // NOW you can subscribe to audio/video
} else {
    // Need: host/co-host status OR recording token
}
```

**Ways to get permission**:
1. Bot is host/co-host
2. Host grants recording permission
3. Use `recording_token` parameter (get via [REST API](https://developers.zoom.us/docs/meeting-sdk/apis/#operation/meetingLocalRecordingJoinToken))
4. Use `app_privilege_token` (OBF) when joining

### GLib Main Loop Required

SDK callbacks execute via GLib event loop:

```cpp
#include <glib.h>

// Setup main loop
GMainLoop* loop = g_main_loop_new(NULL, FALSE);

// Add timeout for periodic tasks
g_timeout_add_seconds(10, check_meeting_status, NULL);

// Run loop (blocks until quit)
g_main_loop_run(loop);
```

**Without GLib loop**: Callbacks never fire, join hangs indefinitely.

### Heap Memory Mode Recommended

Always use heap mode for raw data to avoid stack overflow with large frames:

```cpp
init_params.rawdataOpts.videoRawDataMemoryMode = ZoomSDKRawDataMemoryModeHeap;
init_params.rawdataOpts.shareRawDataMemoryMode = ZoomSDKRawDataMemoryModeHeap;
init_params.rawdataOpts.audioRawDataMemoryMode = ZoomSDKRawDataMemoryModeHeap;
```

### Thread Safety

SDK callbacks execute on SDK threads:
- Don't perform heavy operations in callbacks
- Don't call `CleanUPSDK()` from within callbacks
- Use thread-safe queues for data passing
- Use mutexes for shared state

## Production Architectures

### Transcription Bot

**See**: [concepts/high-level-scenarios.md#scenario-1](concepts/high-level-scenarios.md)

```
Join Meeting → StartRawRecording → Subscribe Audio → 
Stream to AssemblyAI/Whisper → Generate Real-time Transcript
```

### Recording Bot

**See**: [concepts/high-level-scenarios.md#scenario-2](concepts/high-level-scenarios.md)

```
Join Meeting → StartRawRecording → Subscribe Audio+Video → 
Write YUV+PCM → FFmpeg Merge → Upload to Storage
```

### AI Meeting Assistant

**See**: [concepts/high-level-scenarios.md#scenario-3](concepts/high-level-scenarios.md)

```
Join Meeting → Real-time Transcription → AI Analysis → 
Extract Action Items → Generate Summary
```

## Sample Applications

**Official Repositories**:

| Sample | Description | Link |
|--------|-------------|------|
| **Raw Recording Sample** | Traditional C++ approach with config.txt | [GitHub](https://github.com/zoom/meetingsdk-linux-raw-recording-sample) |
| **Headless Sample** | Modern TOML-based with CLI, Docker Compose | [GitHub](https://github.com/zoom/meetingsdk-headless-linux-sample) |

**What Each Demonstrates**:

- **Raw Recording Sample**: Complete raw data workflow, PulseAudio setup, Docker multi-distro support
- **Headless Sample**: AssemblyAI integration, Anthropic AI, production-ready config management

## Documentation Library

### Core Concepts
- **[linux.md](linux.md)** - Quick start & core workflow
- **[concepts/high-level-scenarios.md](concepts/high-level-scenarios.md)** - Production bot architectures
- **[meeting-sdk-bot.md](meeting-sdk-bot.md)** - Resilient bot with retry logic

### Platform Reference
- **[references/linux-reference.md](references/linux-reference.md)** - Dependencies, CMake, Docker, troubleshooting

### Authentication
- **[../references/authorization.md](../references/authorization.md)** - SDK JWT generation
- **[../references/bot-authentication.md](../references/bot-authentication.md)** - Bot token types (ZAK, OBF, JWT)

### Advanced Features
- **[../references/breakout-rooms.md](../references/breakout-rooms.md)** - Programmatic breakout rooms
- **[../references/ai-companion.md](../references/ai-companion.md)** - AI Companion controls

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| **No audio in Docker** | Missing PulseAudio config | Create `~/.config/zoomus.conf` |
| **Raw recording denied** | No permission | Use host/co-host OR recording token |
| **Callbacks not firing** | Missing GLib main loop | Add `g_main_loop_run()` |
| **Build errors (XCB)** | Missing X11 libraries | Install libxcb packages |
| **Segfault on auth** | OpenSSL version mismatch | Install libssl1.1 |

**Complete troubleshooting**: [references/linux-reference.md#troubleshooting](references/linux-reference.md)

## Resources

- **Official Docs**: https://developers.zoom.us/docs/meeting-sdk/linux/
- **API Reference**: https://marketplacefront.zoom.us/sdk/meeting/linux/
- **Dev Forum**: https://devforum.zoom.us/
- **GitHub Samples**: 
  - https://github.com/zoom/meetingsdk-linux-raw-recording-sample
  - https://github.com/zoom/meetingsdk-headless-linux-sample

---

**Need help?** Start with [linux.md](linux.md) for quick start, then explore [high-level-scenarios.md](concepts/high-level-scenarios.md) for production patterns.

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/macos', 'business', 'macos', '', 'macos', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (macOS)

Use this skill when building macOS apps with embedded Zoom meeting capabilities.

## Start Here

1. [macos.md](macos.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/join-start-pattern.md](examples/join-start-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/macos-reference-map.md](references/macos-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Key Sources

- Docs: https://developers.zoom.us/docs/meeting-sdk/macos/
- API reference: https://marketplacefront.zoom.us/sdk/meeting/macos/annotated.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/react-native', 'business', 'react-native', '', 'react-native', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (React Native)

Use this skill when building React Native apps that need embedded Zoom meeting join/start flows.

## Quick Links

1. **[Lifecycle Workflow](concepts/lifecycle-workflow.md)** - init -> auth -> join/start -> in-meeting -> cleanup
2. **[Architecture](concepts/architecture.md)** - JS wrapper, native bridge, iOS/Android SDK layers
3. **[High-Level Scenarios](concepts/high-level-scenarios.md)** - practical product patterns
4. **[Setup Guide](examples/setup-guide.md)** - install package + platform requirements
5. **[Join Meeting Pattern](examples/join-meeting-pattern.md)** - JWT + meetingNumber + password
6. **[Start Meeting Pattern](examples/start-meeting-pattern.md)** - ZAK-based host start
7. **[SKILL.md](SKILL.md)** - full navigation

## Core APIs (Wrapper)

From `@zoom/meetingsdk-react-native` wrapper surface:

- `initSDK(config)`
- `isInitialized()`
- `updateMeetingSetting(config)`
- `joinMeeting(config)`
- `startMeeting(config)`
- `cleanup()`

See: **[Wrapper API](references/wrapper-api.md)**

## Critical Notes

- You still need native iOS/Android Meeting SDK dependencies configured.
- `joinMeeting` and `startMeeting` return numeric status/error codes from native layer.
- For host start flow, pass `zoomAccessToken` (ZAK).
- Keep JWT generation on backend, never embed SDK secret in app.
- Current docs note React Native support up to `0.75.4`; Expo is not supported.

## Platform Guides

- **[iOS Setup](references/ios-setup.md)** - Podfile, optional ReplayKit/app group fields
- **[Android Setup](references/android-setup.md)** - Gradle dependency + options mapping
- **[Native Bridge Notes](references/native-bridge-notes.md)** - behavior differences and gotchas

## Troubleshooting

- **[Common Issues](troubleshooting/common-issues.md)**
- **[Version Drift](troubleshooting/version-drift.md)**
- **[Deprecated/Contradictions](troubleshooting/deprecated-and-contradictions.md)**

## Related Skills

- **[zoom-meeting-sdk](../SKILL.md)** - parent Meeting SDK hub
- **[zoom-oauth](../../oauth/SKILL.md)** - auth flow and token management
- **[zoom-general](../../general/SKILL.md)** - cross-product architecture decisions

## Documentation Index

### Start Here

1. [SKILL.md](SKILL.md)
2. [Lifecycle Workflow](concepts/lifecycle-workflow.md)
3. [Architecture](concepts/architecture.md)
4. [Setup Guide](examples/setup-guide.md)

### Concepts

- [Lifecycle Workflow](concepts/lifecycle-workflow.md)
- [Architecture](concepts/architecture.md)
- [Auth and Token Model](concepts/auth-and-token-model.md)
- [High-Level Scenarios](concepts/high-level-scenarios.md)

### Examples

- [Setup Guide](examples/setup-guide.md)
- [Join Meeting Pattern](examples/join-meeting-pattern.md)
- [Start Meeting Pattern](examples/start-meeting-pattern.md)
- [Provider Hook Pattern](examples/provider-hook-pattern.md)

### References

- [Wrapper API](references/wrapper-api.md)
- [Android Setup](references/android-setup.md)
- [iOS Setup](references/ios-setup.md)
- [Native Bridge Notes](references/native-bridge-notes.md)
- [Official Sources](references/official-sources.md)

### Troubleshooting

- [Common Issues](troubleshooting/common-issues.md)
- [Version Drift](troubleshooting/version-drift.md)
- [Deprecated and Contradictions](troubleshooting/deprecated-and-contradictions.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk', 'business', 'meeting-sdk', '', 'meeting-sdk', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-meeting-sdk-app

Background reference for embedded Zoom meetings across web, mobile, desktop, and Linux bot environments. Prefer `build-zoom-meeting-app` or `build-zoom-bot` first, then route here for platform detail.

# Zoom Meeting SDK

Embed the full Zoom meeting experience into web, mobile, desktop, and headless integrations.

## Hard Routing Guardrail (Read First)

- If the user asks to embed/join meetings inside their app UI, route to Meeting SDK implementation.
- Do not switch to REST-only meeting link flow unless the user explicitly asks for meeting resource management or browser `join_url` links.
- Meeting SDK join path requires SDK signature + SDK join call; REST `join_url` is not a Meeting SDK join payload.

## Prerequisites

- Zoom app with Meeting SDK credentials
- SDK Key and Secret from Marketplace
- Platform-specific development environment (Web, Android, iOS, macOS, Unreal, Electron, Linux, or Windows)

> **Need help with OAuth or signatures?** See the **[zoom-oauth](../oauth/SKILL.md)** skill for authentication flows.

> **Need pre-join diagnostics on web?** Use **[probe-sdk](../probe-sdk/SKILL.md)** before Meeting SDK init/join to gate low-readiness devices/networks.

> **Start troubleshooting fast:** Use the **[5-Minute Runbook](RUNBOOK.md)** before deep debugging.

## Quick Start (Web - Client View via CDN)

```html
<script src="https://source.zoom.us/3.1.6/lib/vendor/react.min.js"></script>
<script src="https://source.zoom.us/3.1.6/lib/vendor/react-dom.min.js"></script>
<script src="https://source.zoom.us/3.1.6/lib/vendor/redux.min.js"></script>
<script src="https://source.zoom.us/3.1.6/lib/vendor/redux-thunk.min.js"></script>
<script src="https://source.zoom.us/3.1.6/lib/vendor/lodash.min.js"></script>
<script src="https://source.zoom.us/3.1.6/zoom-meeting-3.1.6.min.js"></script>

<script>
// CDN provides ZoomMtg (Client View - full page)
// For ZoomMtgEmbedded (Component View), use npm instead

ZoomMtg.preLoadWasm();
ZoomMtg.prepareWebSDK();

ZoomMtg.init({
  leaveUrl: window.location.href,
  patchJsMedia: true,
  disableCORP: !window.crossOriginIsolated,
  success: function() {
    ZoomMtg.join({
      sdkKey: 'YOUR_SDK_KEY',
      signature: 'YOUR_SIGNATURE',  // Generate server-side!
      meetingNumber: 'MEETING_NUMBER',
      userName: 'User Name',
      passWord: '',  // Note: camelCase with capital W
      success: function(res) { console.log('Joined'); },
      error: function(err) { console.error(err); }
    });
  },
  error: function(err) { console.error(err); }
});
</script>
```

## Critical Notes (Web)

### 1. CDN vs npm - Different APIs!

| Distribution | Global Object | View Type | API Style |
|--------------|---------------|-----------|-----------|
| CDN (`zoom-meeting-{ver}.min.js`) | `ZoomMtg` | Client View (full-page) | Callbacks |
| npm (`@zoom/meetingsdk`) | `ZoomMtgEmbedded` | Component View (embeddable) | Promises |

### 2. Backend Required for Production

**Never expose SDK Secret in client code.** Generate signatures server-side:

```javascript
// server.js (Node.js example)
const KJUR = require('jsrsasign');

app.post('/api/signature', (req, res) => {
  const { meetingNumber, role } = req.body;
  const iat = Math.floor(Date.now() / 1000) - 30;
  const exp = iat + 60 * 60 * 2;
  
  const header = { alg: 'HS256', typ: 'JWT' };
  const payload = {
    sdkKey: process.env.ZOOM_SDK_KEY,
    mn: String(meetingNumber).replace(/\D/g, ''),
    role: parseInt(role, 10),
    iat, exp, tokenExp: exp
  };
  
  const signature = KJUR.jws.JWS.sign('HS256',
    JSON.stringify(header),
    JSON.stringify(payload),
    process.env.ZOOM_SDK_SECRET
  );
  
  res.json({ signature, sdkKey: process.env.ZOOM_SDK_KEY });
});
```

### 3. CSS Conflicts - Avoid Global Resets

Global `* { margin: 0; }` breaks Zoom's UI. Scope your styles:

```css
/* BAD */
* { margin: 0; padding: 0; }

/* GOOD */
.your-app, .your-app * { box-sizing: border-box; }
```

### 4. Client View Toolbar Cropping Fix

If toolbar falls off screen, scale down the Zoom UI:

```css
#zmmtg-root {
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  width: 100vw !important;
  height: 100vh !important;
  /* Critical for SPAs (React/Next/etc): ensure Zoom UI isn't behind your app shell/overlays. */
  z-index: 9999 !important;
  transform: scale(0.95) !important;
  transform-origin: top center !important;
}
```

### 5. Hide Your App When Meeting Starts

Client View takes over full page. Hide your UI:

```javascript
// In ZoomMtg.init success callback:
document.documentElement.classList.add('meeting-active');
document.body.classList.add('meeting-active');
```

```css
body.meeting-active .your-app { display: none !important; }
body.meeting-active { background: #000 !important; }
```

## UI Options (Web)

Meeting SDK provides **Zoom's UI with customization options**:

| View | Description |
|------|-------------|
| **Component View** | Extractable, customizable UI - embed meeting in a div |
| **Client View** | Full-page Zoom UI experience |

**Note**: Unlike Video SDK where you build the UI from scratch, Meeting SDK uses Zoom's UI as the base with customization on top.

## Key Concepts

| Concept | Description |
|---------|-------------|
| SDK Key/Secret | Credentials from Marketplace |
| Signature | JWT signed with SDK Secret |
| Component View | Extractable, customizable UI (Web) |
| Client View | Full-page Zoom UI (Web) |

## Detailed References

### Platform Guides
- **[android/SKILL.md](android/SKILL.md)** - Android SDK (default/custom UI, join/start/auth lifecycle, mobile integration)
- **[android/references/android-reference-map.md](android/references/android-reference-map.md)** - Android API surface map and drift watchpoints
- **[ios/SKILL.md](ios/SKILL.md)** - iOS SDK (default/custom UI, join/start/auth lifecycle, mobile integration)
- **[ios/references/ios-reference-map.md](ios/references/ios-reference-map.md)** - iOS API surface map and drift watchpoints
- **[macos/SKILL.md](macos/SKILL.md)** - macOS SDK (desktop default/custom UI, service controllers, host flows)
- **[macos/references/macos-reference-map.md](macos/references/macos-reference-map.md)** - macOS API surface map and drift watchpoints
- **[unreal/SKILL.md](unreal/SKILL.md)** - Unreal Engine wrapper (C++/Blueprint wrapper behavior and SDK mapping)
- **[unreal/references/unreal-reference-map.md](unreal/references/unreal-reference-map.md)** - Unreal wrapper reference map and version-lag notes
- **[references/android.md](references/android.md)** - Android pointer doc for fast routing from broad Meeting SDK queries
- **[references/ios.md](references/ios.md)** - iOS pointer doc for fast routing from broad Meeting SDK queries
- **[references/macos.md](references/macos.md)** - macOS pointer doc for fast routing from broad Meeting SDK queries
- **[references/unreal.md](references/unreal.md)** - Unreal pointer doc for fast routing from broad Meeting SDK queries
- **[linux/SKILL.md](linux/SKILL.md)** - Linux SDK headless bot skill entrypoint
- **[linux/linux.md](linux/linux.md)** - Linux SDK (C++ headless bots, raw media access)
- **[linux/references/linux-reference.md](linux/references/linux-reference.md)** - Linux dependencies, Docker, troubleshooting
- **[react-native/SKILL.md](react-native/SKILL.md)** - React Native SDK (iOS/Android wrapper, join/start flows, bridge setup)
- **[react-native/SKILL.md](react-native/SKILL.md)** - React Native complete navigation
- **[electron/SKILL.md](electron/SKILL.md)** - Electron SDK (desktop wrapper, auth/join flows, module controllers, raw data)
- **[electron/SKILL.md](electron/SKILL.md)** - Electron complete navigation
- **[windows/SKILL.md](windows/SKILL.md)** - Windows SDK (C++ desktop applications, raw media access)
- **[windows/references/windows-reference.md](windows/references/windows-reference.md)** - Windows dependencies, Visual Studio setup, troubleshooting
- **[web/references/web.md](web/references/web.md)** - Web SDK (Component + Client View)
- **[web/references/web-tracking-id.md](web/references/web-tracking-id.md)** - Tracking ID configuration

### Features
- **[references/authorization.md](references/authorization.md)** - SDK JWT generation
- **[references/bot-authentication.md](references/bot-authentication.md)** - ZAK vs OBF vs JWT tokens for bots
- **[references/breakout-rooms.md](references/breakout-rooms.md)** - Programmatic breakout room management
- **[references/ai-companion.md](references/ai-companion.md)** - AI Companion controls in meetings
- **[references/webinars.md](references/webinars.md)** - Webinar SDK features
- **[references/forum-top-questions.md](references/forum-top-questions.md)** - Common forum question patterns (what to cover)
- **[references/triage-intake.md](references/triage-intake.md)** - What to ask first (turn vague reports into answers)
- **[references/signature-playbook.md](references/signature-playbook.md)** - Signature/root-cause playbook
- **[references/multiple-meetings.md](references/multiple-meetings.md)** - Joining multiple meetings / multiple instances
- **[references/troubleshooting.md](references/troubleshooting.md)** - Common issues and solutions

## Sample Repositories

### Official (by Zoom)

| Type | Repository | Stars |
|------|------------|-------|
| Linux Headless | [meetingsdk-headless-linux-sample](https://github.com/zoom/meetingsdk-headless-linux-sample) | 4 |
| Linux Raw Data | [meetingsdk-linux-raw-recording-sample](https://github.com/zoom/meetingsdk-linux-raw-recording-sample) | 0 |
| Web | [meetingsdk-web-sample](https://github.com/zoom/meetingsdk-web-sample) | 643 |
| Web NPM | [meetingsdk-web](https://github.com/zoom/meetingsdk-web) | 324 |
| React | [meetingsdk-react-sample](https://github.com/zoom/meetingsdk-react-sample) | 177 |
| Auth | [meetingsdk-auth-endpoint-sample](https://github.com/zoom/meetingsdk-auth-endpoint-sample) | 124 |
| Angular | [meetingsdk-angular-sample](https://github.com/zoom/meetingsdk-angular-sample) | 60 |
| Vue.js | [meetingsdk-vuejs-sample](https://github.com/zoom/meetingsdk-vuejs-sample) | 42 |

**Full list**: See [general/references/community-repos.md](../general/references/community-repos.md)

## Resources

- **Official docs**: https://developers.zoom.us/docs/meeting-sdk/
- **Developer forum**: https://devforum.zoom.us/

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/unreal', 'business', 'unreal', '', 'unreal', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (Unreal Engine)

Use this skill when integrating Meeting SDK into Unreal Engine projects.

## Start Here

1. [unreal.md](unreal.md)
2. [concepts/lifecycle-workflow.md](concepts/lifecycle-workflow.md)
3. [concepts/architecture.md](concepts/architecture.md)
4. [examples/join-start-pattern.md](examples/join-start-pattern.md)
5. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
6. [references/unreal-reference-map.md](references/unreal-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Key Sources

- Docs: https://developers.zoom.us/docs/meeting-sdk/unreal/
- API reference: https://marketplacefront.zoom.us/sdk/meeting/unreal/MSDKUnrealSDKreferencedocs.html
- Broader guide: [../SKILL.md](../SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/web/client-view', 'business', 'client-view', '', 'client-view', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK Web - Client View

Full-page Zoom meeting experience embedded in your web application. Client View provides the familiar Zoom interface with minimal customization needed.

## Overview

Client View uses the `ZoomMtg` global singleton to render a full-page meeting experience identical to the Zoom Web Client.

| Aspect | Details |
|--------|---------|
| **API Object** | `ZoomMtg` (global singleton) |
| **API Style** | Callback-based |
| **UI** | Full-page takeover |
| **Password param** | `passWord` (capital W) |
| **Events** | `inMeetingServiceListener()` |
| **Best For** | Quick integration, standard Zoom UI |

## Installation

### NPM

```bash
npm install @zoom/meetingsdk --save
```

```javascript
import { ZoomMtg } from '@zoom/meetingsdk';
```

### CDN

```html
<script src="https://source.zoom.us/{VERSION}/lib/vendor/react.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/react-dom.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/redux.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/redux-thunk.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/lodash.min.js"></script>
<script src="https://source.zoom.us/zoom-meeting-{VERSION}.min.js"></script>
```

## Complete Initialization Flow

```javascript
// Step 1: Check browser compatibility
console.log('Requirements:', ZoomMtg.checkSystemRequirements());

// Step 2: Set CDN path (optional - for China or custom hosting)
// ZoomMtg.setZoomJSLib('https://source.zoom.us/{VERSION}/lib', '/av');

// Step 3: Preload WebAssembly modules
ZoomMtg.preLoadWasm();
ZoomMtg.prepareWebSDK();

// Step 4: Load language resources
ZoomMtg.i18n.load('en-US');
ZoomMtg.i18n.onLoad(() => {
  
  // Step 5: Initialize SDK
  ZoomMtg.init({
    leaveUrl: '/meeting-ended',
    patchJsMedia: true,
    disableCORP: !window.crossOriginIsolated,
    success: () => {
      console.log('SDK initialized');
      
      // Step 6: Join meeting
      const joinPayload = {
        signature: signature,
        meetingNumber: meetingNumber,
        userName: userName,
        passWord: passWord,
        success: (res) => {
          console.log('Joined meeting');

          // Step 7: Post-join operations
          ZoomMtg.getAttendeeslist({});
          ZoomMtg.getCurrentUser({
            success: (res) => console.log('Current user:', res.result.currentUser)
          });
        },
        error: (err) => console.error('Join failed:', err)
      };

      // IMPORTANT: only include optional fields when they have real values
      // Passing undefined for some optional fields can cause runtime join errors
      if (userEmail) joinPayload.userEmail = userEmail;
      if (tk) joinPayload.tk = tk;
      if (zak) joinPayload.zak = zak;

      ZoomMtg.join(joinPayload);
    },
    error: (err) => console.error('Init failed:', err)
  });
});
```

## ZoomMtg.init() - All Options

### Required

| Parameter | Type | Description |
|-----------|------|-------------|
| `leaveUrl` | `string` | URL to redirect after leaving meeting |

### UI Customization

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `showMeetingHeader` | `boolean` | `true` | Show meeting number and topic |
| `disableInvite` | `boolean` | `false` | Hide invite button |
| `disableCallOut` | `boolean` | `false` | Hide call out option |
| `disableRecord` | `boolean` | `false` | Hide record button |
| `disableJoinAudio` | `boolean` | `false` | Hide join audio option |
| `disablePreview` | `boolean` | `false` | Skip audio/video preview |
| `audioPanelAlwaysOpen` | `boolean` | `false` | Keep audio panel open |
| `showPureSharingContent` | `boolean` | `false` | Prevent overlays on shared content |
| `videoHeader` | `boolean` | `true` | Show video tile header |
| `isLockBottom` | `boolean` | `true` | Show/hide footer |
| `videoDrag` | `boolean` | `true` | Enable drag video tiles |
| `sharingMode` | `string` | `'both'` | `'both'` or `'fit'` |
| `screenShare` | `boolean` | `true` | Enable browser URL sharing |
| `hideShareAudioOption` | `boolean` | `false` | Hide "Share tab audio" checkbox |
| `disablePictureInPicture` | `boolean` | `false` | Disable PiP mode |
| `disableZoomLogo` | `boolean` | `false` | Remove Zoom logo (deprecated) |
| `defaultView` | `string` | `'speaker'` | `'gallery'`, `'speaker'`, `'multiSpeaker'` |

### Feature Toggles

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `isSupportAV` | `boolean` | `true` | Enable audio/video |
| `isSupportChat` | `boolean` | `true` | Enable in-meeting chat |
| `isSupportQA` | `boolean` | `true` | Enable webinar Q&A |
| `isSupportCC` | `boolean` | `true` | Enable closed captions |
| `isSupportPolling` | `boolean` | `true` | Enable polling |
| `isSupportBreakout` | `boolean` | `true` | Enable breakout rooms |
| `isSupportNonverbal` | `boolean` | `true` | Enable nonverbal feedback |
| `isSupportSimulive` | `boolean` | `false` | Enable Simulive |
| `disableVoIP` | `boolean` | `false` | Disable VoIP |
| `disableReport` | `boolean` | `false` | Disable report feature |

### Video Quality

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enableHD` | `boolean` | `true` (≥2.8.0) | Enable 720p video |
| `enableFullHD` | `boolean` | `false` | Enable 1080p for webinar attendees |

### Advanced

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `debug` | `boolean` | `false` | Enable debug logging |
| `patchJsMedia` | `boolean` | `false` | Auto-apply media fixes |
| `disableCORP` | `boolean` | `false` | Disable web isolation |
| `helper` | `string` | `''` | Path to helper.html |
| `externalLinkPage` | `string` | - | Page for external links |
| `webEndpoint` | `string` | - | For ZFG environments |
| `leaveOnPageUnload` | `boolean` | `false` | Auto cleanup on page close |
| `isShowJoiningErrorDialog` | `boolean` | `true` | Show error dialog on join failure |
| `meetingInfo` | `Array<string>` | `[...]` | Meeting info to display |
| `inviteUrlFormat` | `string` | `''` | Custom invite URL format |
| `loginWindow` | `object` | `{width: 400, height: 380}` | Login popup size |

### Callbacks

| Parameter | Type | Description |
|-----------|------|-------------|
| `success` | `Function` | Called on successful init |
| `error` | `Function` | Called on init failure |

## ZoomMtg.join() - All Options

### Required

| Parameter | Type | Description |
|-----------|------|-------------|
| `signature` | `string` | SDK JWT from backend (v5.0+: must include appKey prefix) |
| `meetingNumber` | `string \| number` | Meeting or webinar number |
| `userName` | `string` | Display name |
| `passWord` | `string` | Meeting password (capital W!) |

### Authentication

| Parameter | Type | When Required | Description |
|-----------|------|---------------|-------------|
| `zak` | `string` | Starting as host | Host's Zoom Access Key |
| `tk` | `string` | Registration required | Registrant token |
| `userEmail` | `string` | Webinars | User email |
| `obfToken` | `string` | March 2026+ | App Privilege Token |

### Optional

| Parameter | Type | Description |
|-----------|------|-------------|
| `customerKey` | `string` | Custom ID (max 36 chars) |
| `recordingToken` | `string` | Local recording permission |

### Callbacks

| Parameter | Type | Description |
|-----------|------|-------------|
| `success` | `Function` | Called on successful join |
| `error` | `Function` | Called on join failure |

## Event Listeners

### User Events

```javascript
ZoomMtg.inMeetingServiceListener('onUserJoin', (data) => {
  console.log('User joined:', data);
  // { userId, userName, ... }
});

ZoomMtg.inMeetingServiceListener('onUserLeave', (data) => {
  console.log('User left:', data);
  // Reason codes:
  // 0: OTHER
  // 1: HOST_ENDED_MEETING
  // 2: SELF_LEAVE_FROM_IN_MEETING
  // 3: SELF_LEAVE_FROM_WAITING_ROOM
  // 4: SELF_LEAVE_FROM_WAITING_FOR_HOST_START
  // 5: MEETING_TRANSFER
  // 6: KICK_OUT_FROM_MEETING
  // 7: KICK_OUT_FROM_WAITING_ROOM
  // 8: LEAVE_FROM_DISCLAIMER
});

ZoomMtg.inMeetingServiceListener('onUserUpdate', (data) => {
  console.log('User updated:', data);
});

ZoomMtg.inMeetingServiceListener('onUserIsInWaitingRoom', (data) => {
  console.log('User in waiting room:', data);
});
```

### Meeting Status

```javascript
ZoomMtg.inMeetingServiceListener('onMeetingStatus', (data) => {
  // status: 1=connecting, 2=connected, 3=disconnected, 4=reconnecting
  console.log('Status:', data.status);
});
```

### Audio/Video Events

```javascript
ZoomMtg.inMeetingServiceListener('onActiveSpeaker', (data) => {
  // [{userId, userName}]
  console.log('Active speaker:', data);
});

ZoomMtg.inMeetingServiceListener('onNetworkQualityChange', (data) => {
  // {level: 0-5, userId, type: 'uplink'}
  // 0-1=bad, 2=normal, 3-5=good
  console.log('Network quality:', data);
});

ZoomMtg.inMeetingServiceListener('onAudioQos', (data) => {
  console.log('Audio QoS:', data);
});

ZoomMtg.inMeetingServiceListener('onVideoQos', (data) => {
  console.log('Video QoS:', data);
});
```

### Chat & Communication

```javascript
ZoomMtg.inMeetingServiceListener('onReceiveChatMsg', (data) => {
  console.log('Chat message:', data);
});

ZoomMtg.inMeetingServiceListener('onReceiveTranscriptionMsg', (data) => {
  console.log('Transcription:', data);
});

ZoomMtg.inMeetingServiceListener('onReceiveTranslateMsg', (data) => {
  console.log('Translation:', data);
});
```

### Recording & Sharing

```javascript
ZoomMtg.inMeetingServiceListener('onRecordingChange', (data) => {
  console.log('Recording status:', data);
});

ZoomMtg.inMeetingServiceListener('onShareContentChange', (data) => {
  console.log('Share content:', data);
});

ZoomMtg.inMeetingServiceListener('receiveSharingChannelReady', (data) => {
  console.log('Sharing channel ready:', data);
});
```

### Breakout Rooms

```javascript
ZoomMtg.inMeetingServiceListener('onRoomStatusChange', (data) => {
  // status: 2=InProgress, 3=Closing, 4=Closed
  console.log('Breakout room status:', data);
});
```

### Other Events

```javascript
ZoomMtg.inMeetingServiceListener('onJoinSpeed', (data) => {
  console.log('Join metrics:', data);
});

ZoomMtg.inMeetingServiceListener('onVbStatusChange', (data) => {
  console.log('Virtual background status:', data);
});

ZoomMtg.inMeetingServiceListener('onFocusModeStatusChange', (data) => {
  console.log('Focus mode:', data);
});

ZoomMtg.inMeetingServiceListener('onPictureInPicture', (data) => {
  console.log('PiP status:', data);
});

ZoomMtg.inMeetingServiceListener('onClaimStatus', (data) => {
  console.log('Host claim status:', data);
});
```

## Common Methods

### Meeting Info

```javascript
// Get current user
ZoomMtg.getCurrentUser({
  success: (res) => console.log(res.result.currentUser)
});

// Get all attendees
ZoomMtg.getAttendeeslist({});

// Get meeting info
ZoomMtg.getCurrentMeetingInfo({
  success: (res) => console.log(res)
});

// Get SDK version
ZoomMtg.getWebSDKVersion({
  success: (version) => console.log(version)
});
```

### Audio/Video Control

```javascript
// Mute/unmute specific user
ZoomMtg.mute({ userId, mute: true });

// Mute/unmute all
ZoomMtg.muteAll({ muteAll: true });

// Stop incoming audio
ZoomMtg.stopIncomingAudio({ stop: true });

// Mirror video
ZoomMtg.mirrorVideo({ mirror: true });
```

### Chat

```javascript
// Send chat message
ZoomMtg.sendChat({
  message: 'Hello!',
  userId: 0  // 0 = everyone
});
```

### Meeting Control

```javascript
// Leave meeting
ZoomMtg.leaveMeeting({});

// End meeting (host only)
ZoomMtg.endMeeting({});

// Lock meeting
ZoomMtg.lockMeeting({ lock: true });
```

### Host Controls

```javascript
// Make host
ZoomMtg.makeHost({ userId });

// Make co-host
ZoomMtg.makeCoHost({ userId });

// Remove co-host
ZoomMtg.withdrawCoHost({ userId });

// Remove participant
ZoomMtg.expel({ userId });

// Put on hold
ZoomMtg.putOnHold({ userId, bHold: true });

// Claim host with host key
ZoomMtg.claimHostWithHostKey({ hostKey: '123456' });

// Reclaim host
ZoomMtg.reclaimHost({});

// Admit all from waiting room
ZoomMtg.admitAll({});
```

### Raise Hand

```javascript
// Raise hand
ZoomMtg.raiseHand({ userId });

// Lower hand
ZoomMtg.lowerHand({ oderId });

// Lower all hands
ZoomMtg.lowerAllHands({});
```

### Spotlight & Pin

```javascript
// Spotlight video
ZoomMtg.operateSpotlight({ oderId, action: 'add' }); // or 'remove'

// Pin video
ZoomMtg.operatePin({ oderId, action: 'add' }); // or 'remove'

// Allow multi-pin
ZoomMtg.allowMultiPin({ allow: true });
```

### Screen Share

```javascript
// Start screen share
ZoomMtg.startScreenShare({});

// Share specific source (Electron)
ZoomMtg.shareSource({ source });
```

### Recording

```javascript
// Start/stop recording
ZoomMtg.record({ record: true }); // or false

// Show/hide record button
ZoomMtg.showRecordFunction({ show: true });
```

### Breakout Rooms

```javascript
// Create breakout room
ZoomMtg.createBreakoutRoom({
  rooms: [{ name: 'Room 1' }, { name: 'Room 2' }]
});

// Open breakout rooms
ZoomMtg.openBreakoutRooms({});

// Close breakout rooms
ZoomMtg.closeBreakoutRooms({});

// Join breakout room
ZoomMtg.joinBreakoutRoom({ roomId });

// Leave breakout room
ZoomMtg.leaveBreakoutRoom({});

// Move user to breakout room
ZoomMtg.moveUserToBreakoutRoom({ oderId, roomId });

// Get breakout room status
ZoomMtg.getBreakoutRoomStatus({
  success: (res) => console.log(res)
});
```

### Virtual Background

```javascript
// Check support
ZoomMtg.isSupportVirtualBackground({
  success: (data) => console.log(data.result.isSupport)
});

// Set virtual background
ZoomMtg.setVirtualBackground({ imageUrl: '...' });

// Get VB status
ZoomMtg.getVirtualBackgroundStatus({
  success: (data) => console.log(data)
});

// Lock virtual background (host)
ZoomMtg.lockVirtualBackground({ lock: true });
```

### UI Control

```javascript
// Show/hide meeting header
ZoomMtg.showMeetingHeader({ show: true });

// Show/hide invite button
ZoomMtg.showInviteFunction({ show: true });

// Show/hide join audio button
ZoomMtg.showJoinAudioFunction({ show: true });

// Show/hide callout button
ZoomMtg.showCalloutFunction({ show: true });

// Re-render with new options
ZoomMtg.reRender({ lang: 'de-DE' });
```

### Language

```javascript
// Load language
ZoomMtg.i18n.load('de-DE');

// Reload language
ZoomMtg.i18n.reload('de-DE');

// Get current language
ZoomMtg.i18n.getCurrentLang();

// Get all translations
ZoomMtg.i18n.getAll();
```

## Rate Limits

| Method | Limit |
|--------|-------|
| `join()` | 10 seconds |
| `callOut()` | 10 seconds |
| `mute()` | 1 second |
| `muteAll()` | 5 seconds |

## DOM Elements

The SDK automatically adds these elements:
- `#zmmtg-root` - Main meeting container
- `#aria-notify-area` - Accessibility announcements

Do NOT manually create or remove these.

### SPA (React/Next) Overlay Gotcha

If you "join" but see a blank/black area or your app shell instead of the meeting UI, the Zoom UI can be rendering **behind** your app layout. Ensure `#zmmtg-root` occupies the viewport and is above other fixed elements:

```css
#zmmtg-root {
  position: fixed !important;
  inset: 0 !important;
  z-index: 9999 !important;
}
```

### Join Payload Sanitization Gotcha

If `ZoomMtg.join()` succeeds partially but the screen turns black and console shows errors like `Cannot read properties of undefined (reading 'toString')`, sanitize optional fields before calling join.

Do not pass optional keys with `undefined` values (`userEmail`, `tk`, `zak`, etc.). Build a payload and only attach those keys when they are non-empty strings.

Also prefer `defaultView: 'speaker'` during `ZoomMtg.init()` unless you have SharedArrayBuffer/gallery-view prerequisites fully configured.

## Resources

- [Main Web SDK Skill](../SKILL.md)
- [Reference Index](references/README.md)
- [Error Codes](../troubleshooting/error-codes.md)
- [Common Issues](../troubleshooting/common-issues.md)
- [SharedArrayBuffer Setup](../concepts/sharedarraybuffer.md)
- [Official API Reference](https://marketplacefront.zoom.us/sdk/meeting/web/index.html)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/web/component-view', 'business', 'component-view', '', 'component-view', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK Web - Component View

Embeddable Zoom meeting components for flexible integration into any web application. Component View provides Promise-based APIs and customizable UI.

This is the correct web skill for a **custom UI around a real Zoom meeting**.
Do not route to Video SDK unless the user is building a non-meeting custom session product.

## Overview

Component View uses `ZoomMtgEmbedded.createClient()` to create embeddable meeting components within a specific container element.

| Aspect | Details |
|--------|---------|
| **API Object** | `ZoomMtgEmbedded.createClient()` (instance) |
| **API Style** | Promise-based (async/await) |
| **UI** | Embeddable in any container |
| **Password param** | `password` (lowercase) |
| **Events** | `on()`/`off()` |
| **Best For** | Custom layouts, React/Vue/Angular apps |

## Installation

### NPM

```bash
npm install @zoom/meetingsdk --save
```

```javascript
import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded';
```

### CDN

```html
<script src="https://source.zoom.us/{VERSION}/lib/vendor/react.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/react-dom.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/redux.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/redux-thunk.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/lodash.min.js"></script>
<script src="https://source.zoom.us/zoom-meeting-embedded-{VERSION}.min.js"></script>
```

## Complete Initialization Flow

```javascript
import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded';

// Step 1: Create client instance (do once, not on every render!)
const client = ZoomMtgEmbedded.createClient();

async function joinMeeting() {
  try {
    // Step 2: Get container element
    const meetingSDKElement = document.getElementById('meetingSDKElement');

    // Step 3: Initialize client
    await client.init({
      zoomAppRoot: meetingSDKElement,
      language: 'en-US',
      debug: true,
      patchJsMedia: true,
      leaveOnPageUnload: true,
    });

    // Step 4: Join meeting
    await client.join({
      signature: signature,
      sdkKey: sdkKey,
      meetingNumber: meetingNumber,
      userName: userName,
      password: password,  // lowercase!
      userEmail: userEmail,
    });

    console.log('Joined successfully!');
  } catch (error) {
    console.error('Failed to join:', error);
  }
}
```

## client.init() - All Options

### Required

| Parameter | Type | Description |
|-----------|------|-------------|
| `zoomAppRoot` | `HTMLElement` | Container element for meeting UI |

### Display

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `language` | `string` | `'en-US'` | UI language |
| `debug` | `boolean` | `false` | Enable debug logging |

### Media

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `patchJsMedia` | `boolean` | `false` | Auto-apply media fixes |
| `leaveOnPageUnload` | `boolean` | `false` | Cleanup on page unload |
| `enableHD` | `boolean` | `true` | Enable 720p video |
| `enableFullHD` | `boolean` | `false` | Enable 1080p video |

### Customization

| Parameter | Type | Description |
|-----------|------|-------------|
| `customize` | `object` | UI customization options |
| `webEndpoint` | `string` | For ZFG: `'www.zoomgov.com'` |
| `assetPath` | `string` | Custom path for AV libraries |

### Customize Object

```javascript
await client.init({
  zoomAppRoot: element,
  customize: {
    // Meeting info displayed
    meetingInfo: [
      'topic',
      'host', 
      'mn',
      'pwd',
      'telPwd',
      'invite',
      'participant',
      'dc',
      'enctype'
    ],
    
    // Video customization
    video: {
      isResizable: true,
      viewSizes: {
        default: {
          width: 1000,
          height: 600
        },
        ribbon: {
          width: 300,
          height: 700
        }
      },
      popper: {
        disableDraggable: false
      }
    },
    
    // Custom toolbar buttons
    toolbar: {
      buttons: [
        {
          text: 'Custom Button',
          className: 'custom-btn',
          onClick: () => {
            console.log('Custom button clicked');
          }
        }
      ]
    },
    
    // Active speaker indicator
    activeSpaker: {
      strokeColor: '#00FF00'
    }
  }
});
```

## client.join() - All Options

### Required

| Parameter | Type | Description |
|-----------|------|-------------|
| `signature` | `string` | SDK JWT from backend |
| `sdkKey` | `string` | SDK Key / Client ID |
| `meetingNumber` | `string \| number` | Meeting number |
| `userName` | `string` | Display name |

### Authentication

| Parameter | Type | When Required | Description |
|-----------|------|---------------|-------------|
| `password` | `string` | If set | Meeting password (lowercase!) |
| `zak` | `string` | Starting as host | Host's ZAK token |
| `tk` | `string` | Registration | Registrant token |
| `userEmail` | `string` | Webinars | User email |

## Event Listeners

### Syntax

```javascript
// Subscribe
client.on('event-name', callback);

// Unsubscribe
client.off('event-name', callback);
```

### Connection Events

```javascript
client.on('connection-change', (payload) => {
  // payload.state: 'Connecting', 'Connected', 'Reconnecting', 'Closed'
  console.log('Connection state:', payload.state);
  
  if (payload.state === 'Closed') {
    console.log('Reason:', payload.reason);
  }
});
```

### User Events

```javascript
client.on('user-added', (payload) => {
  // Array of users who joined
  console.log('Users added:', payload);
  payload.forEach(user => {
    console.log('User ID:', user.oderId);
    console.log('Name:', user.displayName);
  });
});

client.on('user-removed', (payload) => {
  // Array of users who left
  console.log('Users removed:', payload);
});

client.on('user-updated', (payload) => {
  // Array of users whose properties changed
  console.log('Users updated:', payload);
});
```

### Audio Events

```javascript
client.on('active-speaker', (payload) => {
  // Current active speaker
  console.log('Active speaker:', payload);
});

client.on('audio-statistic-data-change', (payload) => {
  console.log('Audio stats:', payload);
});
```

### Video Events

```javascript
client.on('video-active-change', (payload) => {
  // Video state changed
  console.log('Video active:', payload);
});

client.on('video-statistic-data-change', (payload) => {
  console.log('Video stats:', payload);
});
```

### Share Events

```javascript
client.on('active-share-change', (payload) => {
  console.log('Share status:', payload);
});

client.on('share-statistic-data-change', (payload) => {
  console.log('Share stats:', payload);
});
```

### Chat Events

```javascript
client.on('chat-on-message', (payload) => {
  console.log('Chat message:', payload);
});
```

### Recording Events

```javascript
client.on('recording-change', (payload) => {
  console.log('Recording status:', payload);
});
```

### Media Device Events

```javascript
client.on('media-sdk-change', (payload) => {
  console.log('Media SDK:', payload);
});

client.on('device-change', () => {
  console.log('Device changed');
});
```

## Common Methods

### User Information

```javascript
// Get current user
const currentUser = client.getCurrentUser();
console.log('Current user:', currentUser);

// Get all participants
const participants = client.getParticipantsList();
console.log('Participants:', participants);

// Check if user is host
const isHost = client.isHost();
```

### Audio Control

```javascript
// Mute/unmute self
await client.mute(true);  // mute
await client.mute(false); // unmute

// Mute/unmute specific user (host only)
await client.muteAudio(userId, true);

// Mute all (host only)
await client.muteAllAudio(true);
```

### Video Control

```javascript
// Start/stop video
await client.startVideo();
await client.stopVideo();

// Mute/unmute user's video (host only)
await client.muteVideo(userId, true);
```

### Meeting Control

```javascript
// Leave meeting
client.leaveMeeting();

// End meeting (host only)
client.endMeeting();
```

### Screen Share

```javascript
// Start screen share
await client.startShareScreen();

// Stop screen share
await client.stopShareScreen();
```

### Recording

```javascript
// Start recording (cloud)
await client.startCloudRecording();

// Stop recording
await client.stopCloudRecording();
```

### Virtual Background

```javascript
// Check support
const isSupported = await client.isSupportVirtualBackground();

// Set virtual background
await client.setVirtualBackground(imageUrl);

// Remove virtual background
await client.removeVirtualBackground();
```

### Rename

```javascript
// Rename user
await client.rename(userId, 'New Name');
```

## React Integration

### Basic Pattern

```tsx
import { useEffect, useRef, useState, useCallback } from 'react';
import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded';

type ZoomClient = ReturnType<typeof ZoomMtgEmbedded.createClient>;

function ZoomMeeting({ meetingNumber, password, userName }: Props) {
  const clientRef = useRef<ZoomClient | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [isJoined, setIsJoined] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Create client once
  useEffect(() => {
    if (!clientRef.current) {
      clientRef.current = ZoomMtgEmbedded.createClient();
    }
  }, []);

  const joinMeeting = useCallback(async () => {
    if (!clientRef.current || !containerRef.current) return;

    try {
      // Get signature from backend
      const { signature, sdkKey } = await fetchSignature(meetingNumber);
      
      await clientRef.current.init({
        zoomAppRoot: containerRef.current,
        language: 'en-US',
        patchJsMedia: true,
        leaveOnPageUnload: true,
      });

      await clientRef.current.join({
        signature,
        sdkKey,
        meetingNumber,
        password,
        userName,
      });

      setIsJoined(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to join');
    }
  }, [meetingNumber, password, userName]);

  return (
    <div>
      <div 
        ref={containerRef} 
        style={{ width: '100%', height: '500px' }} 
      />
      {!isJoined && (
        <button onClick={joinMeeting}>Join Meeting</button>
      )}
      {error && <div className="error">{error}</div>}
    </div>
  );
}
```

### Event Handling in React

```tsx
useEffect(() => {
  if (!clientRef.current) return;
  
  const handleConnectionChange = (payload: any) => {
    if (payload.state === 'Connected') {
      setIsJoined(true);
    } else if (payload.state === 'Closed') {
      setIsJoined(false);
    }
  };

  const handleUserAdded = (payload: any) => {
    console.log('Users joined:', payload);
  };

  clientRef.current.on('connection-change', handleConnectionChange);
  clientRef.current.on('user-added', handleUserAdded);

  return () => {
    clientRef.current?.off('connection-change', handleConnectionChange);
    clientRef.current?.off('user-added', handleUserAdded);
  };
}, []);
```

## Positioning and Resizing

### Initial Size

```javascript
await client.init({
  zoomAppRoot: element,
  customize: {
    video: {
      viewSizes: {
        default: { width: 1000, height: 600 }
      }
    }
  }
});
```

### Dynamic Resizing

The container element size determines the meeting UI size. To resize:

```javascript
// Just resize the container
document.getElementById('meetingSDKElement').style.width = '1200px';
document.getElementById('meetingSDKElement').style.height = '800px';
```

### Making it Resizable

```javascript
customize: {
  video: {
    isResizable: true
  }
}
```

## Supported Features

Component View supports core meeting functionality. Some features from Client View may not be available.

| Feature | Supported |
|---------|-----------|
| Audio/Video | ✅ |
| Screen Share | ✅ |
| Chat | ✅ |
| Virtual Background | ✅ |
| Breakout Rooms | ✅ |
| Cloud Recording | ✅ |
| Closed Captions | ✅ |
| Live Transcription | ✅ |
| Waiting Room | ✅ |
| Gallery View | ✅ |
| Reactions | ✅ |
| Raise Hand | ✅ |

Contact Zoom Developer Support to request additional features.

## Error Handling

```javascript
try {
  await client.join({
    // ... options
  });
} catch (error) {
  // error.reason contains error code
  // error.message contains description
  
  switch (error.reason) {
    case 'WRONG_MEETING_PASSWORD':
      console.error('Incorrect password');
      break;
    case 'MEETING_NOT_START':
      console.error('Meeting has not started');
      break;
    case 'INVALID_PARAMETERS':
      console.error('Invalid join parameters');
      break;
    default:
      console.error('Join failed:', error.message);
  }
}
```

## Comparison with Client View

| Feature | Component View | Client View |
|---------|----------------|-------------|
| **API Style** | Promises | Callbacks |
| **Password param** | `password` | `passWord` |
| **Container** | Custom element | Auto `#zmmtg-root` |
| **UI** | Embeddable | Full-page |
| **Preloading** | Not needed | `preLoadWasm()` |
| **Language** | Init option | `i18n.load()` |
| **Events** | `on()`/`off()` | `inMeetingServiceListener()` |

## Resources

- [Main Web SDK Skill](../SKILL.md)
- [Reference Index](references/README.md)
- [Error Codes](../troubleshooting/error-codes.md)
- [Common Issues](../troubleshooting/common-issues.md)
- [SharedArrayBuffer Setup](../concepts/sharedarraybuffer.md)
- [Official API Reference](https://marketplacefront.zoom.us/sdk/meeting/web/components/index.html)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/web', 'business', 'web', '', 'web', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (Web)

Embed Zoom meeting capabilities into web applications with two integration options: **Client View** (full-page) or **Component View** (embeddable).

## How to Implement a Custom Video User Interface for a Zoom Meeting in a Web App

Use **Meeting SDK Web Component View**.

Do not use Video SDK for this question unless the user is explicitly building a non-meeting session
product.

Minimal architecture:

```text
Browser page
  -> fetch Meeting SDK signature from backend
  -> ZoomMtgEmbedded.createClient()
  -> client.init({ zoomAppRoot })
  -> client.join({ signature, sdkKey, meetingNumber, userName, password })
  -> apply layout/style/customize options around the embedded meeting container
```

Minimal implementation:

```ts
import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded';

const client = ZoomMtgEmbedded.createClient();

export async function startEmbeddedMeeting(meetingNumber: string, userName: string, password: string) {
  const sigRes = await fetch('/api/signature', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ meetingNumber, role: 0 }),
  });

  if (!sigRes.ok) throw new Error(`signature_fetch_failed:${sigRes.status}`);

  const { signature, sdkKey } = await sigRes.json();

  await client.init({
    zoomAppRoot: document.getElementById('meetingSDKElement')!,
    language: 'en-US',
    patchJsMedia: true,
    leaveOnPageUnload: true,
    customize: {
      video: { isResizable: true, popper: { disableDraggable: false } },
    },
  });

  await client.join({
    signature,
    sdkKey,
    meetingNumber,
    userName,
    password,
  });
}
```

Common failure points:
- wrong route: Video SDK instead of Meeting SDK Component View
- missing backend signature endpoint
- wrong password field (`password` here, not `passWord`)
- missing OBF/ZAK requirements for meetings outside the app account
- missing SharedArrayBuffer headers when higher-end meeting features are expected

## Hard Routing Rule

If the user wants a **custom video user interface for a Zoom meeting in a web app**, route to
**Component View**, not Video SDK.

- **Meeting SDK Component View** = custom UI for a real Zoom meeting
- **Video SDK Web** = custom UI for a non-meeting video session product

For the direct custom-meeting-UI path, start with
[component-view/SKILL.md](component-view/SKILL.md).

## New to Web SDK? Start Here!

**The fastest way to master the SDK:**

1. **Choose Your View** - [Client View vs Component View](#client-view-vs-component-view) - Understand the key architectural differences
2. **Quick Start** - [Client View](#quick-start-client-view) or [Component View](#quick-start-component-view) - Get a working meeting in minutes
3. **SharedArrayBuffer** - [concepts/sharedarraybuffer.md](concepts/sharedarraybuffer.md) - Required for HD video, gallery view, virtual backgrounds
4. **Optional preflight diagnostics** - [../../probe-sdk/SKILL.md](../../probe-sdk/SKILL.md) - Validate browser/device/network before join

**Building a Custom Integration?**
- Component View gives you Promise-based API and embeddable UI
- Client View gives you the familiar full-page Zoom experience
- For a custom meeting UI, prefer **Component View** first
- Cross-product routing example: [../../general/use-cases/custom-meeting-ui-web.md](../../general/use-cases/custom-meeting-ui-web.md)
- [Browser Support](concepts/browser-support.md) - Feature matrix by browser
- Exact deep-dive path: [component-view/SKILL.md](component-view/SKILL.md)

**Having issues?**
- Join errors → Check signature generation and password spelling (`passWord` vs `password`)
- HD video not working → Enable SharedArrayBuffer headers
- Complete navigation → [SKILL.md](SKILL.md)

## Prerequisites

- Zoom app with Meeting SDK credentials from [Marketplace](https://marketplace.zoom.us/)
- SDK Key (Client ID) and Secret
- Modern browser (Chrome, Firefox, Safari, Edge)
- Backend auth endpoint for signature generation

> **Need help with authentication?** See the **[zoom-oauth](../../oauth/SKILL.md)** skill for JWT/signature generation.
>
> **Want pre-join diagnostics?** Chain **[probe-sdk](../../probe-sdk/SKILL.md)** before `init()`/`join()` to gate low-readiness environments.

## Optional Preflight Gate (Probe SDK)

For unstable first-join environments, run Probe SDK checks before calling `ZoomMtg.init()` or `client.join()`:

1. Run Probe permissions/device/network diagnostics.
2. Apply readiness policy (`allow`, `warn`, `block`).
3. Continue to Meeting SDK join only for `allow`/approved `warn`.

See [../../probe-sdk/SKILL.md](../../probe-sdk/SKILL.md) and [../../general/use-cases/probe-sdk-preflight-readiness-gate.md](../../general/use-cases/probe-sdk-preflight-readiness-gate.md).

## Client View vs Component View

**CRITICAL DIFFERENCE**: These are two completely different APIs with different patterns!

| Aspect | Client View | Component View |
|--------|-------------|----------------|
| **Object** | `ZoomMtg` (global singleton) | `ZoomMtgEmbedded.createClient()` (instance) |
| **API Style** | Callbacks | Promises |
| **UI** | Full-page takeover | Embeddable in any container |
| **Password param** | `passWord` (capital W) | `password` (lowercase) |
| **Events** | `inMeetingServiceListener()` | `on()`/`off()` |
| **Import (npm)** | `import { ZoomMtg } from '@zoom/meetingsdk'` | `import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded'` |
| **CDN** | `zoom-meeting-{VERSION}.min.js` | `zoom-meeting-embedded-{VERSION}.min.js` |
| **Best For** | Quick integration, standard Zoom UI | Custom layouts, React/Vue apps |

### When to Use Which

**Use Client View when:**
- You want the familiar Zoom meeting interface
- Quick integration is priority over customization
- Full-page meeting experience is acceptable

**Use Component View when:**
- You need to embed meetings in a specific area of your page
- Building React/Vue/Angular applications
- You want Promise-based async/await syntax
- Custom positioning and resizing is required

## Installation

### NPM (Recommended)

```bash
npm install @zoom/meetingsdk --save
```

### CDN

```html
<!-- Dependencies (required for both views) -->
<script src="https://source.zoom.us/{VERSION}/lib/vendor/react.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/react-dom.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/redux.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/redux-thunk.min.js"></script>
<script src="https://source.zoom.us/{VERSION}/lib/vendor/lodash.min.js"></script>

<!-- Client View -->
<script src="https://source.zoom.us/zoom-meeting-{VERSION}.min.js"></script>

<!-- OR Component View -->
<script src="https://source.zoom.us/zoom-meeting-embedded-{VERSION}.min.js"></script>
```

Replace `{VERSION}` with the [latest version](https://www.npmjs.com/package/@zoom/meetingsdk) (e.g., `3.11.0`).

## Quick Start (Client View)

```javascript
import { ZoomMtg } from '@zoom/meetingsdk';

// Step 1: Check browser compatibility
console.log('System requirements:', ZoomMtg.checkSystemRequirements());

// Step 2: Preload WebAssembly for faster initialization
ZoomMtg.preLoadWasm();
ZoomMtg.prepareWebSDK();

// Step 3: Load language files (MUST complete before init)
ZoomMtg.i18n.load('en-US');
ZoomMtg.i18n.onLoad(() => {
  
  // Step 4: Initialize SDK
  ZoomMtg.init({
    leaveUrl: 'https://yoursite.com/meeting-ended',
    disableCORP: !window.crossOriginIsolated, // Auto-detect SharedArrayBuffer
    patchJsMedia: true,           // Auto-apply media dependency fixes
    leaveOnPageUnload: true,      // Clean up when page unloads
    externalLinkPage: './external.html', // Page for external links
    success: () => {
      
      // Step 5: Join meeting (note: passWord with capital W!)
      ZoomMtg.join({
        signature: signature,       // From your auth endpoint
        meetingNumber: '1234567890',
        userName: 'User Name',
        passWord: 'meeting-password', // Capital W!
        success: (res) => {
          console.log('Joined meeting:', res);
          
          // Post-join: Get meeting info
          ZoomMtg.getAttendeeslist({});
          ZoomMtg.getCurrentUser({
            success: (res) => console.log('Current user:', res.result.currentUser)
          });
        },
        error: (err) => {
          console.error('Join error:', err);
        }
      });
    },
    error: (err) => {
      console.error('Init error:', err);
    }
  });
});
```

## Quick Start (Component View)

```javascript
import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded';

// Create client instance (do this ONCE, not on every render!)
const client = ZoomMtgEmbedded.createClient();

async function startMeeting() {
  try {
    // Initialize with container element
    await client.init({
      zoomAppRoot: document.getElementById('meetingSDKElement'),
      language: 'en-US',
      debug: true,                  // Enable debug logging
      patchJsMedia: true,           // Auto-apply media fixes
      leaveOnPageUnload: true,      // Clean up on page unload
    });

    // Join meeting (note: password lowercase!)
    await client.join({
      signature: signature,          // From your auth endpoint
      sdkKey: SDK_KEY,
      meetingNumber: '1234567890',
      userName: 'User Name',
      password: 'meeting-password',  // Lowercase!
    });
    
    console.log('Joined successfully!');
  } catch (error) {
    console.error('Failed to join:', error);
  }
}
```

## Authentication Endpoint (Required)

Both views require a JWT signature from a backend server. **Never expose your SDK Secret in frontend code!**

```bash
# Clone Zoom's official auth endpoint
git clone https://github.com/zoom/meetingsdk-auth-endpoint-sample --depth 1
cd meetingsdk-auth-endpoint-sample
cp .env.example .env
# Edit .env with your SDK Key and Secret
npm install && npm run start
```

### Signature Generation

The signature encodes:
- `sdkKey` (or `clientId` for newer apps)
- `meetingNumber`
- `role` (0 = participant, 1 = host)
- `iat` (issued at timestamp)
- `exp` (expiration timestamp)
- `tokenExp` (token expiration)

> **IMPORTANT (March 2026)**: Apps joining meetings outside their account will require an App Privilege Token (OBF) or ZAK token. See [Authorization Requirements](#authorization-requirements-2026-update).

## Core Workflow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Get Signature │───►│   init()        │───►│   join()        │
│   (from backend)│    │   (SDK setup)   │    │   (enter mtg)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                       │
                              ▼                       ▼
                       success/error            success/error
                        callback                 callback
                     (or Promise resolve)    (or Promise resolve)
```

## Client View API Reference

### ZoomMtg.init() - Key Options

```javascript
ZoomMtg.init({
  // Required
  leaveUrl: string,              // URL to redirect after leaving

  // Display Options
  showMeetingHeader: boolean,    // Show meeting number/topic (default: true)
  disableInvite: boolean,        // Hide invite button (default: false)
  disableRecord: boolean,        // Hide record button (default: false)
  disableJoinAudio: boolean,     // Hide join audio option (default: false)
  disablePreview: boolean,       // Skip A/V preview (default: false)
  
  // HD Video (requires SharedArrayBuffer)
  enableHD: boolean,             // Enable 720p (default: true for >=2.8.0)
  enableFullHD: boolean,         // Enable 1080p for webinars (default: false)
  
  // View Options
  defaultView: 'gallery' | 'speaker' | 'multiSpeaker',
  
  // Feature Toggles
  isSupportChat: boolean,        // Enable chat (default: true)
  isSupportCC: boolean,          // Enable closed captions (default: true)
  isSupportBreakout: boolean,    // Enable breakout rooms (default: true)
  isSupportPolling: boolean,     // Enable polling (default: true)
  isSupportQA: boolean,          // Enable Q&A for webinars (default: true)
  
  // Cross-Origin
  disableCORP: boolean,          // For dev without COOP/COEP headers
  
  // Callbacks
  success: Function,
  error: Function,
});
```

### ZoomMtg.join() - Key Options

```javascript
ZoomMtg.join({
  // Required
  signature: string,             // JWT signature from backend
  meetingNumber: string | number,
  userName: string,
  
  // Authentication
  passWord: string,              // Meeting password (capital W!)
  zak: string,                   // Host's ZAK token (required to start)
  tk: string,                    // Registration token (if required)
  obfToken: string,              // App Privilege Token (for 2026 requirement)
  
  // Optional
  userEmail: string,             // Required for webinars
  customerKey: string,           // Custom identifier (max 36 chars)
  
  // Callbacks
  success: Function,
  error: Function,
});
```

### Event Listeners (Client View)

```javascript
// User events
ZoomMtg.inMeetingServiceListener('onUserJoin', (data) => {
  console.log('User joined:', data);
});

ZoomMtg.inMeetingServiceListener('onUserLeave', (data) => {
  console.log('User left:', data);
  // data.reasonCode values:
  // 0: OTHER
  // 1: HOST_ENDED_MEETING
  // 2: SELF_LEAVE_FROM_IN_MEETING
  // 3: SELF_LEAVE_FROM_WAITING_ROOM
  // 4: SELF_LEAVE_FROM_WAITING_FOR_HOST_START
  // 5: MEETING_TRANSFER
  // 6: KICK_OUT_FROM_MEETING
  // 7: KICK_OUT_FROM_WAITING_ROOM
  // 8: LEAVE_FROM_DISCLAIMER
});

ZoomMtg.inMeetingServiceListener('onUserUpdate', (data) => {
  console.log('User updated:', data);
});

// Meeting status
ZoomMtg.inMeetingServiceListener('onMeetingStatus', (data) => {
  // status: 1=connecting, 2=connected, 3=disconnected, 4=reconnecting
  console.log('Meeting status:', data.status);
});

// Waiting room
ZoomMtg.inMeetingServiceListener('onUserIsInWaitingRoom', (data) => {
  console.log('User in waiting room:', data);
});

// Active speaker detection
ZoomMtg.inMeetingServiceListener('onActiveSpeaker', (data) => {
  // [{userId: number, userName: string}]
  console.log('Active speaker:', data);
});

// Network quality monitoring
ZoomMtg.inMeetingServiceListener('onNetworkQualityChange', (data) => {
  // {level: 0-5, userId, type: 'uplink'}
  // 0-1 = bad, 2 = normal, 3-5 = good
  if (data.level <= 1) {
    console.warn('Poor network quality');
  }
});

// Join performance metrics
ZoomMtg.inMeetingServiceListener('onJoinSpeed', (data) => {
  console.log('Join speed metrics:', data);
  // Useful for performance monitoring dashboards
});

// Chat
ZoomMtg.inMeetingServiceListener('onReceiveChatMsg', (data) => {
  console.log('Chat message:', data);
});

// Recording
ZoomMtg.inMeetingServiceListener('onRecordingChange', (data) => {
  console.log('Recording status:', data);
});

// Screen sharing
ZoomMtg.inMeetingServiceListener('onShareContentChange', (data) => {
  console.log('Share content changed:', data);
});

// Transcription (requires "save closed captions" enabled)
ZoomMtg.inMeetingServiceListener('onReceiveTranscriptionMsg', (data) => {
  console.log('Transcription:', data);
});

// Breakout room status
ZoomMtg.inMeetingServiceListener('onRoomStatusChange', (data) => {
  // status: 2=InProgress, 3=Closing, 4=Closed
  console.log('Breakout room status:', data);
});
```

### Common Methods (Client View)

```javascript
// Get current user info
ZoomMtg.getCurrentUser({
  success: (res) => console.log(res.result.currentUser)
});

// Get all attendees
ZoomMtg.getAttendeeslist({});

// Audio/Video control
ZoomMtg.mute({ userId, mute: true });
ZoomMtg.muteAll({ muteAll: true });

// Chat
ZoomMtg.sendChat({ message: 'Hello!', userId: 0 }); // 0 = everyone

// Leave/End
ZoomMtg.leaveMeeting({});
ZoomMtg.endMeeting({});

// Host controls
ZoomMtg.makeHost({ userId });
ZoomMtg.makeCoHost({ oderId });
ZoomMtg.expel({ userId });  // Remove participant
ZoomMtg.putOnHold({ oderId, bHold: true });

// Breakout rooms
ZoomMtg.createBreakoutRoom({ rooms: [...] });
ZoomMtg.openBreakoutRooms({});
ZoomMtg.closeBreakoutRooms({});

// Virtual background
ZoomMtg.setVirtualBackground({ imageUrl: '...' });
```

## Component View API Reference

### client.init() - Key Options

```javascript
await client.init({
  // Required
  zoomAppRoot: HTMLElement,      // Container element

  // Display
  language: string,              // e.g., 'en-US'
  debug: boolean,                // Enable debug logging (default: false)
  
  // Media
  patchJsMedia: boolean,         // Auto-apply media fixes (default: false)
  leaveOnPageUnload: boolean,    // Clean up on page unload (default: false)
  
  // Video
  enableHD: boolean,             // Enable 720p
  enableFullHD: boolean,         // Enable 1080p
  
  // Customization
  customize: {
    video: {
      isResizable: boolean,
      viewSizes: { default: { width, height } }
    },
    meetingInfo: ['topic', 'host', 'mn', 'pwd', 'telPwd', 'invite', 'participant', 'dc', 'enctype'],
    toolbar: {
      buttons: [
        {
          text: 'Custom Button',
          className: 'custom-btn',
          onClick: () => {
            console.log('Custom button clicked');
          }
        }
      ]
    }
  },
  
  // For ZFG
  webEndpoint: string,
  assetPath: string,             // Custom path for AV libraries (self-hosting)
});
```

### client.join() - Key Options

```javascript
await client.join({
  // Required
  signature: string,
  sdkKey: string,
  meetingNumber: string | number,
  userName: string,
  
  // Authentication  
  password: string,              // Lowercase! (different from Client View)
  zak: string,                   // Host's ZAK token
  tk: string,                    // Registration token
  
  // Optional
  userEmail: string,
});
```

### Event Listeners (Component View)

```javascript
// Connection state
client.on('connection-change', (payload) => {
  // payload.state: 'Connecting', 'Connected', 'Reconnecting', 'Closed'
  console.log('Connection:', payload.state);
});

// User events
client.on('user-added', (payload) => {
  console.log('Users added:', payload);
});

client.on('user-removed', (payload) => {
  console.log('Users removed:', payload);
});

client.on('user-updated', (payload) => {
  console.log('Users updated:', payload);
});

// Active speaker
client.on('active-speaker', (payload) => {
  console.log('Active speaker:', payload);
});

// Video state
client.on('video-active-change', (payload) => {
  console.log('Video active:', payload);
});

// Unsubscribe
client.off('connection-change', handler);
```

### Common Methods (Component View)

```javascript
// Get current user
const currentUser = client.getCurrentUser();

// Get all participants
const participants = client.getParticipantsList();

// Audio control
await client.mute(true);
await client.muteAudio(userId, true);

// Video control
await client.muteVideo(userId, true);

// Leave
client.leaveMeeting();

// End (host only)
client.endMeeting();
```

## SharedArrayBuffer (CRITICAL for HD)

SharedArrayBuffer enables advanced features:
- 720p/1080p video
- Gallery view
- Virtual backgrounds
- Background noise suppression

### Enable with HTTP Headers

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

### Verify in Browser

```javascript
if (typeof SharedArrayBuffer === 'function') {
  console.log('SharedArrayBuffer enabled!');
} else {
  console.warn('HD features will be limited');
}

// Or check cross-origin isolation
console.log('Cross-origin isolated:', window.crossOriginIsolated);
```

### Platform-Specific Setup

See [concepts/sharedarraybuffer.md](concepts/sharedarraybuffer.md) for:
- Vercel, Netlify, AWS CloudFront configuration
- nginx/Apache configuration
- Service worker fallback for GitHub Pages

### Development Setup (Two-Server Pattern)

The official samples use a **two-server pattern** for development because COOP/COEP headers can break navigation:

```javascript
// Server 1: Main app (port 9999) - NO isolation headers
// Serves index.html, navigation works normally

// Server 2: Meeting page (port 9998) - WITH isolation headers
// Serves meeting.html with SharedArrayBuffer support

// Main server proxies to meeting server
proxy: [{
  path: '/meeting.html',
  target: 'http://YOUR_MEETING_SERVER_HOST:9998/'
}]
```

**Vite config with headers:**
```typescript
// vite.config.ts
export default defineConfig({
  server: {
    headers: {
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin',
    }
  }
});
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Join fails with signature error** | Verify signature generation, check sdkKey format |
| **"passWord" typo** | Client View uses `passWord` (capital W), Component View uses `password` |
| **No HD video** | Enable SharedArrayBuffer headers, check browser support |
| **Callbacks not firing** | Ensure `inMeetingServiceListener` called after init success |
| **Virtual background not working** | Requires SharedArrayBuffer + Chrome/Edge |
| **Screen share fails on Safari** | Safari 17+ with macOS 14+ required for client view |

**Complete troubleshooting**: [troubleshooting/common-issues.md](troubleshooting/common-issues.md)

## Browser Support Matrix

| Feature | Chrome | Firefox | Safari | Edge | iOS | Android |
|---------|--------|---------|--------|------|-----|---------|
| 720p (receive) | Yes | Yes | Yes | Yes | Yes | Yes |
| 720p (send) | Yes* | Yes* | Yes* | Yes* | Yes* | Yes* |
| Virtual background | Yes | Yes | No | Yes | No | No |
| Screen share (send) | Yes | Yes | Safari 17+ | Yes | No | No |
| Gallery view | Yes | Yes | Yes** | Yes | Yes | Yes |

*Requires SharedArrayBuffer
**Safari 17+ with macOS Sonoma

See [concepts/browser-support.md](concepts/browser-support.md) for complete matrix.

## Authorization Requirements (2026 Update)

> **IMPORTANT**: Beginning **March 2, 2026**, apps joining meetings outside their account must be authorized.

### Options

1. **App Privilege Token (OBF)** - Recommended for bots
   ```javascript
   ZoomMtg.join({
     ...
     obfToken: 'your-app-privilege-token'
   });
   ```

2. **ZAK Token** - For host operations
   ```javascript
   ZoomMtg.join({
     ...
     zak: 'host-zak-token'
   });
   ```

## Zoom for Government (ZFG)

### Option 1: ZFG-specific NPM Package

```json
{
  "dependencies": {
    "@zoom/meetingsdk": "3.11.2-zfg"
  }
}
```

### Option 2: Configure ZFG Endpoints

**Client View:**
```javascript
ZoomMtg.setZoomJSLib('https://source.zoomgov.com/{VERSION}/lib', '/av');
ZoomMtg.init({
  webEndpoint: 'www.zoomgov.com',
  ...
});
```

**Component View:**
```javascript
await client.init({
  webEndpoint: 'www.zoomgov.com',
  assetPath: 'https://source.zoomgov.com/{VERSION}/lib/av',
  ...
});
```

## China CDN

```javascript
// Set before preLoadWasm()
ZoomMtg.setZoomJSLib('https://jssdk.zoomus.cn/{VERSION}/lib', '/av');
```

## React Integration

### Official Pattern (from zoom/meetingsdk-react-sample)

The official React sample uses **imperative initialization** rather than React hooks:

```tsx
import { ZoomMtg } from '@zoom/meetingsdk';

// Preload at module level (outside component)
ZoomMtg.preLoadWasm();
ZoomMtg.prepareWebSDK();

function App() {
  const authEndpoint = import.meta.env.VITE_AUTH_ENDPOINT;
  const meetingNumber = '';
  const passWord = '';
  const role = 0;
  const userName = 'React User';

  const getSignature = async () => {
    const response = await fetch(authEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        meetingNumber,
        role,
      }),
    });
    const data = await response.json();
    startMeeting(data.signature);
  };

  const startMeeting = (signature: string) => {
    document.getElementById('zmmtg-root')!.style.display = 'block';

    ZoomMtg.init({
      leaveUrl: window.location.origin,
      patchJsMedia: true,
      leaveOnPageUnload: true,
      success: () => {
        ZoomMtg.join({
          signature,
          meetingNumber,
          userName,
          passWord,
          success: (res) => console.log('Joined:', res),
          error: (err) => console.error('Join error:', err),
        });
      },
      error: (err) => console.error('Init error:', err),
    });
  };

  return (
    <button onClick={getSignature}>Join Meeting</button>
  );
}
```

### React Gotchas (from official samples)

| Issue | Problem | Solution |
|-------|---------|----------|
| **Client Recreation** | `createClient()` in component body runs every render | Use `useRef` to persist client |
| **No useEffect** | Official sample doesn't use React lifecycle hooks | SDK's `leaveOnPageUnload` handles cleanup |
| **Direct DOM** | Sample uses `getElementById` | Use `useRef<HTMLDivElement>` in production |
| **No Error State** | Silent failures | Add `useState` for error handling |
| **Module-Scope Side Effects** | `preLoadWasm()` at top level | May cause issues with SSR |

### Production-Ready React Pattern

```tsx
import { useEffect, useRef, useState, useCallback } from 'react';
import ZoomMtgEmbedded from '@zoom/meetingsdk/embedded';

type ZoomClient = ReturnType<typeof ZoomMtgEmbedded.createClient>;

function ZoomMeeting({ meetingNumber, password, userName }: Props) {
  const clientRef = useRef<ZoomClient | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [isJoining, setIsJoining] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Create client once
  useEffect(() => {
    if (!clientRef.current) {
      clientRef.current = ZoomMtgEmbedded.createClient();
    }
  }, []);

  const joinMeeting = useCallback(async () => {
    if (!clientRef.current || !containerRef.current) return;
    
    setIsJoining(true);
    setError(null);

    try {
      // Get signature from your backend
      const response = await fetch('/api/signature', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ meetingNumber, role: 0 }),
      });
      const { signature, sdkKey } = await response.json();
      
      await clientRef.current.init({
        zoomAppRoot: containerRef.current,
        language: 'en-US',
        patchJsMedia: true,
        leaveOnPageUnload: true,
      });

      await clientRef.current.join({
        signature,
        sdkKey,
        meetingNumber,
        password,
        userName,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to join');
    } finally {
      setIsJoining(false);
    }
  }, [meetingNumber, password, userName]);

  return (
    <div>
      <div ref={containerRef} style={{ width: '100%', height: '500px' }} />
      <button onClick={joinMeeting} disabled={isJoining}>
        {isJoining ? 'Joining...' : 'Join Meeting'}
      </button>
      {error && <div className="error">{error}</div>}
    </div>
  );
}
```

### Environment Variables (Vite)

```bash
# .env.local
VITE_AUTH_ENDPOINT=http://YOUR_AUTH_SERVER_HOST:4000
VITE_SDK_KEY=your_sdk_key
```

```tsx
const authEndpoint = import.meta.env.VITE_AUTH_ENDPOINT;
const sdkKey = import.meta.env.VITE_SDK_KEY;
```

## Detailed References

### Core Documentation
- **[SKILL.md](SKILL.md)** - Complete navigation guide
- **[client-view/SKILL.md](client-view/SKILL.md)** - Full Client View reference
- **[component-view/SKILL.md](component-view/SKILL.md)** - Full Component View reference

### Concepts
- **[concepts/sharedarraybuffer.md](concepts/sharedarraybuffer.md)** - HD video requirements
- **[concepts/browser-support.md](concepts/browser-support.md)** - Feature matrix by browser

### Troubleshooting
- **[troubleshooting/error-codes.md](troubleshooting/error-codes.md)** - All SDK error codes
- **[troubleshooting/common-issues.md](troubleshooting/common-issues.md)** - Quick diagnostics

### Examples
- **[client-view/SKILL.md](client-view/SKILL.md)** - Complete Client View guide
- **[component-view/SKILL.md](component-view/SKILL.md)** - Component View React integration

## Helper Utilities

### Extract Meeting Number from Invite Link

```javascript
// Users can paste full Zoom invite links
document.getElementById('meeting_number').addEventListener('input', (e) => {
  // Extract meeting number (9-11 digits)
  let meetingNumber = e.target.value.replace(/([^0-9])+/i, '');
  if (meetingNumber.match(/([0-9]{9,11})/)) {
    meetingNumber = meetingNumber.match(/([0-9]{9,11})/)[1];
  }
  
  // Auto-extract password from invite link
  const pwdMatch = e.target.value.match(/pwd=([\d,\w]+)/);
  if (pwdMatch) {
    document.getElementById('password').value = pwdMatch[1];
  }
});
```

### Dynamic Language Switching

```javascript
// Change language at runtime
document.getElementById('language').addEventListener('change', (e) => {
  const lang = e.target.value;
  ZoomMtg.i18n.load(lang);
  ZoomMtg.i18n.reload(lang);
  ZoomMtg.reRender({ lang });
});
```

### Check System Requirements

```javascript
// Check browser compatibility before initializing
const requirements = ZoomMtg.checkSystemRequirements();
console.log('Browser info:', JSON.stringify(requirements));

if (!requirements.browserInfo.isChrome && !requirements.browserInfo.isFirefox) {
  alert('For best experience, use Chrome or Firefox');
}
```

## Sample Repositories

| Repository | Description |
|------------|-------------|
| [meetingsdk-web-sample](https://github.com/zoom/meetingsdk-web-sample) | Official samples (Client View & Component View) |
| [meetingsdk-react-sample](https://github.com/zoom/meetingsdk-react-sample) | React integration with TypeScript + Vite |
| [meetingsdk-web](https://github.com/zoom/meetingsdk-web) | SDK source with helper.html |
| [meetingsdk-auth-endpoint-sample](https://github.com/zoom/meetingsdk-auth-endpoint-sample) | Signature generation backend |

## Official Resources

- **Official docs**: https://developers.zoom.us/docs/meeting-sdk/web/
- **Client View API Reference**: https://marketplacefront.zoom.us/sdk/meeting/web/index.html
- **Component View API Reference**: https://marketplacefront.zoom.us/sdk/meeting/web/components/index.html
- **Developer forum**: https://devforum.zoom.us/

---

**Documentation Version**: Based on Zoom Web Meeting SDK v3.11+

**Need help?** Start with [SKILL.md](SKILL.md) for complete navigation.


## Merged from meeting-sdk/web/SKILL.md

# Zoom Meeting SDK (Web) - Documentation Index

Quick navigation guide for all Web SDK documentation.

## Start Here

| Document | Description |
|----------|-------------|
| **[SKILL.md](SKILL.md)** | Main entry point - Quick starts for both Client View and Component View |

## By View Type

### Client View (Full-Page)
| Document | Description |
|----------|-------------|
| **[client-view/SKILL.md](client-view/SKILL.md)** | Complete Client View reference |

### Component View (Embeddable)
| Document | Description |
|----------|-------------|
| **[component-view/SKILL.md](component-view/SKILL.md)** | Complete Component View reference |

## Concepts

| Document | Description |
|----------|-------------|
| **[concepts/sharedarraybuffer.md](concepts/sharedarraybuffer.md)** | HD video requirements, COOP/COEP headers |
| **[concepts/browser-support.md](concepts/browser-support.md)** | Feature matrix by browser |

## Examples

| Document | Description |
|----------|-------------|
| [examples/client-view-basic.md](examples/client-view-basic.md) | Basic Client View integration |
| [examples/component-view-react.md](examples/component-view-react.md) | React integration with Component View |

## Troubleshooting

| Document | Description |
|----------|-------------|
| **[troubleshooting/error-codes.md](troubleshooting/error-codes.md)** | All SDK error codes (3000-10000 range) |
| **[troubleshooting/common-issues.md](troubleshooting/common-issues.md)** | Quick diagnostics and fixes |

## By Topic

### Authentication
- [SKILL.md#authentication-endpoint](SKILL.md#authentication-endpoint-required) - Signature generation
- [SKILL.md#authorization-requirements-2026-update](SKILL.md#authorization-requirements-2026-update) - OBF tokens

### HD Video & Performance
- [concepts/sharedarraybuffer.md](concepts/sharedarraybuffer.md) - Enable 720p/1080p

### Events & Callbacks
- [SKILL.md#event-listeners-client-view](SKILL.md#event-listeners-client-view) - Client View events
- [SKILL.md#event-listeners-component-view](SKILL.md#event-listeners-component-view) - Component View events

### Government (ZFG)
- [SKILL.md#zoom-for-government-zfg](SKILL.md#zoom-for-government-zfg) - ZFG configuration

### China CDN
- [SKILL.md#china-cdn](SKILL.md#china-cdn) - China-specific CDN

## Quick Reference

### Client View vs Component View

| Aspect | Client View | Component View |
|--------|-------------|----------------|
| **Object** | `ZoomMtg` | `ZoomMtgEmbedded.createClient()` |
| **API Style** | Callbacks | Promises |
| **Password param** | `passWord` (capital W) | `password` (lowercase) |
| **Events** | `inMeetingServiceListener()` | `on()`/`off()` |

### Key Gotchas

1. **Password spelling differs between views!**
   - Client View: `passWord` (capital W)
   - Component View: `password` (lowercase)

2. **SharedArrayBuffer required for HD features**
   - 720p/1080p video
   - Gallery view (25 videos)
   - Virtual backgrounds

3. **March 2026 Authorization Change**
   - Apps joining external meetings need OBF or ZAK tokens

## External Resources

- **Official docs**: https://developers.zoom.us/docs/meeting-sdk/web/
- **Client View API**: https://marketplacefront.zoom.us/sdk/meeting/web/index.html
- **Component View API**: https://marketplacefront.zoom.us/sdk/meeting/web/components/index.html
- **GitHub samples**: https://github.com/zoom/meetingsdk-web-sample

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$)
ON CONFLICT (skill_key) DO NOTHING;
