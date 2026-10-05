INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/meeting-sdk/windows', 'business', 'windows', '', 'windows', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Meeting SDK (Windows)

Embed Zoom meeting capabilities into Windows desktop applications for native C++ integrations and headless bots.

## New to Zoom SDK? Start Here!

**The fastest way to master the SDK:**

1. **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - Learn the universal pattern that works for ALL 35+ features
2. **[Authentication Pattern](examples/authentication-pattern.md)** - Get a working bot joining meetings
3. **[Windows Message Loop](troubleshooting/windows-message-loop.md)** - Fix the #1 reason callbacks don't fire

**Building a Custom UI?**
- [Custom UI Architecture](concepts/custom-ui-architecture.md) - How SDK rendering actually works (child HWNDs, D3D, etc.)
- [Custom UI Video Rendering Example](examples/custom-ui-video-rendering.md) - Complete working code
- [SDK-Rendered vs Self-Rendered](concepts/custom-ui-vs-raw-data.md) - Choose the right approach
- [Custom UI Interface Methods](references/interface-methods.md) - All 13 required virtual methods

**Having issues?**
- Build errors → [Build Errors Guide](troubleshooting/build-errors.md)
- Callbacks not firing → [Windows Message Loop](troubleshooting/windows-message-loop.md)
- Quick diagnostics → [Common Issues](troubleshooting/common-issues.md)
- Performance / service quality → [service-quality.md](examples/service-quality.md)
- Deployment notes → [deployment.md](references/deployment.md)
- MSBuild from git bash → [Build Errors Guide](troubleshooting/build-errors.md#msbuild-command-pattern)
- Complete navigation → [SKILL.md](SKILL.md)

## Prerequisites

- Zoom app with Meeting SDK credentials (Client ID & Secret)
- Visual Studio 2019/2022 or later
- Windows 10 or later
- C++ development environment
- vcpkg for dependency management

> **Need help with authentication?** See the **[zoom-oauth](../../oauth/SKILL.md)** skill for JWT token generation.

## Project Preferences & Learnings

> **IMPORTANT**: These are hard-won preferences from real project experience. Follow these when creating new projects.

### Do NOT use CMake — Use native Visual Studio `.vcxproj`

**Always create a native Visual Studio `.sln` + `.vcxproj` project**, not a CMake project. Reasons:
- More standard and familiar for Windows C++ developers
- Developers can double-click the `.sln` to open in Visual Studio immediately
- Project settings (include dirs, lib dirs, preprocessor defines) are easier to see and edit in the VS Property Pages UI
- No extra CMake tooling or configuration step required
- Friendlier and easier for developers to understand and maintain

### `config.json` must be visible in Solution Explorer

The `config.json` file (containing `sdk_jwt`, `meeting_number`, `passcode`) must be:
1. **Included in the `.vcxproj`** as a `<None>` item with `<CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>`
2. **Placed in a "Config" filter** in the `.vcxproj.filters` file so it appears under a "Config" folder in Solution Explorer
3. **Easily editable** by developers directly from Solution Explorer — they should never have to hunt for it in File Explorer

Example `.vcxproj` entry:
```xml
<ItemGroup>
  <None Include="config.json">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </None>
</ItemGroup>
```

Example `.vcxproj.filters` entry:
```xml
<ItemGroup>
  <Filter Include="Config">
    <UniqueIdentifier>{GUID-HERE}</UniqueIdentifier>
  </Filter>
</ItemGroup>
<ItemGroup>
  <None Include="config.json">
    <Filter>Config</Filter>
  </None>
</ItemGroup>
```

## Overview

The Windows SDK is a **C++ native SDK** designed for:
- **Desktop applications** - Native Windows apps with full UI control
- **Headless bots** - Join meetings without UI
- **Raw media access** - Capture/send audio/video streams
- **Local recording** - Record meetings locally or to cloud

### Key Architectural Insight

The SDK follows a **universal 3-step pattern** for every feature:
1. **Get controller** (singleton): `meetingService->Get[Feature]Controller()`
2. **Implement event listener**: `class MyListener : public I[Feature]Event { ... }`
3. **Register and use**: `controller->SetEvent(listener)` then call methods

**This works for ALL features**: audio, video, chat, recording, participants, screen sharing, breakout rooms, webinars, Q&A, polling, whiteboard, and 20+ more!

Learn more: **[SDK Architecture Pattern Guide](concepts/sdk-architecture-pattern.md)**

## Quick Start

### 1. Download Windows SDK

Download from [Zoom Marketplace](https://marketplace.zoom.us/):
- Extract `zoom-meeting-sdk-windows_x86_64-{version}.zip`

### 2. Setup Project Structure

```
your-project/
  YourApp/
    SDK/
      x64/
        bin/          # DLL files and dependencies
        h/            # Header files
        lib/          # sdk.lib
      x86/
        bin/
        h/
        lib/
    YourApp.cpp
    YourApp.vcxproj
    config.json
```

Copy SDK files:
```cmd
xcopy /E /I sdk-package\x64 your-project\YourApp\SDK\x64\
xcopy /E /I sdk-package\x86 your-project\YourApp\SDK\x86\
```

### 3. Install Dependencies (vcpkg)

```powershell
# Install vcpkg
git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
cd C:\vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install

# Install dependencies
.\vcpkg install jsoncpp:x64-windows
.\vcpkg install curl:x64-windows
```

### 4. Configure Visual Studio Project

**Project Properties → C/C++ → General → Additional Include Directories:**
```
$(SolutionDir)SDK\$(PlatformTarget)\h
C:\vcpkg\packages\jsoncpp_x64-windows\include
C:\vcpkg\packages\curl_x64-windows\include
```

**Project Properties → Linker → General → Additional Library Directories:**
```
$(SolutionDir)SDK\$(PlatformTarget)\lib
```

**Project Properties → Linker → Input → Additional Dependencies:**
```
sdk.lib
```

**Post-Build Event** (Copy DLLs to output):
```cmd
xcopy /Y /D "$(SolutionDir)SDK\$(PlatformTarget)\bin\*.*" "$(OutDir)"
```

### 5. Configure Credentials

Create `config.json`:
```json
{
  "sdk_jwt": "YOUR_JWT_TOKEN",
  "meeting_number": "1234567890",
  "passcode": "password123",
  "zak": ""
}
```

### 6. Build & Run

- Open solution in Visual Studio
- Select x64 or x86 configuration
- Press F5 to build and run

## Core Workflow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  InitSDK    │───►│  AuthSDK    │───►│ JoinMeeting │───►│ Raw Data    │
│             │    │  (JWT)      │    │             │    │ Subscribe   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                         │                   │
                         ▼                   ▼
                   OnAuthComplete      onInMeeting
                     callback           callback
```

**⚠️ CRITICAL**: Add Windows message loop or callbacks won't fire!
```cpp
while (!done) {
    MSG msg;
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
}
```
See: [Windows Message Loop Guide](troubleshooting/windows-message-loop.md)

## Code Examples

> **💡 Pro Tip**: These are minimal examples. For complete, tested code see:
> - [Authentication Pattern](examples/authentication-pattern.md) - Full auth workflow
> - [Raw Video Capture](examples/raw-video-capture.md) - Complete video capture
> - [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Implement any feature

### Important: Include Order

**CRITICAL**: Include headers in this exact order or you'll get build errors:

```cpp
#include <windows.h>      // MUST be first
#include <cstdint>         // MUST be second (SDK headers use uint32_t)
// ... other standard headers ...
#include <zoom_sdk.h>
#include <meeting_service_components/meeting_audio_interface.h>  // BEFORE participants!
#include <meeting_service_components/meeting_participants_ctrl_interface.h>
```

See: [Build Errors Guide](troubleshooting/build-errors.md) for all dependency fixes.

### 1. Initialize SDK

```cpp
#include <windows.h>
#include <cstdint>
#include <zoom_sdk.h>

using namespace ZOOM_SDK_NAMESPACE;

bool InitMeetingSDK() {
    InitParam initParam;
    initParam.strWebDomain = L"https://zoom.us";
    initParam.strSupportUrl = L"https://zoom.us";
    initParam.emLanguageID = LANGUAGE_English;
    initParam.enableLogByDefault = true;
    initParam.enableGenerateDump = true;
    
    SDKError err = InitSDK(initParam);
    if (err != SDKERR_SUCCESS) {
        std::wcout << L"InitSDK failed: " << err << std::endl;
        return false;
    }
    return true;
}
```

### 2. Authenticate with JWT

```cpp
#include <windows.h>
#include <cstdint>
#include <auth_service_interface.h>
#include "AuthServiceEventListener.h"

IAuthService* authService = nullptr;

void OnAuthenticationComplete() {
    std::cout << "Authentication successful!" << std::endl;
    JoinMeeting();  // Proceed to join meeting
}

bool AuthenticateSDK(const std::wstring& jwtToken) {
    CreateAuthService(&authService);
    if (!authService) return false;
    
    // Set event listener BEFORE calling SDKAuth
    authService->SetEvent(new AuthServiceEventListener(&OnAuthenticationComplete));
    
    // Authenticate with JWT
    AuthContext authContext;
    authContext.jwt_token = jwtToken.c_str();
    
    SDKError err = authService->SDKAuth(authContext);
    if (err != SDKERR_SUCCESS) {
        std::wcout << L"SDKAuth failed: " << err << std::endl;
        return false;
    }
    
    // CRITICAL: Add message loop or callback won't fire!
    // See complete example: examples/authentication-pattern.md
    
    return true;
}
```

**AuthServiceEventListener.h:**
```cpp
#include <windows.h>
#include <cstdint>
#include <auth_service_interface.h>
#include <iostream>

using namespace ZOOM_SDK_NAMESPACE;

class AuthServiceEventListener : public IAuthServiceEvent {
public:
    AuthServiceEventListener(void (*onComplete)()) 
        : onAuthComplete(onComplete) {}
    
    void onAuthenticationReturn(AuthResult ret) override {
        if (ret == AUTHRET_SUCCESS && onAuthComplete) {
            onAuthComplete();
        } else {
            std::cout << "Auth failed: " << ret << std::endl;
        }
    }
    
    // Must implement ALL pure virtual methods (6 total)
    void onLoginReturnWithReason(LOGINSTATUS ret, IAccountInfo* info, LoginFailReason reason) override {}
    void onLogout() override {}
    void onZoomIdentityExpired() override {}
    void onZoomAuthIdentityExpired() override {}
#if defined(WIN32)
    void onNotificationServiceStatus(SDKNotificationServiceStatus status, SDKNotificationServiceError error) override {}
#endif

private:
    void (*onAuthComplete)();
};
```

**See complete working code**: [Authentication Pattern Guide](examples/authentication-pattern.md)

### 3. Join Meeting

```cpp
#include <meeting_service_interface.h>
#include "MeetingServiceEventListener.h"

IMeetingService* meetingService = nullptr;

void OnMeetingJoined() {
    std::cout << "Joining meeting..." << std::endl;
}

void OnInMeeting() {
    std::cout << "In meeting now!" << std::endl;
    // Start raw data capture here
}

void OnMeetingEnds() {
    std::cout << "Meeting ended" << std::endl;
}

bool JoinMeeting(UINT64 meetingNumber, const std::wstring& password) {
    CreateMeetingService(&meetingService);
    if (!meetingService) return false;
    
    // Set event listener
    meetingService->SetEvent(
        new MeetingServiceEventListener(&OnMeetingJoined, &OnMeetingEnds, &OnInMeeting)
    );
    
    // Prepare join parameters
    JoinParam joinParam;
    joinParam.userType = SDK_UT_WITHOUT_LOGIN;
    
    JoinParam4WithoutLogin& params = joinParam.param.withoutloginuserJoin;
    params.meetingNumber = meetingNumber;
    params.userName = L"Bot User";
    params.psw = password.c_str();
    params.isVideoOff = false;
    params.isAudioOff = false;
    
    SDKError err = meetingService->Join(joinParam);
    if (err != SDKERR_SUCCESS) {
        std::wcout << L"Join failed: " << err << std::endl;
        return false;
    }
    return true;
}
```

**MeetingServiceEventListener.h:**
```cpp
#include <windows.h>
#include <cstdint>
#include <meeting_service_interface.h>
#include <iostream>

using namespace ZOOM_SDK_NAMESPACE;

class MeetingServiceEventListener : public IMeetingServiceEvent {
public:
    MeetingServiceEventListener(
        void (*onJoined)(),
        void (*onEnded)(), 
        void (*onInMeeting)()
    ) : onMeetingJoined(onJoined), 
        onMeetingEnded(onEnded),
        onInMeetingCallback(onInMeeting) {}
    
    void onMeetingStatusChanged(MeetingStatus status, int iResult) override {
        if (status == MEETING_STATUS_CONNECTING) {
            if (onMeetingJoined) onMeetingJoined();
        }
        else if (status == MEETING_STATUS_INMEETING) {
            if (onInMeetingCallback) onInMeetingCallback();
        }
        else if (status == MEETING_STATUS_ENDED) {
            if (onMeetingEnded) onMeetingEnded();
        }
    }
    
    // Must implement ALL pure virtual methods (9 total)
    void onMeetingStatisticsWarningNotification(StatisticsWarningType type) override {}
    void onMeetingParameterNotification(const MeetingParameter* param) override {}
    void onSuspendParticipantsActivities() override {}
    void onAICompanionActiveChangeNotice(bool isActive) override {}
    void onMeetingTopicChanged(const zchar_t* sTopic) override {}
    void onMeetingFullToWatchLiveStream(const zchar_t* sLiveStreamUrl) override {}
    void onUserNetworkStatusChanged(MeetingComponentType type, ConnectionQuality level, unsigned int userId, bool uplink) override {}
#if defined(WIN32)
    void onAppSignalPanelUpdated(IMeetingAppSignalHandler* pHandler) override {}
#endif

private:
    void (*onMeetingJoined)();
    void (*onMeetingEnded)();
    void (*onInMeetingCallback)();
};
```

**See all required methods**: [Interface Methods Guide](references/interface-methods.md)

### 4. Subscribe to Raw Video

```cpp
#include <windows.h>
#include <cstdint>
#include <rawdata/zoom_rawdata_api.h>
#include <rawdata/rawdata_renderer_interface.h>
#include <zoom_sdk_raw_data_def.h>  // REQUIRED for YUVRawDataI420
#include "ZoomSDKRendererDelegate.h"

IZoomSDKRenderer* videoHelper = nullptr;
ZoomSDKRendererDelegate* videoSource = new ZoomSDKRendererDelegate();

bool StartVideoCapture(uint32_t userId) {
    // STEP 1: Start raw recording FIRST (required!)
    IMeetingRecordingController* recordCtrl = 
        meetingService->GetMeetingRecordingController();
    
    SDKError canStart = recordCtrl->CanStartRawRecording();
    if (canStart != SDKERR_SUCCESS) {
        std::cout << "Cannot start recording: " << canStart << std::endl;
        return false;
    }
    
    recordCtrl->StartRawRecording();
    
    // Wait for recording to initialize
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // STEP 2: Create renderer
    SDKError err = createRenderer(&videoHelper, videoSource);
    if (err != SDKERR_SUCCESS || !videoHelper) {
        std::cout << "createRenderer failed: " << err << std::endl;
        return false;
    }
    
    // STEP 3: Set resolution and subscribe
    videoHelper->setRawDataResolution(ZoomSDKResolution_720P);
    err = videoHelper->subscribe(userId, RAW_DATA_TYPE_VIDEO);
    if (err != SDKERR_SUCCESS) {
        std::cout << "Subscribe failed: " << err << std::endl;
        return false;
    }
    
    std::cout << "Video capture started! Frames arrive in onRawDataFrameReceived()" << std::endl;
    return true;
}
```

**ZoomSDKRendererDelegate.h:**
```cpp
#include <windows.h>
#include <cstdint>
#include <rawdata/rawdata_renderer_interface.h>
#include <zoom_sdk_raw_data_def.h>
#include <fstream>
#include <iostream>

using namespace ZOOM_SDK_NAMESPACE;

class ZoomSDKRendererDelegate : public IZoomSDKRendererDelegate {
public:
    void onRawDataFrameReceived(YUVRawDataI420* data) override {
        if (!data) return;
        
        // YUV420 (I420) format: Y plane + U plane + V plane
        int width = data->GetStreamWidth();
        int height = data->GetStreamHeight();
        
        // Calculate buffer sizes
        // Y = full resolution, U/V = quarter resolution each
        size_t ySize = width * height;
        size_t uvSize = ySize / 4;  // (width/2) * (height/2)
        
        // Total size: width * height * 1.5 bytes
        
        // Save to file (playback: ffplay -f rawvideo -pixel_format yuv420p -video_size 1280x720 output.yuv)
        std::ofstream outputFile("output.yuv", std::ios::binary | std::ios::app);
        outputFile.write(data->GetYBuffer(), ySize);    // Brightness
        outputFile.write(data->GetUBuffer(), uvSize);   // Blue-difference
        outputFile.write(data->GetVBuffer(), uvSize);   // Red-difference
        outputFile.close();
    }
    
    void onRawDataStatusChanged(RawDataStatus status) override {
        std::cout << "Raw data status: " << status << std::endl;
    }
    
    void onRendererBeDestroyed() override {
        std::cout << "Renderer destroyed" << std::endl;
    }
};
```

**Complete video capture guide**: [Raw Video Capture Guide](examples/raw-video-capture.md)

### 5. Subscribe to Raw Audio

```cpp
#include <rawdata/rawdata_audio_helper_interface.h>

class ZoomSDKAudioRawDataDelegate : public IZoomSDKAudioRawDataDelegate {
public:
    void onMixedAudioRawDataReceived(AudioRawData* data) override {
        // Process PCM audio (mixed from all participants)
        std::ofstream pcmFile("audio.pcm", std::ios::binary | std::ios::app);
        pcmFile.write((char*)data->GetBuffer(), data->GetBufferLen());
        pcmFile.close();
    }
    
    void onOneWayAudioRawDataReceived(AudioRawData* data, uint32_t node_id) override {
        // Process audio from specific participant
    }
};

// Subscribe to audio
IZoomSDKAudioRawDataHelper* audioHelper = GetAudioRawdataHelper();
audioHelper->subscribe(new ZoomSDKAudioRawDataDelegate());
```

### 6. Main Message Loop (CRITICAL!)

**⚠️ WITHOUT THIS, CALLBACKS WON'T FIRE!**

```cpp
#include <windows.h>
#include <thread>
#include <chrono>

int main() {
    // Initialize COM
    CoInitialize(NULL);
    
    // Load config and initialize
    LoadConfig();
    InitMeetingSDK();
    AuthenticateSDK(sdk_jwt);
    
    // CRITICAL: Windows message loop for SDK callbacks
    // SDK uses Windows message pump to dispatch callbacks
    // Without this, callbacks are queued but NEVER fire!
    MSG msg;
    while (!g_exit) {
        // Process all pending Windows messages
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) {
                g_exit = true;
                break;
            }
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        
        // Small sleep to avoid busy-waiting
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // Cleanup
    CleanSDK();
    CoUninitialize();
    
    return 0;
}
```

**Why message loop is critical**: The SDK uses Windows COM/messaging for async callbacks. Without `PeekMessage()`, the SDK queues messages but they're never retrieved/dispatched, so callbacks never execute.

**Symptoms without message loop**:
- Authentication timeout (even with valid JWT)
- Meeting join timeout
- No callback events fire
- Appears like network/auth issue but it's a message loop issue

**See detailed explanation**: [Windows Message Loop Guide](troubleshooting/windows-message-loop.md)

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Callbacks don't fire / Auth timeout** | Add Windows message loop → [Guide](troubleshooting/windows-message-loop.md) |
| **`uint32_t` / `AudioType` errors** | Fix include order → [Guide](troubleshooting/build-errors.md) |
| **Abstract class error** | Implement all virtual methods → [Guide](references/interface-methods.md) |
| **How to implement [feature]?** | Follow universal pattern → [Guide](concepts/sdk-architecture-pattern.md) |
| **Authentication fails** | Check JWT token & error codes → [Guide](troubleshooting/common-issues.md) |
| **No video frames received** | Call StartRawRecording() first → [Guide](examples/raw-video-capture.md) |

**Complete troubleshooting**: [Common Issues Guide](troubleshooting/common-issues.md)

## How to Implement Any Feature

The SDK has **35+ feature controllers** (audio, video, chat, recording, participants, screen sharing, breakout rooms, webinars, Q&A, polling, whiteboard, captions, AI companion, etc.).

**Universal pattern that works for ALL features:**

1. **Get the controller** (singleton):
   ```cpp
   IMeetingAudioController* audioCtrl = meetingService->GetMeetingAudioController();
   IMeetingChatController* chatCtrl = meetingService->GetMeetingChatController();
   // ... 33 more controllers available
   ```

2. **Implement event listener** (observer pattern):
   ```cpp
   class MyAudioListener : public IMeetingAudioCtrlEvent {
       void onUserAudioStatusChange(IList<IUserAudioStatus*>* lst) override {
           // React to audio events
       }
       // ... implement all required methods
   };
   ```

3. **Register and use**:
   ```cpp
   audioCtrl->SetEvent(new MyAudioListener());
   audioCtrl->MuteAudio(userId, true);  // Use feature
   ```

**Complete guide with examples**: [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

## Available Examples

| Example | Description |
|---------|-------------|
| **SkeletonDemo** | Minimal join meeting - start here |
| **GetVideoRawData** | Subscribe to raw video streams |
| **GetAudioRawData** | Subscribe to raw audio streams |
| **SendVideoRawData** | Send custom video as virtual camera |
| **SendAudioRawData** | Send custom audio as virtual mic |
| **GetShareRawData** | Capture screen share content |
| **LocalRecording** | Local MP4 recording |
| **ChatDemo** | In-meeting chat functionality |
| **CaptionDemo** | Closed caption/live transcription |
| **BreakoutDemo** | Breakout room management |

## Detailed References

### 🎯 Core Concepts (START HERE!)
- **[concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)** - **Universal pattern for implementing ANY feature** - Understanding this unlocks the entire SDK!

### 📚 Complete Examples
- **[examples/authentication-pattern.md](examples/authentication-pattern.md)** - Complete working authentication with JWT tokens
- **[examples/raw-video-capture.md](examples/raw-video-capture.md)** - YUV420 video capture with detailed format explanation

### 🔧 Troubleshooting Guides
- **[troubleshooting/windows-message-loop.md](troubleshooting/windows-message-loop.md)** - **Why callbacks don't fire** (MOST CRITICAL!)
- **[troubleshooting/build-errors.md](troubleshooting/build-errors.md)** - SDK header dependency issues and fixes
- **[troubleshooting/common-issues.md](troubleshooting/common-issues.md)** - Quick diagnostic workflow and error code tables

### 📖 References
- **[references/interface-methods.md](references/interface-methods.md)** - How to implement ALL required virtual methods
- **[references/windows-reference.md](references/windows-reference.md)** - Dependencies, Visual Studio setup
- **[../references/authorization.md](../references/authorization.md)** - SDK JWT generation
- **[../references/bot-authentication.md](../references/bot-authentication.md)** - Bot token types (ZAK, OBF, JWT)

### 🎨 Feature-Specific Guides
- **[../references/breakout-rooms.md](../references/breakout-rooms.md)** - Programmatic breakout room management
- **[../references/ai-companion.md](../references/ai-companion.md)** - AI Companion controls

## Sample Repositories

| Repository | Description |
|------------|-------------|
| [meetingsdk-windows-raw-recording-sample](https://github.com/zoom/meetingsdk-windows-raw-recording-sample) | Official raw data capture samples |
| [meetingsdk-windows-local-recording-sample](https://github.com/zoom/meetingsdk-windows-local-recording-container-sample) | Local recording with Docker |

## Playing Raw Video/Audio Files

Raw YUV/PCM files have no headers - you must specify format explicitly.

### Play Raw YUV Video
```cmd
ffplay -video_size 1280x720 -pixel_format yuv420p -f rawvideo output.yuv
```

### Convert YUV to MP4
```cmd
ffmpeg -video_size 1280x720 -pixel_format yuv420p -f rawvideo -i output.yuv -c:v libx264 output.mp4
```

### Play Raw PCM Audio
```cmd
ffplay -f s16le -ar 32000 -ac 1 audio.pcm
```

### Convert PCM to WAV
```cmd
ffmpeg -f s16le -ar 32000 -ac 1 -i audio.pcm output.wav
```

### Combine Video + Audio
```cmd
ffmpeg -video_size 1280x720 -pixel_format yuv420p -f rawvideo -i output.yuv ^
       -f s16le -ar 32000 -ac 1 -i audio.pcm ^
       -c:v libx264 -c:a aac -shortest output.mp4
```

**Key flags:**
| Flag | Description |
|------|-------------|
| `-video_size WxH` | Frame dimensions (e.g., 1280x720) |
| `-pixel_format yuv420p` | I420/YUV420 planar format |
| `-f rawvideo` | Raw video input (no container) |
| `-f s16le` | Signed 16-bit little-endian PCM |
| `-ar 32000` | Sample rate (Zoom uses 32kHz) |
| `-ac 1` | Mono (use `-ac 2` for stereo) |

## Authentication Requirements (2026 Update)

> **Important**: Beginning **March 2, 2026**, apps joining meetings outside their account must be authorized.

Use one of:
- **App Privilege Token (OBF)** - Recommended for bots (`app_privilege_token` in JoinParam)
- **ZAK Token** - Zoom Access Key (`userZAK` in JoinParam)
- **On Behalf Token** - For specific use cases (`onBehalfToken` in JoinParam)

## 📖 Complete Documentation Library

This skill includes comprehensive guides created from real-world debugging:

### 🎯 Start Here
- **[SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)** - Master document: Universal pattern for ANY feature
- **[SKILL.md](SKILL.md)** - Complete navigation guide

### 📚 By Category

**Core Concepts:**
- [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - How every feature works (singleton + observer pattern)

**Complete Examples:**
- [Authentication Pattern](examples/authentication-pattern.md) - Working JWT auth with all code
- [Raw Video Capture](examples/raw-video-capture.md) - YUV420 video capture explained

**Troubleshooting:**
- [Windows Message Loop](troubleshooting/windows-message-loop.md) - **CRITICAL**: Why callbacks don't fire
- [Build Errors](troubleshooting/build-errors.md) - SDK header dependency fixes
- [Common Issues](troubleshooting/common-issues.md) - Quick diagnostics & error codes

**References:**
- [Interface Methods](references/interface-methods.md) - All required virtual methods (6 auth + 9 meeting)
- [Windows Reference](references/windows-reference.md) - Platform setup
- [Authorization](../references/authorization.md) - JWT generation
- [Bot Authentication](../references/bot-authentication.md) - Bot token types
- [Breakout Rooms](../references/breakout-rooms.md) - Breakout room API
- [AI Companion](../references/ai-companion.md) - AI features

### 🚨 Most Critical Issues (From Real Debugging)

1. **Callbacks not firing** → Missing Windows message loop (99% of issues)
   - See: [Windows Message Loop Guide](troubleshooting/windows-message-loop.md)

2. **Build errors** → SDK header dependencies (`uint32_t`, `AudioType`, etc.)
   - See: [Build Errors Guide](troubleshooting/build-errors.md)

3. **Abstract class errors** → Missing virtual method implementations
   - See: [Interface Methods Guide](references/interface-methods.md)

### 💡 Key Insight

**Once you learn the 3-step pattern, you can implement ANY of the 35+ features:**
1. Get controller → 2. Implement event listener → 3. Register and use

See: [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

## Official Resources

- **Official docs**: https://developers.zoom.us/docs/meeting-sdk/windows/
- **API Reference**: https://marketplacefront.zoom.us/sdk/meeting/windows/annotated.html
- **Developer forum**: https://devforum.zoom.us/
- **SDK download**: https://marketplace.zoom.us/

---

**Documentation Version**: Based on Zoom Windows Meeting SDK v6.7.2.26830

**Need help?** Start with [SKILL.md](SKILL.md) for complete navigation.


## Merged from meeting-sdk/windows/SKILL.md

# Zoom Windows Meeting SDK - Complete Documentation Index

## 🚀 Quick Start Path

**If you're new to the SDK, follow this order:**

1. **Read the architecture pattern** → [concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)
   - This teaches you the universal formula that applies to ALL features
   - Once you understand this, you can implement any feature by reading the `.h` files

2. **Fix build errors** → [troubleshooting/build-errors.md](troubleshooting/build-errors.md)
   - SDK header dependencies issues
   - Required include order

3. **Implement authentication** → [examples/authentication-pattern.md](examples/authentication-pattern.md)
   - Complete working JWT authentication code

4. **Fix callback issues** → [troubleshooting/windows-message-loop.md](troubleshooting/windows-message-loop.md)
   - **CRITICAL**: Why callbacks don't fire without Windows message loop
   - This was the hardest issue to diagnose!

5. **Implement virtual methods** → [references/interface-methods.md](references/interface-methods.md)
   - Complete lists of all required methods
   - How to avoid abstract class errors

6. **Capture video (optional)** → [examples/raw-video-capture.md](examples/raw-video-capture.md)
   - YUV420 format explained
   - Complete raw data capture workflow

7. **Troubleshoot any issues** → [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
   - Quick diagnostic checklist
   - Error code tables
   - "If you see X, do Y" reference

---

## 📂 Documentation Structure

```
meeting-sdk/windows/
├── SKILL.md                           # Main skill overview
├── SKILL.md                           # This file - navigation guide
│
├── concepts/                          # Core architectural patterns
│   ├── sdk-architecture-pattern.md   # THE MOST IMPORTANT DOC
│   │                                  # Universal formula for ANY feature
│   ├── singleton-hierarchy.md        # Navigation guide for SDK services
│   │                                  # 4-level deep service tree, when/how
│   ├── custom-ui-architecture.md     # How Custom UI rendering works
│   │                                  # Child HWNDs, D3D, layout, events
│   └── custom-ui-vs-raw-data.md      # SDK-rendered vs self-rendered
│                                      # Decision guide for Custom UI approach
│
├── examples/                          # Complete working code
│   ├── authentication-pattern.md     # JWT auth with full code
│   ├── raw-video-capture.md          # Video capture with YUV420 details
│   │                                  # Recording vs Streaming, permissions
│   ├── custom-ui-video-rendering.md  # Custom UI with video container
│   │                                  # Active speaker + gallery layout
│   ├── breakout-rooms.md             # Complete breakout room guide
│   │                                  # 5 roles, create/manage/join
│   ├── chat.md                       # Send/receive chat messages
│   │                                  # Rich text, threading, file transfer
│   ├── captions-transcription.md     # Live transcription & closed captions
│   │                                  # Multi-language translation
│   ├── local-recording.md            # Local MP4 recording
│   │                                  # Permission flow, encoder monitoring
│   ├── share-raw-data-capture.md     # Screen share raw data capture
│   │                                  # YUV420 frames from shared content
│   └── send-raw-data.md              # Virtual camera/mic/share
│                                      # Send custom video/audio/share
│
├── troubleshooting/                   # Problem solving guides
│   ├── windows-message-loop.md       # CRITICAL - Why callbacks fail
│   ├── build-errors.md               # Header dependency fixes + MSBuild
│   └── common-issues.md              # Quick diagnostic workflow
│
└── references/                        # Reference documentation
    ├── interface-methods.md           # Required virtual methods
    │                                  # Auth(6) + Meeting(9) + CustomUI(13)
    ├── windows-reference.md           # Platform setup
    ├── authorization.md               # JWT generation
    ├── bot-authentication.md          # Bot token types
    ├── breakout-rooms.md              # Breakout room features
    └── ai-companion.md                # AI Companion features
```

---

## 🎯 By Use Case

### I want to build a meeting bot
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Understand the pattern
2. [Authentication Pattern](examples/authentication-pattern.md) - Join meetings
3. [Windows Message Loop](troubleshooting/windows-message-loop.md) - Fix callback issues
4. [Interface Methods](references/interface-methods.md) - Implement callbacks

### I'm getting build errors
1. [Build Errors Guide](troubleshooting/build-errors.md) - SDK header dependencies
2. [Interface Methods](references/interface-methods.md) - Abstract class errors
3. [Common Issues](troubleshooting/common-issues.md) - Linker errors

### I'm getting runtime errors
1. [Windows Message Loop](troubleshooting/windows-message-loop.md) - Callbacks not firing
2. [Authentication Pattern](examples/authentication-pattern.md) - Auth timeout
3. [Common Issues](troubleshooting/common-issues.md) - Error code tables

### I want to build a Custom UI meeting app
1. [Custom UI Architecture](concepts/custom-ui-architecture.md) - How SDK rendering works
2. [SDK-Rendered vs Self-Rendered](concepts/custom-ui-vs-raw-data.md) - Choose your approach
3. [Custom UI Video Rendering](examples/custom-ui-video-rendering.md) - Complete working code
4. [Interface Methods](references/interface-methods.md) - 13 Custom UI virtual methods
5. [Build Errors Guide](troubleshooting/build-errors.md) - MSBuild from git bash

### I want to capture video/audio
1. [Raw Video Capture](examples/raw-video-capture.md) - Complete video workflow
   - Recording vs Streaming approaches
   - Permission requirements (host, OAuth tokens)
   - Audio PCM capture
2. [Share Raw Data Capture](examples/share-raw-data-capture.md) - Screen share capture
   - Subscribe to RAW_DATA_TYPE_SHARE
   - Handle dynamic resolution
3. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Controller pattern
4. [Common Issues](troubleshooting/common-issues.md) - No frames received

### I want to use breakout rooms
1. [Breakout Rooms Guide](examples/breakout-rooms.md) - Complete breakout room workflow
   - 5 roles: Creator, Admin, Data, Assistant, Attendee
   - Create, configure, manage, join/leave rooms
2. [Common Issues](troubleshooting/common-issues.md) - Breakout room error codes

### I want to implement chat
1. [Chat Guide](examples/chat.md) - Send/receive messages
   - Rich text formatting (bold, italic, links)
   - Private messages and threading
   - File transfer events

### I want to use live transcription
1. [Captions & Transcription Guide](examples/captions-transcription.md) - Live transcription
   - Automatic speech-to-text
   - Multi-language translation
   - Manual closed captions (host feature)

### I want to record meetings
1. [Local Recording Guide](examples/local-recording.md) - Local MP4 recording
   - Permission request workflow
   - zTscoder.exe encoder monitoring
   - Gallery view vs active speaker

### I want to implement a specific feature
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - **START HERE!**
2. Find the controller in `SDK/x64/h/meeting_service_interface.h`
3. Find the header in `SDK/x64/h/meeting_service_components/`
4. Follow the universal pattern: Get controller → Implement listener → Use methods

### I want to understand the SDK architecture
1. [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Complete architecture overview
2. [Singleton Hierarchy](concepts/singleton-hierarchy.md) - Navigate the service tree (4 levels)
3. [Interface Methods](references/interface-methods.md) - Event listener pattern
4. [Authentication Pattern](examples/authentication-pattern.md) - Service pattern

---

## 🔥 Most Critical Documents

### 1. SDK Architecture Pattern (⭐ MASTER DOCUMENT)
**[concepts/sdk-architecture-pattern.md](concepts/sdk-architecture-pattern.md)**

This is THE most important document. It teaches the universal 3-step pattern:
1. Get controller (singleton pattern)
2. Implement event listener (observer pattern)
3. Register and use

Once you understand this pattern, you can implement **any of the 35+ features** by just reading the SDK headers.

**Key insight**: The Zoom SDK follows a perfectly consistent architecture. Every feature works the same way.

---

### 2. Windows Message Loop (⚠️ MOST COMMON ISSUE)
**[troubleshooting/windows-message-loop.md](troubleshooting/windows-message-loop.md)**

99% of "callbacks not firing" issues are caused by missing Windows message loop. This document explains:
- Why SDK requires `PeekMessage()` loop
- How to implement it correctly
- How to diagnose callback issues

**This was the hardest bug to find during development** (took ~2 hours).

---

### 3. Build Errors Guide
**[troubleshooting/build-errors.md](troubleshooting/build-errors.md)**

SDK headers have dependency bugs that cause build errors. This document provides:
- Required include order
- Missing `<cstdint>` fix
- Missing `AudioType` fix
- Missing `YUVRawDataI420` fix

---

## 📊 By Document Type

### Concepts (Why and How)
- [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - Universal implementation pattern
- [Singleton Hierarchy](concepts/singleton-hierarchy.md) - Navigation guide for SDK services (4 levels deep)

### Examples (Complete Working Code)
- [Authentication Pattern](examples/authentication-pattern.md) - JWT authentication
- [Raw Video Capture](examples/raw-video-capture.md) - Video capture with YUV420, recording vs streaming
- [Custom UI Video Rendering](examples/custom-ui-video-rendering.md) - SDK-rendered video containers
- [Breakout Rooms](examples/breakout-rooms.md) - Create, manage, join breakout rooms
- [Chat](examples/chat.md) - Send/receive messages with rich formatting
- [Captions & Transcription](examples/captions-transcription.md) - Live transcription and closed captions
- [Local Recording](examples/local-recording.md) - Local MP4 recording with permission flow
- [Share Raw Data Capture](examples/share-raw-data-capture.md) - Screen share raw data capture
- [Send Raw Data](examples/send-raw-data.md) - Virtual camera, microphone, and share

### Troubleshooting (Problem Solving)
- [Windows Message Loop](troubleshooting/windows-message-loop.md) - Callback issues
- [Build Errors](troubleshooting/build-errors.md) - Compilation issues
- [Common Issues](troubleshooting/common-issues.md) - Quick diagnostics

### References (Lookup Information)
- [Interface Methods](references/interface-methods.md) - Required virtual methods
- [Windows Reference](references/windows-reference.md) - Platform setup
- [Authorization](../references/authorization.md) - JWT generation
- [Bot Authentication](../references/bot-authentication.md) - Bot tokens
- [Breakout Rooms](../references/breakout-rooms.md) - Breakout room API
- [AI Companion](../references/ai-companion.md) - AI features

---

## 💡 Key Learnings from Real Debugging

These documents were created from actual debugging of a non-functional Zoom SDK sample. Here are the key insights:

### Critical Discoveries:

1. **Windows Message Loop is MANDATORY** (not optional)
   - SDK uses Windows message pump for callbacks
   - Without it, callbacks are queued but never fire
   - Manifests as "authentication timeout" even with valid JWT
   - See: [Windows Message Loop Guide](troubleshooting/windows-message-loop.md)

2. **SDK Headers Have Dependency Bugs**
   - Missing `#include <cstdint>` in SDK headers
   - `meeting_participants_ctrl_interface.h` doesn't include `meeting_audio_interface.h`
   - `rawdata_renderer_interface.h` only forward-declares `YUVRawDataI420`
   - See: [Build Errors Guide](troubleshooting/build-errors.md)

3. **Include Order is CRITICAL**
   - `<windows.h>` must be FIRST
   - `<cstdint>` must be SECOND
   - Then SDK headers in specific order
   - See: [Build Errors Guide](troubleshooting/build-errors.md)

4. **ALL Virtual Methods Must Be Implemented**
   - Including WIN32-conditional methods
   - SDK v6.7.2 requires 6 auth methods + 9 meeting methods
   - Different versions have different requirements
   - See: [Interface Methods Guide](references/interface-methods.md)

5. **The Architecture is Beautifully Consistent**
   - Every feature follows the same 3-step pattern
   - Controllers are singletons
   - Event listeners use observer pattern
   - Once you learn the pattern, you can implement any feature
   - See: [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

---

## 🎓 Learning Path by Skill Level

### Beginner (Never used Zoom SDK)
1. Read [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) to understand the overall design
2. Follow [Authentication Pattern](examples/authentication-pattern.md) to join your first meeting
3. Reference [Common Issues](troubleshooting/common-issues.md) when you hit problems

### Intermediate (Familiar with SDK basics)
1. Deep dive into [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - implement multiple features
2. Learn [Raw Video Capture](examples/raw-video-capture.md) for media processing
3. Use [Interface Methods](references/interface-methods.md) as reference

### Advanced (Building production bots)
1. Study [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) - learn to implement ANY feature
2. Master [Windows Message Loop](troubleshooting/windows-message-loop.md) - understand async callback flow
3. Reference SDK headers directly using the universal pattern

---

## 🔍 How to Find What You Need

### "My code won't compile"
→ [Build Errors Guide](troubleshooting/build-errors.md)

### "Authentication times out"
→ [Windows Message Loop](troubleshooting/windows-message-loop.md)

### "Callbacks never fire"
→ [Windows Message Loop](troubleshooting/windows-message-loop.md)

### "Abstract class error"
→ [Interface Methods](references/interface-methods.md)

### "How do I implement [feature]?"
→ [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

### "How do I join a meeting?"
→ [Authentication Pattern](examples/authentication-pattern.md)

### "How do I capture video?"
→ [Raw Video Capture](examples/raw-video-capture.md)

### "What error code means what?"
→ [Common Issues](troubleshooting/common-issues.md) - Comprehensive error code tables (SDKERR, AUTHRET, Login, BO, Phone, OBF)

### "How do I use breakout rooms?"
→ [Breakout Rooms Guide](examples/breakout-rooms.md)

### "How does the SDK work?"
→ [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md)

### "How do I navigate to a specific controller/feature?"
→ [Singleton Hierarchy](concepts/singleton-hierarchy.md)

### "How do I send/receive chat messages?"
→ [Chat Guide](examples/chat.md)

### "How do I use live transcription?"
→ [Captions & Transcription Guide](examples/captions-transcription.md)

### "How do I record locally?"
→ [Local Recording Guide](examples/local-recording.md)

### "How do I capture screen share?"
→ [Share Raw Data Capture](examples/share-raw-data-capture.md)

---

## 📝 Document Version

All documents are based on **Zoom Windows Meeting SDK v6.7.2.26830**.

Different SDK versions may have:
- Different required callback methods
- Different error codes
- Different API behavior

If using a different version, use `grep "= 0" SDK/x64/h/*.h` to verify required methods.

---

Remember: The [SDK Architecture Pattern](concepts/sdk-architecture-pattern.md) is the fastest way to understand how the Windows Meeting SDK fits together. Read it first if you are debugging custom UI or event flow issues.

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/oauth', 'business', 'oauth', '', 'oauth', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom OAuth

Background reference for Zoom auth and token lifecycle behavior. Prefer `setup-zoom-oauth` first, then use this skill for the exact flow, scope, and error details.

# Zoom OAuth

Authentication and authorization for Zoom APIs.

## 📖 Complete Documentation

For comprehensive guides, production patterns, and troubleshooting, see **Integrated Index section below**.

Quick navigation:
- **[5-Minute Runbook](RUNBOOK.md)** - Preflight checks before deep debugging
- **[OAuth Flows](concepts/oauth-flows.md)** - Which flow to use and how each works
- **[Token Lifecycle](concepts/token-lifecycle.md)** - Expiration, refresh, and revocation
- **[Production Examples](examples/s2s-oauth-redis.md)** - Redis caching, MySQL storage, auto-refresh
- **[Troubleshooting](troubleshooting/common-errors.md)** - Error codes 4700-4741

## Prerequisites

- Zoom app created in [Marketplace](https://marketplace.zoom.us/)
- Client ID and Client Secret
- For S2S OAuth: Account ID

## Four Authorization Use Cases

| Use Case | App Type | Grant Type | Industry Name |
|----------|----------|------------|---------------|
| **Account Authorization** | Server-to-Server | `account_credentials` | Client Credentials Grant, M2M, Two-legged OAuth |
| **User Authorization** | General | `authorization_code` | Authorization Code Grant, Three-legged OAuth |
| **Device Authorization** | General | `urn:ietf:params:oauth:grant-type:device_code` | Device Authorization Grant (RFC 8628) |
| **Client Authorization** | General | `client_credentials` | Client Credentials Grant (chatbot-scoped) |

### Industry Terminology

| Term | Meaning |
|------|---------|
| **Two-legged OAuth** | No user involved (client ↔ server) |
| **Three-legged OAuth** | User involved (user ↔ client ↔ server) |
| **M2M** | Machine-to-Machine (backend services) |
| **Public client** | Can't keep secrets (mobile, SPA) → use PKCE |
| **Confidential client** | Can keep secrets (backend servers) |
| **PKCE** | Proof Key for Code Exchange (RFC 7636), pronounced "pixy" |

### Which Flow Should I Use?

```
                              ┌─────────────────────┐
                              │  What are you       │
                              │  building?          │
                              └──────────┬──────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
          ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
          │  Backend        │  │  App for other  │  │  Chatbot only   │
          │  automation     │  │  users/accounts │  │  (Team Chat)    │
          │  (your account) │  │                 │  │                 │
          └────────┬────────┘  └────────┬────────┘  └────────┬────────┘
                   │                    │                    │
                   ▼                    │                    ▼
          ┌─────────────────┐           │           ┌─────────────────┐
          │    ACCOUNT      │           │           │     CLIENT      │
          │   (S2S OAuth)   │           │           │   (Chatbot)     │
          └─────────────────┘           │           └─────────────────┘
                                        │
                                        ▼
                              ┌─────────────────────┐
                              │  Does device have   │
                              │  a browser?         │
                              └──────────┬──────────┘
                                         │
                         ┌───────────────┴───────────────┐
                         │ NO                         YES│
                         ▼                               ▼
          ┌─────────────────────────┐         ┌─────────────────┐
          │        DEVICE           │         │      USER       │
          │     (Device Flow)       │         │  (Auth Code)    │
          │                         │         │                 │
          │ Examples:               │         │ + PKCE if       │
          │ • Smart TV              │         │   public client │
          │ • Meeting SDK device    │         │                 │
          └─────────────────────────┘         └─────────────────┘
```

---

## Account Authorization (Server-to-Server OAuth)

For backend automation without user interaction.

### Request Access Token

```bash
POST https://zoom.us/oauth/token?grant_type=account_credentials&account_id={ACCOUNT_ID}

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

### Response

```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "user:read:user:admin",
  "api_url": "https://api.zoom.us"
}
```

### Refresh

Access tokens expire after **1 hour**. No separate refresh flow - just request a new token.

---

## User Authorization (Authorization Code Flow)

For apps that act on behalf of users.

### Step 1: Redirect User to Authorize

```
https://zoom.us/oauth/authorize?response_type=code&client_id={CLIENT_ID}&redirect_uri={REDIRECT_URI}
```

Use `https://zoom.us/oauth/authorize` for consent, but `https://zoom.us/oauth/token` for token exchange.

**Optional Parameters:**

| Parameter | Description |
|-----------|-------------|
| `state` | CSRF protection, maintains state through flow |
| `code_challenge` | For PKCE (see below) |
| `code_challenge_method` | `S256` or `plain` (default: plain) |

### Step 2: User Authorizes

- User signs in and grants permission
- Redirects to `redirect_uri` with authorization code:
  ```
  https://example.com/?code={AUTHORIZATION_CODE}
  ```

### Step 3: Exchange Code for Token

```bash
POST https://zoom.us/oauth/token?grant_type=authorization_code&code={CODE}&redirect_uri={REDIRECT_URI}

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

**With PKCE:** Add `code_verifier` parameter.

### Response

```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "refresh_token": "eyJ...",
  "expires_in": 3600,
  "scope": "user:read:user",
  "api_url": "https://api.zoom.us"
}
```

### Refresh Token

```bash
POST https://zoom.us/oauth/token?grant_type=refresh_token&refresh_token={REFRESH_TOKEN}

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

- Access tokens expire after **1 hour**
- Refresh token lifetime can vary; ~90 days is common for some user-based flows. Treat it as configuration/behavior that can change and rely on runtime errors + re-auth fallback.
- Always use the latest refresh token for the next request
- If refresh token expires, redirect user to authorization URL to restart flow

### User-Level vs Account-Level Apps

| Type | Who Can Authorize | Scope Access |
|------|-------------------|--------------|
| **User-level** | Any individual user | Scoped to themselves |
| **Account-level** | User with admin permissions | Account-wide access (admin scopes) |

---

## Device Authorization (Device Flow)

For devices without browsers (e.g., Meeting SDK apps).

### Prerequisites

Enable "Use App on Device" in: Features > Embed > Enable Meeting SDK

### Step 1: Request Device Code

```bash
POST https://zoom.us/oauth/devicecode?client_id={CLIENT_ID}

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

### Response

```json
{
  "device_code": "DEVICE_CODE",
  "user_code": "abcd1234",
  "verification_uri": "https://zoom.us/oauth_device",
  "verification_uri_complete": "https://zoom.us/oauth/device/complete/{CODE}",
  "expires_in": 900,
  "interval": 5
}
```

### Step 2: User Authorization

Direct user to:
- `verification_uri` and display `user_code` for manual entry, OR
- `verification_uri_complete` (user code prefilled)

User signs in and allows the app.

### Step 3: Poll for Token

Poll at the `interval` (5 seconds) until user authorizes:

```bash
POST https://zoom.us/oauth/token?grant_type=urn:ietf:params:oauth:grant-type:device_code&device_code={DEVICE_CODE}

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

### Response

```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "refresh_token": "eyJ...",
  "expires_in": 3599,
  "scope": "user:read:user user:read:token",
  "api_url": "https://api.zoom.us"
}
```

### Polling Responses

| Response | Meaning | Action |
|----------|---------|--------|
| Token returned | User authorized | Store tokens, done |
| `error: authorization_pending` | User hasn't authorized yet | Keep polling at interval |
| `error: slow_down` | Polling too fast | Increase interval by 5 seconds |
| `error: expired_token` | Device code expired (15 min) | Restart flow from Step 1 |
| `error: access_denied` | User denied authorization | Handle denial, don't retry |

### Polling Implementation

```javascript
async function pollForToken(deviceCode, interval) {
  while (true) {
    await sleep(interval * 1000);
    
    try {
      const response = await axios.post(
        `https://zoom.us/oauth/token?grant_type=urn:ietf:params:oauth:grant-type:device_code&device_code=${deviceCode}`,
        null,
        { headers: { 'Authorization': `Basic ${credentials}` } }
      );
      return response.data; // Success - got tokens
    } catch (error) {
      const err = error.response?.data?.error;
      if (err === 'authorization_pending') continue;
      if (err === 'slow_down') { interval += 5; continue; }
      throw error; // expired_token or access_denied
    }
  }
}
```

### Refresh

Same as User Authorization. If refresh token expires, restart device flow from Step 1.

---

## Client Authorization (Chatbot)

For chatbot message operations only.

### Request Token

```bash
POST https://zoom.us/oauth/token?grant_type=client_credentials

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

### Response

```json
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "imchat:bot",
  "api_url": "https://api.zoom.us"
}
```

### Refresh

Tokens expire after **1 hour**. No refresh flow - just request a new token.

---

## Using Access Tokens

### Call API

```bash
GET https://api.zoom.us/v2/users/me

Headers:
Authorization: Bearer {ACCESS_TOKEN}
```

### Me Context

Replace `userID` with `me` to target the token's associated user:

| Endpoint | Methods |
|----------|---------|
| `/v2/users/me` | GET, PATCH |
| `/v2/users/me/token` | GET |
| `/v2/users/me/meetings` | GET, POST |

---

## Revoke Access Token

Works for all authorization types.

```bash
POST https://zoom.us/oauth/revoke?token={ACCESS_TOKEN}

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

### Response

```json
{
  "status": "success"
}
```

---

## PKCE (Proof Key for Code Exchange)

For public clients that can't securely store secrets (mobile apps, SPAs, desktop apps).

### When to Use PKCE

| Client Type | Use PKCE? | Why |
|-------------|-----------|-----|
| Mobile app | **Yes** | Can't securely store client secret |
| Single Page App (SPA) | **Yes** | JavaScript is visible to users |
| Desktop app | **Yes** | Binary can be decompiled |
| Meeting SDK (client-side) | **Yes** | Runs on user's device |
| Backend server | Optional | Can keep secrets, but PKCE adds security |

### How PKCE Works

```
┌──────────┐                              ┌──────────┐                    ┌──────────┐
│  Client  │                              │   Zoom   │                    │   Zoom   │
│   App    │                              │  Auth    │                    │  Token   │
└────┬─────┘                              └────┬─────┘                    └────┬─────┘
     │                                         │                              │
     │ 1. Generate code_verifier (random)      │                              │
     │ 2. Create code_challenge = SHA256(verifier)                            │
     │                                         │                              │
     │ ─────── /authorize + code_challenge ──► │                              │
     │                                         │                              │
     │ ◄────── authorization_code ──────────── │                              │
     │                                         │                              │
     │ ─────────────── /token + code_verifier ─┼────────────────────────────► │
     │                                         │                              │
     │                                         │     Verify: SHA256(verifier) │
     │                                         │            == challenge      │
     │                                         │                              │
     │ ◄───────────────────────────────────────┼─────── access_token ──────── │
     │                                         │                              │
```

### Implementation (Node.js)

```javascript
const crypto = require('crypto');

function generatePKCE() {
  const verifier = crypto.randomBytes(32).toString('base64url');
  const challenge = crypto.createHash('sha256').update(verifier).digest('base64url');
  return { verifier, challenge };
}

const pkce = generatePKCE();

const authUrl = `https://zoom.us/oauth/authorize?` +
  `response_type=code&` +
  `client_id=${CLIENT_ID}&` +
  `redirect_uri=${REDIRECT_URI}&` +
  `code_challenge=${pkce.challenge}&` +
  `code_challenge_method=S256`;

// Store pkce.verifier in session for callback
```

### Token Exchange with PKCE

```bash
POST https://zoom.us/oauth/token?grant_type=authorization_code&code={CODE}&redirect_uri={REDIRECT_URI}&code_verifier={VERIFIER}

Headers:
Authorization: Basic {Base64(ClientID:ClientSecret)}
```

---

## Deauthorization

When a user removes your app, Zoom sends a webhook to your Deauthorization Notification Endpoint URL.

### Webhook Event

```json
{
  "event": "app_deauthorized",
  "event_ts": 1740439732278,
  "payload": {
    "account_id": "ACCOUNT_ID",
    "user_id": "USER_ID",
    "signature": "SIGNATURE",
    "deauthorization_time": "2019-06-17T13:52:28.632Z",
    "client_id": "CLIENT_ID"
  }
}
```

### Requirements

- **Delete all associated user data** after receiving this event
- **Verify webhook signature** (use secret token, verification token deprecated Oct 2023)
- Only public apps receive deauthorization webhooks (not private/dev apps)

---

## Pre-Approval Flow

Some Zoom accounts require Marketplace admin pre-approval before users can authorize apps.

- Users can request pre-approval from their admin
- Account-level apps (admin scopes) require appropriate role permissions

---

## Active Apps Notifier (AAN)

In-meeting feature showing apps with real-time access to content.

- Displays icon + tooltip with app info, content type being accessed, approving account
- Supported: Zoom client 5.6.7+, Meeting SDK 5.9.0+

---

## OAuth Scopes

### Scope Types

| Type | Description | For |
|------|-------------|-----|
| **Classic scopes** | Legacy scopes (user, admin, master levels) | Existing apps |
| **Granular scopes** | New fine-grained scopes with optional support | New apps |

### Classic Scopes

For previously-created apps. Three levels:
- **User-level**: Access to individual user's data
- **Admin-level**: Account-wide access, requires admin role
- **Master-level**: For master-sub account setups, requires account owner

Full list: https://developers.zoom.us/docs/integrations/oauth-scopes/

### Granular Scopes

For new apps. Format: `<service>:<action>:<data_claim>:<access>`

| Component | Values |
|-----------|--------|
| **service** | `meeting`, `webinar`, `user`, `recording`, etc. |
| **action** | `read`, `write`, `update`, `delete` |
| **data_claim** | Data category (e.g., `participants`, `settings`) |
| **access** | empty (user), `admin`, `master` |

Example: `meeting:read:list_meetings:admin`

Full list: https://developers.zoom.us/docs/integrations/oauth-scopes-granular/

### Optional Scopes

Granular scopes can be marked as **optional** - users choose whether to grant them.

**Basic authorization** (uses build flow defaults):
```
https://zoom.us/oauth/authorize?response_type=code&client_id={CLIENT_ID}&redirect_uri={REDIRECT_URI}
```

**Advanced authorization** (custom scopes per request):
```
https://zoom.us/oauth/authorize?client_id={CLIENT_ID}&response_type=code&redirect_uri={REDIRECT_URI}&scope={required_scopes}&optional_scope={optional_scopes}
```

**Include previously granted scopes:**
```
https://zoom.us/oauth/authorize?...&include_granted_scopes&scope={additional_scopes}
```

### Migrating Classic to Granular

1. Manage > select app > edit
2. Scope page > Development tab > click **Migrate**
3. Review auto-assigned granular scopes, remove unnecessary, mark optional
4. Test
5. Production tab > click **Migrate**

**Notes:**
- No review needed if only migrating or reducing scopes
- Existing user tokens continue with classic scope values until re-authorization
- New users get granular scopes after migration

---

## Common Error Codes

| Code | Message | Solution |
|------|---------|----------|
| 4700 | Token cannot be empty | Check Authorization header has valid token |
| 4702/4704 | Invalid client | Verify Client ID and Client Secret |
| 4705 | Grant type not supported | Use: `account_credentials`, `authorization_code`, `urn:ietf:params:oauth:grant-type:device_code`, or `client_credentials` |
| 4706 | Client ID or secret missing | Add credentials to header or request params |
| 4709 | Redirect URI mismatch | Ensure redirect_uri matches app configuration exactly (including trailing slash) |
| 4711 | Refresh token invalid | Token scopes don't match client scopes |
| 4717 | App has been disabled | Contact Zoom support |
| 4733 | Code is expired | Authorization codes expire in 5 minutes - restart flow |
| 4734 | Invalid authorization code | Regenerate authorization code |
| 4735 | Owner of token does not exist | User was removed from account - re-authorize |
| 4741 | Token has been revoked | Use the most recent token from latest authorization |

See `references/oauth-errors.md` for complete error list.

---

## Quick Reference

| Flow | Grant Type | Token Expiry | Refresh |
|------|------------|--------------|---------|
| Account (S2S) | `account_credentials` | 1 hour | Request new token |
| User | `authorization_code` | 1 hour | Use refresh_token (90 day expiry) |
| Device | `urn:ietf:params:oauth:grant-type:device_code` | 1 hour | Use refresh_token (90 day expiry) |
| Client (Chatbot) | `client_credentials` | 1 hour | Request new token |

---

## Demo Guidance

If you build an OAuth demo app, document its runtime base URL in that demo project's own
README or `.env.example`, not in this shared skill.

## Resources

- **OAuth docs**: https://developers.zoom.us/docs/integrations/oauth/
- **S2S OAuth docs**: https://developers.zoom.us/docs/internal-apps/s2s-oauth/
- **PKCE blog**: https://developers.zoom.us/blog/pcke-oauth-with-postman-rest-api/
- **Classic scopes**: https://developers.zoom.us/docs/integrations/oauth-scopes/
- **Granular scopes**: https://developers.zoom.us/docs/integrations/oauth-scopes-granular/

---

## Integrated Index

_This section was migrated from `SKILL.md`._

## Quick Start Path

**If you're new to Zoom OAuth, follow this order:**

1. **Run preflight checks first** → [RUNBOOK.md](RUNBOOK.md)

2. **Choose your OAuth flow** → [concepts/oauth-flows.md](concepts/oauth-flows.md)
   - 4 flows: S2S (backend), User (SaaS), Device (no browser), Chatbot
   - Decision matrix: Which flow fits your use case?

3. **Understand token lifecycle** → [concepts/token-lifecycle.md](concepts/token-lifecycle.md)
   - **CRITICAL**: How tokens expire, refresh, and revoke
   - Common pitfalls: refresh token rotation

4. **Implement your flow** → Jump to examples:
   - Backend automation → [examples/s2s-oauth-redis.md](examples/s2s-oauth-redis.md)
   - SaaS app → [examples/user-oauth-mysql.md](examples/user-oauth-mysql.md)
   - Mobile/SPA → [examples/pkce-implementation.md](examples/pkce-implementation.md)
   - Device (TV/kiosk) → [examples/device-flow.md](examples/device-flow.md)

5. **Fix redirect URI issues** → [troubleshooting/redirect-uri-issues.md](troubleshooting/redirect-uri-issues.md)
   - Most common OAuth error: Redirect URI mismatch

6. **Implement token refresh** → [examples/token-refresh.md](examples/token-refresh.md)
   - Automatic middleware pattern
   - Handle refresh token rotation

7. **Troubleshoot errors** → [troubleshooting/common-errors.md](troubleshooting/common-errors.md)
   - Error code tables (4700-4741 range)
   - Quick diagnostic workflow

---

## Documentation Structure

```
oauth/
├── SKILL.md                           # Main skill overview
├── SKILL.md                           # This file - navigation guide
│
├── concepts/                          # Core OAuth concepts
│   ├── oauth-flows.md                # 4 flows: S2S, User, Device, Chatbot
│   ├── token-lifecycle.md            # Expiration, refresh, revocation
│   ├── pkce.md                       # PKCE security for public clients
│   ├── scopes-architecture.md        # Classic vs Granular scopes
│   └── state-parameter.md            # CSRF protection with state
│
├── examples/                          # Complete working code
│   ├── s2s-oauth-basic.md            # S2S OAuth minimal example
│   ├── s2s-oauth-redis.md            # S2S OAuth with Redis caching (production)
│   ├── user-oauth-basic.md           # User OAuth minimal example
│   ├── user-oauth-mysql.md           # User OAuth with MySQL + encryption (production)
│   ├── device-flow.md                # Device authorization flow
│   ├── pkce-implementation.md        # PKCE for SPAs/mobile apps
│   └── token-refresh.md              # Auto-refresh middleware pattern
│
├── troubleshooting/                   # Problem solving guides
│   ├── common-errors.md              # Error codes 4700-4741
│   ├── redirect-uri-issues.md        # Most common OAuth error
│   ├── token-issues.md               # Expired, revoked, invalid tokens
│   └── scope-issues.md               # Scope mismatch errors
│
└── references/                        # Reference documentation
    ├── oauth-errors.md                # Complete error code reference
    ├── classic-scopes.md              # Classic scope reference
    └── granular-scopes.md             # Granular scope reference
```

---

## By Use Case

### I want to automate Zoom tasks on my own account
1. [OAuth Flows](concepts/oauth-flows.md#server-to-server-s2s-oauth) - S2S OAuth explained
2. [S2S OAuth Redis](examples/s2s-oauth-redis.md) - Production pattern with Redis caching
3. [Token Lifecycle](concepts/token-lifecycle.md) - 1hr token, no refresh

### I want to build a SaaS app for other Zoom users
1. [OAuth Flows](concepts/oauth-flows.md#user-authorization-oauth) - User OAuth explained
2. [User OAuth MySQL](examples/user-oauth-mysql.md) - Production pattern with encryption
3. [Token Refresh](examples/token-refresh.md) - Automatic refresh middleware
4. [Redirect URI Issues](troubleshooting/redirect-uri-issues.md) - Fix most common error

### I want to build a mobile or SPA app
1. [PKCE](concepts/pkce.md) - Why PKCE is required for public clients
2. [PKCE Implementation](examples/pkce-implementation.md) - Complete code example
3. [State Parameter](concepts/state-parameter.md) - CSRF protection

### I want to build an app for devices without browsers (TV, kiosk)
1. [OAuth Flows](concepts/oauth-flows.md#device-authorization-flow) - Device flow explained
2. [Device Flow Example](examples/device-flow.md) - Complete polling implementation
3. [Common Errors](troubleshooting/common-errors.md) - Device-specific errors

### I'm building a Team Chat bot
1. [OAuth Flows](concepts/oauth-flows.md#client-authorization-chatbot) - Chatbot flow explained
2. [S2S OAuth Basic](examples/s2s-oauth-basic.md) - Similar pattern, different grant type
3. [Scopes Architecture](concepts/scopes-architecture.md) - Chatbot-specific scopes

### I'm getting redirect URI errors (4709)
1. [Redirect URI Issues](troubleshooting/redirect-uri-issues.md) - **START HERE!**
2. [Common Errors](troubleshooting/common-errors.md#4709-redirect-uri-mismatch) - Error details
3. [User OAuth Basic](examples/user-oauth-basic.md) - See correct pattern

### I'm getting token errors (4700-4741)
1. [Token Issues](troubleshooting/token-issues.md) - Diagnostic workflow
2. [Token Lifecycle](concepts/token-lifecycle.md) - Understand expiration
3. [Token Refresh](examples/token-refresh.md) - Implement auto-refresh
4. [Common Errors](troubleshooting/common-errors.md) - Error code tables

### I'm getting scope errors (4711)
1. [Scope Issues](troubleshooting/scope-issues.md) - Mismatch causes
2. [Scopes Architecture](concepts/scopes-architecture.md) - Classic vs Granular
3. [Classic Scopes](references/classic-scopes.md) - Complete scope reference
4. [Granular Scopes](references/granular-scopes.md) - Granular scope reference

### I need to refresh tokens
1. [Token Lifecycle](concepts/token-lifecycle.md#refresh-strategy) - When to refresh
2. [Token Refresh](examples/token-refresh.md) - Middleware pattern
3. [Token Issues](troubleshooting/token-issues.md#refresh-token-problems) - Common mistakes

### I want to understand the difference between Classic and Granular scopes
1. [Scopes Architecture](concepts/scopes-architecture.md) - **Complete comparison**
2. [Classic Scopes](references/classic-scopes.md) - `resource:level` format
3. [Granular Scopes](references/granular-scopes.md) - `service:action:data_claim:access` format

### I need to secure my OAuth implementation
1. [PKCE](concepts/pkce.md) - Public client security
2. [State Parameter](concepts/state-parameter.md) - CSRF protection
3. [User OAuth MySQL](examples/user-oauth-mysql.md#token-encryption) - Token encryption at rest

### I want to migrate from JWT app to S2S OAuth
1. [S2S OAuth Redis](examples/s2s-oauth-redis.md) - Modern replacement
2. [Token Lifecycle](concepts/token-lifecycle.md) - Different token behavior

> **Note**: JWT App Type was deprecated in June 2023. Migrate to S2S OAuth for server-to-server automation.

---

## Most Critical Documents

### 1. OAuth Flows (DECISION DOCUMENT)
**[concepts/oauth-flows.md](concepts/oauth-flows.md)**

Understand which of the 4 flows to use:
- **S2S OAuth**: Backend automation (your account)
- **User OAuth**: SaaS apps (users authorize you)
- **Device Flow**: Devices without browsers
- **Chatbot**: Team Chat bots only

### 2. Token Lifecycle (MOST COMMON ISSUE)
**[concepts/token-lifecycle.md](concepts/token-lifecycle.md)**

99% of OAuth issues stem from misunderstanding:
- Token expiration (1 hour for all flows)
- Refresh token rotation (must save new refresh token)
- Revocation behavior (invalidates all tokens)

### 3. Redirect URI Issues (MOST COMMON ERROR)
**[troubleshooting/redirect-uri-issues.md](troubleshooting/redirect-uri-issues.md)**

Error 4709 ("Redirect URI mismatch") is the #1 OAuth error.
Must match EXACTLY (including trailing slash, http vs https).

---

## Key Learnings

### Critical Discoveries:

1. **Refresh Token Rotation**
   - Each refresh returns a NEW refresh token
   - Old refresh token becomes invalid
   - Failure to save new token causes 4735 errors
   - See: [Token Refresh](examples/token-refresh.md)

2. **S2S OAuth Uses Redis, User OAuth Uses Database**
   - S2S: Single token for entire account → Redis (ephemeral)
   - User: Per-user tokens → Database (persistent)
   - See: [S2S OAuth Redis](examples/s2s-oauth-redis.md) vs [User OAuth MySQL](examples/user-oauth-mysql.md)

3. **Redirect URI Must Match EXACTLY**
   - Trailing slash matters: `/callback` ≠ `/callback/`
   - Protocol matters: `http://` ≠ `https://`
   - Port matters: `:3000` ≠ `:3001`
   - See: [Redirect URI Issues](troubleshooting/redirect-uri-issues.md)

4. **PKCE Required for Public Clients**
   - Mobile apps CANNOT keep secrets
   - SPAs CANNOT keep secrets
   - PKCE prevents authorization code interception
   - See: [PKCE](concepts/pkce.md)

5. **State Parameter Prevents CSRF**
   - Generate random state before redirect
   - Store in session
   - Verify on callback
   - See: [State Parameter](concepts/state-parameter.md)

6. **Token Storage Must Be Encrypted**
   - NEVER store tokens in plain text
   - Use AES-256 minimum
   - See: [User OAuth MySQL](examples/user-oauth-mysql.md#token-encryption)

7. **JWT App Type is Deprecated (June 2023)**
   - No new JWT apps can be created
   - Existing apps still work but will eventually be sunset
   - Migrate to S2S OAuth or User OAuth

8. **Scope Levels Determine Authorization Requirements**
   - No suffix (user-level): Any user can authorize
   - `:admin`: Requires admin role
   - `:master`: Requires account owner (multi-account)
   - See: [Scopes Architecture](concepts/scopes-architecture.md)

9. **Authorization Codes Expire in 5 Minutes**
   - Exchange code for token immediately
   - Don't cache authorization codes
   - See: [Token Lifecycle](concepts/token-lifecycle.md#authorization-code-expiration)

10. **Device Flow Requires Polling**
    - Poll at interval returned by `/devicecode` (usually 5s)
    - Handle `authorization_pending`, `slow_down`, `expired_token`
    - See: [Device Flow](examples/device-flow.md)

---

## Quick Reference

### "Which OAuth flow should I use?"
→ [OAuth Flows](concepts/oauth-flows.md)

### "Redirect URI mismatch error (4709)"
→ [Redirect URI Issues](troubleshooting/redirect-uri-issues.md)

### "Token expired or invalid"
→ [Token Issues](troubleshooting/token-issues.md)

### "Refresh token invalid (4735)"
→ [Token Refresh](examples/token-refresh.md) - Must save new refresh token

### "Scope mismatch error (4711)"
→ [Scope Issues](troubleshooting/scope-issues.md)

### "How do I secure my OAuth app?"
→ [PKCE](concepts/pkce.md) + [State Parameter](concepts/state-parameter.md)

### "How do I implement auto-refresh?"
→ [Token Refresh](examples/token-refresh.md)

### "What's the difference between Classic and Granular scopes?"
→ [Scopes Architecture](concepts/scopes-architecture.md)

### "What error code means what?"
→ [Common Errors](troubleshooting/common-errors.md)

---

## Document Version

Based on **Zoom OAuth API v2** (2024+)

**Deprecated:** JWT App Type (June 2023)

---

**Happy coding!**

Remember: Start with [OAuth Flows](concepts/oauth-flows.md) to understand which flow fits your use case!

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/phone', 'business', 'phone', '', 'phone', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-phone-integration

Background reference for Zoom Phone integrations across API, webhook, Smart Embed, and URI-launch workflows.

Implementation guidance for Zoom Phone integrations across API, webhook/event, Smart Embed, and URI-launch workflows.

Official docs:
- https://developers.zoom.us/docs/phone/
- CRM sample reference: https://github.com/zoom/CRM-Sample

## Routing Guardrail

- If the user needs embedded softphone behavior in a web app, use Smart Embed ([examples/smart-embed-postmessage-bridge.md](examples/smart-embed-postmessage-bridge.md)).
- If the user needs call records, analytics, or automation, use Phone REST API and webhooks ([references/deprecations-and-migrations.md](references/deprecations-and-migrations.md)).
- If the user needs click-to-dial/SMS launch from external UI, use URI schemes (`zoomphonecall://`, `zoomphonesms://`).
- If the user mixes Zoom Phone and Contact Center, chain with [../contact-center/SKILL.md](../contact-center/SKILL.md).

## Quick Links

Start here:
1. [concepts/architecture-and-lifecycle.md](concepts/architecture-and-lifecycle.md)
2. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
3. [references/deprecations-and-migrations.md](references/deprecations-and-migrations.md)
4. [references/forum-top-questions.md](references/forum-top-questions.md)
5. [references/smart-embed-event-contract.md](references/smart-embed-event-contract.md)
6. [references/call-handling-patterns.md](references/call-handling-patterns.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/crm-sample-validation.md](references/crm-sample-validation.md)
9. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
10. [RUNBOOK.md](RUNBOOK.md)
11. [examples/smart-embed-postmessage-bridge.md](examples/smart-embed-postmessage-bridge.md)
12. [examples/phone-api-service-pattern.md](examples/phone-api-service-pattern.md)
13. [references/source-map.md](references/source-map.md)

## Common Lifecycle Pattern

1. Provision account prerequisites (Zoom Phone license, admin setup, SMS readiness).
2. Create OAuth app and scopes in Marketplace.
3. Choose integration surface:
- Smart Embed (iframe + postMessage)
- REST + webhooks
- URI launch (`callto`, `tel`, `zoomphonecall`, `zoomphonesms`)
4. Capture real-time events (Smart Embed events and/or webhooks).
5. Persist call identifiers and correlate records (`call_id`, `call_history_uuid`, `call_element_id`).
6. Apply migration-safe data mapping (v1 -> v2 -> v3) and handle renamed fields.
7. Harden security (origin validation, webhook signature validation, least-privilege scopes).

## High-Level Scenarios

- CRM softphone pane using Smart Embed + contact search/match callbacks.
- Click-to-call from account/contact table via `zp-make-call`.
- Call disposition workflow using `zp-save-log-event` and custom notes page.
- SMS engagement workflow with `zoomphonesms://` and `zp-sms-log-event`.
- Real-time operational board driven by `phone.*` webhook events.
- Call analytics migration from legacy call logs to call history/call elements.
- Admin automation for user/auto-receptionist/call-queue call-handling settings.

See [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md) for details.

## Chaining

- OAuth setup/token lifecycle: [../oauth/SKILL.md](../oauth/SKILL.md)
- Phone and account resources via REST: [../rest-api/SKILL.md](../rest-api/SKILL.md)
- Event delivery and signature validation: [../webhooks/SKILL.md](../webhooks/SKILL.md)
- Contact Center blended journey: [../contact-center/SKILL.md](../contact-center/SKILL.md)

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/plan-zoom-integration', 'business', 'plan-zoom-integration', '', 'plan-zoom-integration', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /plan-zoom-integration

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Create a practical build plan for a Zoom integration or app.

## Usage

```text
/plan-zoom-integration $ARGUMENTS
```

## Workflow

1. Capture the target user flow and success criteria.
2. Choose the correct Zoom surface and supporting services.
3. Define auth requirements, scopes, and account assumptions.
4. Break implementation into phases: prototype, core integration, reliability, and launch.
5. Call out hard risks early: OAuth setup, webhook verification, SDK environment limits, marketplace review, or MCP client constraints.
6. End with the smallest deliverable that proves the architecture.

## Output

- Architecture summary
- Zoom products and APIs required
- Auth and scope checklist
- Delivery phases
- Risks, open questions, and immediate next action

## Related Skills

- [start](../start/SKILL.md)
- [setup-zoom-oauth](../setup-zoom-oauth/SKILL.md)
- [build-zoom-meeting-app](../build-zoom-meeting-app/SKILL.md)
- [build-zoom-bot](../build-zoom-bot/SKILL.md)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/plan-zoom-product', 'business', 'plan-zoom-product', '', 'plan-zoom-product', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /plan-zoom-product

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Choose between Zoom REST API, Webhooks, WebSockets, Meeting SDK, Video SDK, Zoom Apps SDK, Phone, Contact Center, or MCP for a specific use case.

## Usage

```text
/plan-zoom-product $ARGUMENTS
```

## Workflow

1. Identify the user's actual goal.
2. Classify whether the problem is automation, embedded meetings, custom video, in-client app behavior, event delivery, AI tooling, or support/phone/contact-center work.
3. If the request is ambiguous, ask one short clarifier before locking the recommendation.
4. Recommend the primary Zoom surface and list the minimum supporting pieces.
5. Explain why the rejected alternatives are worse for this case.
6. End with a concrete next-step plan.

## Output

- Recommended Zoom surface
- Supporting components required
- Key tradeoffs and constraints
- Suggested implementation sequence
- Relevant skill links for the next step

## Related Skills

- [start](../start/SKILL.md)
- [choose-zoom-approach](../choose-zoom-approach/SKILL.md)
- [design-mcp-workflow](../design-mcp-workflow/SKILL.md)$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/probe-sdk', 'business', 'probe-sdk', '', 'probe-sdk', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Probe SDK

Background reference for preflight diagnostics on user devices and networks before meeting or session workflows.

Official docs:
- https://developers.zoom.us/docs/probe-sdk/
- https://marketplacefront.zoom.us/sdk/probe/index.html

Reference sample:
- https://github.com/zoom/probesdk-web

## Routing Guardrail

- Use Probe SDK when the user needs client-side diagnostics and readiness scoring (device/network/browser capability), not meeting/session join.
- If user needs embedded meeting flows, route to [../meeting-sdk/SKILL.md](../meeting-sdk/SKILL.md).
- If user needs custom real-time session UX, route to [../video-sdk/SKILL.md](../video-sdk/SKILL.md).
- If user needs backend orchestration of events/APIs, chain with [../rivet-sdk/SKILL.md](../rivet-sdk/SKILL.md), [../oauth/SKILL.md](../oauth/SKILL.md), and [../rest-api/SKILL.md](../rest-api/SKILL.md).

## Quick Links

Start here:
1. [probe-sdk.md](probe-sdk.md)
2. [concepts/architecture-and-lifecycle.md](concepts/architecture-and-lifecycle.md)
3. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
4. [examples/diagnostic-page-pattern.md](examples/diagnostic-page-pattern.md)
5. [examples/comprehensive-network-pattern.md](examples/comprehensive-network-pattern.md)
6. [references/probe-reference-map.md](references/probe-reference-map.md)
7. [references/environment-variables.md](references/environment-variables.md)
8. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
9. [references/samples-validation.md](references/samples-validation.md)
10. [references/source-map.md](references/source-map.md)
11. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
12. [RUNBOOK.md](RUNBOOK.md)

## Common Lifecycle Pattern

1. Initialize `Prober` / `Reporter`.
2. Request media permissions and enumerate devices.
3. Run targeted diagnostics (`diagnoseAudio`, `diagnoseVideo`).
4. Run comprehensive network diagnostic (`startToDiagnose`) and stream stats to UI.
5. Produce final report and apply readiness gates.
6. Stop/cleanup (`stopToDiagnose`, `stopToDiagnoseVideo`, `releaseMediaStream`, `cleanup`).

## High-Level Scenarios

- Pre-join diagnostics page before Meeting SDK join action.
- Support workflow that captures structured report for customer troubleshooting.
- Device certification flow for kiosk or controlled endpoint environments.
- Browser capability gating for advanced media features.

See [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md) for details.

## Chaining

- Meeting pre-join gate: [../meeting-sdk/web/SKILL.md](../meeting-sdk/web/SKILL.md)
- Video session readiness gate: [../video-sdk/web/SKILL.md](../video-sdk/web/SKILL.md)
- Telemetry/report ingestion backend: [../rivet-sdk/SKILL.md](../rivet-sdk/SKILL.md) + [../rest-api/SKILL.md](../rest-api/SKILL.md)

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for optional `.env` keys and how to source values.

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/rest-api', 'business', 'rest-api', '', 'rest-api', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# /build-zoom-rest-api-app

Background reference for deterministic server-side Zoom automation and resource management. Prefer `plan-zoom-product`, `plan-zoom-integration`, or `debug-zoom` first, then route here for endpoint-level detail.

# Zoom REST API

Expert guidance for building server-side integrations with the Zoom REST API. This API provides 600+ endpoints for managing meetings, users, webinars, recordings, reports, and all Zoom platform resources programmatically.

**Official Documentation**: https://developers.zoom.us/api-hub/
**API Hub Reference**: https://developers.zoom.us/api-hub/meetings/
**OpenAPI Inventories**: `https://developers.zoom.us/api-hub/<domain>/methods/endpoints.json`

## Quick Links

**New to Zoom REST API? Follow this path:**

1. **[API Architecture](concepts/api-architecture.md)** - Base URLs, regional URLs, `me` keyword, ID vs UUID, time formats
2. **[Authentication Flows](concepts/authentication-flows.md)** - OAuth setup (S2S, User, PKCE, Device Code)
3. **[Meeting URLs vs Meeting SDK](concepts/meeting-urls-and-sdk-joining.md)** - Stop mixing `join_url` with Meeting SDK
3. **[Meeting Lifecycle](examples/meeting-lifecycle.md)** - Create → Update → Start → End → Delete with webhooks
4. **[Rate Limiting Strategy](concepts/rate-limiting-strategy.md)** - Plan tiers, per-user limits, retry patterns

**Reference:**
- **[Meetings](references/meetings.md)** - Meeting CRUD, types, settings
- **[Users](references/users.md)** - User provisioning and management
- **[Recordings](references/recordings.md)** - Cloud recording access and download
- **[AI Services](references/ai-services.md)** - Scribe endpoint inventory and current AI Services path surface
- **[GraphQL Queries](examples/graphql-queries.md)** - Alternative query API (beta)
- **Integrated Index** - see the section below in this file

Most domain files under `references/` are aligned to the official API Hub `endpoints.json` inventories. Treat those files as the local source of truth for method/path discovery.

**Having issues?**
- Start with preflight checks → [5-Minute Runbook](RUNBOOK.md)
- 401 Unauthorized → [Authentication Flows](concepts/authentication-flows.md) (check token expiry, scopes)
- 429 Too Many Requests → [Rate Limiting Strategy](concepts/rate-limiting-strategy.md)
- Error codes → [Common Errors](troubleshooting/common-errors.md)
- Pagination confusion → [Common Issues](troubleshooting/common-issues.md)
- Webhooks not arriving → [Webhook Server](examples/webhook-server.md)
- Forum-derived FAQs → [Forum Top Questions](troubleshooting/forum-top-questions.md)
- Token/scope failures → [Token + Scope Playbook](troubleshooting/token-scope-playbook.md)

**Building event-driven integrations?**
- [Webhook Server](examples/webhook-server.md) - Express.js server with CRC validation
- [Recording Pipeline](examples/recording-pipeline.md) - Auto-download via webhook events

## Quick Start

### Get an Access Token (Server-to-Server OAuth)

```bash
curl -X POST "https://zoom.us/oauth/token" \
  -H "Authorization: Basic $(echo -n 'CLIENT_ID:CLIENT_SECRET' | base64)" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=account_credentials&account_id=ACCOUNT_ID"
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "meeting:read meeting:write user:read"
}
```

### Create a Meeting

```bash
curl -X POST "https://api.zoom.us/v2/users/HOST_USER_ID/meetings" \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "Team Standup",
    "type": 2,
    "start_time": "2025-03-15T10:00:00Z",
    "duration": 30,
    "settings": {
      "join_before_host": false,
      "waiting_room": true
    }
  }'
```

For S2S OAuth, use an explicit host user ID or email in the path. Do not use `me`.

### List Users with Pagination

```bash
curl "https://api.zoom.us/v2/users?page_size=300&status=active" \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

## Base URL

```
https://api.zoom.us/v2
```

### Regional Base URLs

The `api_url` field in OAuth token responses indicates the user's region. Use regional URLs for data residency compliance:

| Region | URL |
|--------|-----|
| Global (default) | `https://api.zoom.us/v2` |
| Australia | `https://api-au.zoom.us/v2` |
| Canada | `https://api-ca.zoom.us/v2` |
| European Union | `https://api-eu.zoom.us/v2` |
| India | `https://api-in.zoom.us/v2` |
| Saudi Arabia | `https://api-sa.zoom.us/v2` |
| Singapore | `https://api-sg.zoom.us/v2` |
| United Kingdom | `https://api-uk.zoom.us/v2` |
| United States | `https://api-us.zoom.us/v2` |

**Note:** You can always use the global URL `https://api.zoom.us` regardless of the `api_url` value.

## Key Features

| Feature | Description |
|---------|-------------|
| **Meeting Management** | Create, read, update, delete meetings with full scheduling control |
| **User Provisioning** | Automated user lifecycle (create, update, deactivate, delete) |
| **Webinar Operations** | Webinar CRUD, registrant management, panelist control |
| **Cloud Recordings** | List, download, delete recordings with file-type filtering |
| **Reports & Analytics** | Usage reports, participant data, daily statistics |
| **Team Chat** | Channel management, messaging, chatbot integration |
| **Zoom Phone** | Call management, voicemail, call routing |
| **Zoom Rooms** | Room management, device control, scheduling |
| **Webhooks** | Real-time event notifications for 100+ event types |
| **WebSockets** | Persistent event streaming without public endpoints |
| **GraphQL (Beta)** | Single-endpoint flexible queries at `v3/graphql` |
| **AI Companion** | Meeting summaries, transcripts, AI-generated content |
| **AI Services / Scribe** | File and archive transcription via Build-platform JWT-authenticated endpoints |

## Prerequisites

- Zoom account (Free tier has API access with lower rate limits)
- App registered on [Zoom App Marketplace](https://marketplace.zoom.us/)
- OAuth credentials (Server-to-Server OAuth or User OAuth)
- Appropriate scopes for target endpoints

> **Need help with authentication?** See the **[zoom-oauth](../oauth/SKILL.md)** skill for complete OAuth flow implementation.

## Critical Gotchas and Best Practices

### ⚠️ JWT App Type is Deprecated

The JWT app type is deprecated. Migrate to **Server-to-Server OAuth**. This does NOT affect JWT token signatures used in Video SDK — only the Marketplace "JWT" app type for REST API access.

```javascript
// OLD (JWT app type - DEPRECATED)
const token = jwt.sign({ iss: apiKey, exp: expiry }, apiSecret);

// NEW (Server-to-Server OAuth)
const token = await getServerToServerToken(accountId, clientId, clientSecret);
```

### ⚠️ The `me` Keyword Rules

- **User-level OAuth apps**: MUST use `me` instead of `userId` (otherwise: invalid token error)
- **Server-to-Server OAuth apps**: MUST NOT use `me` — provide the actual `userId` or email
- **Account-level OAuth apps**: Can use either `me` or `userId`

### ⚠️ Meeting ID vs UUID — Double Encoding

UUIDs that begin with `/` or contain `//` must be **double URL-encoded**:

```javascript
// UUID: /abc==
// Single encode: %2Fabc%3D%3D
// Double encode: %252Fabc%253D%253D  ← USE THIS

const uuid = '/abc==';
const encoded = encodeURIComponent(encodeURIComponent(uuid));
const url = `https://api.zoom.us/v2/meetings/${encoded}`;
```

### ⚠️ Time Formats

- `yyyy-MM-ddTHH:mm:ssZ` — **UTC time** (note the `Z` suffix)
- `yyyy-MM-ddTHH:mm:ss` — **Local time** (no `Z`, uses `timezone` field)
- Some report APIs only accept UTC. Check the API reference for each endpoint.

### ⚠️ Rate Limits Are Per-Account, Not Per-App

All apps on the same Zoom account **share** rate limits. One heavy app can impact others. Monitor `X-RateLimit-Remaining` headers proactively.

### ⚠️ Per-User Daily Limits

Meeting/Webinar create/update operations are limited to **100 per day per user** (resets at 00:00 UTC). Distribute operations across different host users when doing bulk operations.

### ⚠️ Download URLs Require Auth and Follow Redirects

Recording `download_url` values require Bearer token authentication and may redirect. Always follow redirects:

```bash
curl -L -H "Authorization: Bearer ACCESS_TOKEN" "https://zoom.us/rec/download/..."
```

### Use Webhooks Instead of Polling

```javascript
// DON'T: Poll every minute (wastes API quota)
setInterval(() => getMeetings(), 60000);

// DO: Receive webhook events in real-time
app.post('/webhook', (req, res) => {
  if (req.body.event === 'meeting.started') {
    handleMeetingStarted(req.body.payload);
  }
  res.status(200).send();
});
```

> **Webhook setup details:** See the **[zoom-webhooks](../webhooks/SKILL.md)** skill for comprehensive webhook implementation.

## Complete Documentation Library

This skill includes comprehensive guides organized by category:

### Core Concepts
- **[API Architecture](concepts/api-architecture.md)** - REST design, base URLs, regional routing, `me` keyword, ID vs UUID, time formats
- **[Authentication Flows](concepts/authentication-flows.md)** - All OAuth flows (S2S, User, PKCE, Device Code)
- **[Rate Limiting Strategy](concepts/rate-limiting-strategy.md)** - Limits by plan, retry patterns, request queuing

### Complete Examples
- **[Meeting Lifecycle](examples/meeting-lifecycle.md)** - Full Create → Update → Start → End → Delete flow with webhook events
- **[User Management](examples/user-management.md)** - CRUD users, list with pagination, bulk operations
- **[Recording Pipeline](examples/recording-pipeline.md)** - Download recordings via webhooks + API
- **[Webhook Server](examples/webhook-server.md)** - Express.js server with CRC validation and signature verification
- **[GraphQL Queries](examples/graphql-queries.md)** - GraphQL queries, mutations, cursor pagination

### Troubleshooting
- **[Common Errors](troubleshooting/common-errors.md)** - HTTP status codes, Zoom error codes, error response formats
- **[Common Issues](troubleshooting/common-issues.md)** - Rate limits, token refresh, pagination pitfalls, gotchas

### References (39 files covering all Zoom API domains)

#### Core APIs
- **[references/meetings.md](references/meetings.md)** - Meeting CRUD, types, settings
- **[references/users.md](references/users.md)** - User provisioning, types, scopes
- **[references/webinars.md](references/webinars.md)** - Webinar management, registrants
- **[references/recordings.md](references/recordings.md)** - Cloud recording access
- **[references/reports.md](references/reports.md)** - Usage reports, analytics
- **[references/accounts.md](references/accounts.md)** - Account management

#### Communication
- **[references/team-chat.md](references/team-chat.md)** - Team Chat messaging
- **[references/chatbot.md](references/chatbot.md)** - Interactive chatbots
- **[references/phone.md](references/phone.md)** - Zoom Phone
- **[references/mail.md](references/mail.md)** - Zoom Mail
- **[references/calendar.md](references/calendar.md)** - Zoom Calendar

#### Infrastructure
- **[references/rooms.md](references/rooms.md)** - Zoom Rooms
- **[references/scim2.md](references/scim2.md)** - SCIM 2.0 provisioning APIs
- **[references/rate-limits.md](references/rate-limits.md)** - Rate limit details
- **[references/qss.md](references/qss.md)** - Quality of Service Subscription

#### Advanced
- **[references/graphql.md](references/graphql.md)** - GraphQL API (beta)
- **[references/ai-companion.md](references/ai-companion.md)** - AI features
- **[references/authentication.md](references/authentication.md)** - Auth reference
- **[references/openapi.md](references/openapi.md)** - OpenAPI specs, Postman, code generation

#### Additional API Domains
- **[references/events.md](references/events.md)** - Events and event platform APIs
- **[references/scheduler.md](references/scheduler.md)** - Zoom Scheduler APIs
- **[references/tasks.md](references/tasks.md)** - Tasks APIs
- **[references/whiteboard.md](references/whiteboard.md)** - Whiteboard APIs
- **[references/video-management.md](references/video-management.md)** - Video management APIs
- **[references/video-sdk-api.md](references/video-sdk-api.md)** - Video SDK REST APIs
- **[references/marketplace-apps.md](references/marketplace-apps.md)** - Marketplace app management
- **[references/commerce.md](references/commerce.md)** - Commerce and billing APIs
- **[references/contact-center.md](references/contact-center.md)** - Contact Center APIs
- **[references/quality-management.md](references/quality-management.md)** - Quality management APIs
- **[references/workforce-management.md](references/workforce-management.md)** - Workforce management APIs
- **[references/healthcare.md](references/healthcare.md)** - Healthcare APIs
- **[references/auto-dialer.md](references/auto-dialer.md)** - Auto dialer APIs
- **[references/number-management.md](references/number-management.md)** - Number management APIs
- **[references/revenue-accelerator.md](references/revenue-accelerator.md)** - Revenue Accelerator APIs
- **[references/virtual-agent.md](references/virtual-agent.md)** - Virtual Agent APIs
- **[references/cobrowse-sdk-api.md](references/cobrowse-sdk-api.md)** - Cobrowse SDK APIs
- **[references/crc.md](references/crc.md)** - Cloud Room Connector APIs
- **[references/clips.md](references/clips.md)** - Clips APIs
- **[references/zoom-docs.md](references/zoom-docs.md)** - Zoom docs and source references

## Sample Repositories

### Official (by Zoom)

| Type | Repository |
|------|------------|
| OAuth Sample | [oauth-sample-app](https://github.com/zoom/oauth-sample-app) |
| S2S OAuth Starter | [server-to-server-oauth-starter-api](https://github.com/zoom/server-to-server-oauth-starter-api) |
| User OAuth | [user-level-oauth-starter](https://github.com/zoom/user-level-oauth-starter) |
| S2S Token | [server-to-server-oauth-token](https://github.com/zoom/server-to-server-oauth-token) |
| Rivet Library | [rivet-javascript](https://github.com/zoom/rivet-javascript) |
| WebSocket Sample | [websocket-js-sample](https://github.com/zoom/websocket-js-sample) |
| Webhook Sample | [webhook-sample-node.js](https://github.com/zoom/webhook-sample-node.js) |
| Python S2S | [server-to-server-python-sample](https://github.com/zoom/server-to-server-python-sample) |

## Resources

- **API Reference**: https://developers.zoom.us/api-hub/
- **GraphQL Playground**: https://nws.zoom.us/graphql/playground
- **Postman Collection**: https://marketplace.zoom.us/docs/api-reference/postman
- **Developer Forum**: https://devforum.zoom.us/
- **Changelog**: https://developers.zoom.us/changelog/
- **Status Page**: https://status.zoom.us/

---

**Need help?** Start with Integrated Index section below for complete navigation.

---

## Integrated Index

_This section was migrated from `SKILL.md`._

## Quick Start Path

**If you're new to the Zoom REST API, follow this order:**

1. **Run preflight checks first** → [RUNBOOK.md](RUNBOOK.md)

2. **Understand the API design** → [concepts/api-architecture.md](concepts/api-architecture.md)
   - Base URLs, regional endpoints, `me` keyword rules
   - Meeting ID vs UUID, double-encoding, time formats

3. **Set up authentication** → [concepts/authentication-flows.md](concepts/authentication-flows.md)
   - Server-to-Server OAuth (backend automation)
   - User OAuth with PKCE (user-facing apps)
   - Cross-reference: [zoom-oauth](../oauth/SKILL.md)

4. **Create your first meeting** → [examples/meeting-lifecycle.md](examples/meeting-lifecycle.md)
   - Full CRUD with curl and Node.js examples
   - Webhook event integration

5. **Handle rate limits** → [concepts/rate-limiting-strategy.md](concepts/rate-limiting-strategy.md)
   - Plan-based limits, retry patterns, request queuing

6. **Set up webhooks** → [examples/webhook-server.md](examples/webhook-server.md)
   - CRC validation, signature verification, event handling

7. **Troubleshoot issues** → [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
   - Token refresh, pagination pitfalls, common gotchas

---

## Documentation Structure

```
rest-api/
├── SKILL.md                              # Main skill overview + quick start
├── SKILL.md                              # This file - navigation guide
│
├── concepts/                             # Core architectural concepts
│   ├── api-architecture.md              # REST design, URLs, IDs, time formats
│   ├── authentication-flows.md          # OAuth flows (S2S, User, PKCE, Device)
│   └── rate-limiting-strategy.md        # Limits by plan, retry, queuing
│
├── examples/                             # Complete working code
│   ├── meeting-lifecycle.md             # Create→Update→Start→End→Delete
│   ├── user-management.md              # CRUD users, pagination, bulk ops
│   ├── recording-pipeline.md           # Download recordings via webhooks
│   ├── webhook-server.md               # Express.js CRC + signature verification
│   └── graphql-queries.md              # GraphQL queries, mutations, pagination
│
├── troubleshooting/                      # Problem solving
│   ├── common-errors.md                # HTTP codes, Zoom error codes table
│   └── common-issues.md               # Rate limits, tokens, pagination pitfalls
│
└── references/                           # 39 domain-specific reference files
    ├── authentication.md                # Auth methods reference
    ├── meetings.md                      # Meeting endpoints
    ├── users.md                         # User management endpoints
    ├── webinars.md                      # Webinar endpoints
    ├── recordings.md                    # Cloud recording endpoints
    ├── reports.md                       # Reports & analytics
    ├── accounts.md                      # Account management
    ├── rate-limits.md                   # Rate limit details
    ├── graphql.md                       # GraphQL API (beta)
    ├── zoom-team-chat.md                     # Team Chat messaging
    ├── chatbot.md                       # Chatbot integration
    ├── phone.md                         # Zoom Phone
    ├── rooms.md                         # Zoom Rooms
    ├── calendar.md                      # Zoom Calendar
    ├── mail.md                          # Zoom Mail
    ├── ai-companion.md                  # AI features
    ├── openapi.md                       # OpenAPI specs
    ├── qss.md                           # Quality of Service
    ├── contact-center.md                # Contact Center
    ├── events.md                        # Zoom Events
    ├── whiteboard.md                    # Whiteboard
    ├── clips.md                         # Zoom Clips
    ├── scheduler.md                     # Scheduler
    ├── scim2.md                         # SCIM 2.0
    ├── marketplace-apps.md              # App management
    ├── zoom-video-sdk-api.md                 # Video SDK REST
    └── ... (39 total files)
```

---

## By Use Case

### I want to create and manage meetings
1. [API Architecture](concepts/api-architecture.md) - Base URL, time formats
2. [Meeting Lifecycle](examples/meeting-lifecycle.md) - Full CRUD + webhook events
3. [Meetings Reference](references/meetings.md) - All endpoints, types, settings

### I want to manage users programmatically
1. [User Management](examples/user-management.md) - CRUD, pagination, bulk ops
2. [Users Reference](references/users.md) - Endpoints, user types, scopes

### I want to download recordings automatically
1. [Recording Pipeline](examples/recording-pipeline.md) - Webhook-triggered downloads
2. [Recordings Reference](references/recordings.md) - File types, download auth

### I want to receive real-time events
1. [Webhook Server](examples/webhook-server.md) - CRC validation, signature check
2. Cross-reference: [zoom-webhooks](../webhooks/SKILL.md) for comprehensive webhook docs
3. Cross-reference: [zoom-websockets](../websockets/SKILL.md) for WebSocket events

### I want to use GraphQL instead of REST
1. [GraphQL Queries](examples/graphql-queries.md) - Queries, mutations, pagination
2. [GraphQL Reference](references/graphql.md) - Available entities, scopes, rate limits

### I want to set up authentication
1. [Authentication Flows](concepts/authentication-flows.md) - All OAuth methods
2. Cross-reference: [zoom-oauth](../oauth/SKILL.md) for full OAuth implementation

### I'm hitting rate limits
1. [Rate Limiting Strategy](concepts/rate-limiting-strategy.md) - Limits by plan, strategies
2. [Rate Limits Reference](references/rate-limits.md) - Detailed tables
3. [Common Issues](troubleshooting/common-issues.md) - Practical solutions

### I'm getting errors
1. [Common Errors](troubleshooting/common-errors.md) - Error code tables
2. [Common Issues](troubleshooting/common-issues.md) - Diagnostic workflow

### I want to build webinars
1. [Webinars Reference](references/webinars.md) - Endpoints, types, registrants
2. [Meeting Lifecycle](examples/meeting-lifecycle.md) - Similar patterns apply

### I want to integrate Zoom Phone
1. [Phone Reference](references/phone.md) - Phone API endpoints
2. [Rate Limiting Strategy](concepts/rate-limiting-strategy.md) - Separate Phone rate limits

---

## Most Critical Documents

### 1. API Architecture (FOUNDATION)
**[concepts/api-architecture.md](concepts/api-architecture.md)**

Essential knowledge before making any API call:
- Base URLs and regional endpoints
- The `me` keyword rules (different per app type!)
- Meeting ID vs UUID double-encoding
- ISO 8601 time formats (UTC vs local)
- Download URL authentication

### 2. Rate Limiting Strategy (MOST COMMON PRODUCTION ISSUE)
**[concepts/rate-limiting-strategy.md](concepts/rate-limiting-strategy.md)**

Rate limits are per-account, shared across all apps:
- Free: 4/sec Light, 2/sec Medium, 1/sec Heavy
- Pro: 30/sec Light, 20/sec Medium, 10/sec Heavy
- Business+: 80/sec Light, 60/sec Medium, 40/sec Heavy
- Per-user: 100 meeting create/update per day

### 3. Meeting Lifecycle (MOST COMMON TASK)
**[examples/meeting-lifecycle.md](examples/meeting-lifecycle.md)**

Complete CRUD with webhook integration — the pattern most developers need first.

---

## Key Learnings

### Critical Discoveries:

1. **JWT app type is deprecated** — use Server-to-Server OAuth
   - The JWT *app type* on Marketplace is deprecated, NOT JWT token signatures
   - See: [Authentication Flows](concepts/authentication-flows.md)

2. **`me` keyword behaves differently by app type**
   - User OAuth: MUST use `me`
   - S2S OAuth: MUST NOT use `me`
   - See: [API Architecture](concepts/api-architecture.md)

3. **Rate limiting is nuanced (don’t assume a single global rule)**
   - Limits can vary by endpoint and may be enforced at account/app/user levels
   - Treat quotas as potentially shared across your account and implement backoff
   - Monitor rate limit response headers (for example `X-RateLimit-Remaining`)
   - See: [Rate Limiting Strategy](concepts/rate-limiting-strategy.md)

4. **100 meeting creates per user per day**
   - This is a hard per-user limit, not related to rate limits
   - Distribute across host users for bulk operations
   - See: [Rate Limiting Strategy](concepts/rate-limiting-strategy.md)

5. **UUID double-encoding is required for certain UUIDs**
   - UUIDs starting with `/` or containing `//` must be double-encoded
   - See: [API Architecture](concepts/api-architecture.md)

6. **Pagination: use `next_page_token`, not `page_number`**
   - `page_number` is legacy and being phased out
   - `next_page_token` is the recommended approach
   - See: [Common Issues](troubleshooting/common-issues.md)

7. **GraphQL is at `/v3/graphql`, not `/v2/`**
   - Single endpoint, cursor-based pagination
   - Rate limits apply per-field (each field = one REST equivalent)
   - See: [GraphQL Queries](examples/graphql-queries.md)

---

## Quick Reference

### "401 Unauthorized"
→ [Authentication Flows](concepts/authentication-flows.md) - Token expired or wrong scopes

### "429 Too Many Requests"
→ [Rate Limiting Strategy](concepts/rate-limiting-strategy.md) - Check headers for reset time

### "Invalid token" when using userId
→ [API Architecture](concepts/api-architecture.md) - User OAuth apps must use `me`

### "How do I paginate results?"
→ [Common Issues](troubleshooting/common-issues.md) - Use `next_page_token`

### "Webhooks not arriving"
→ [Webhook Server](examples/webhook-server.md) - CRC validation required

### "Recording download fails"
→ [Recording Pipeline](examples/recording-pipeline.md) - Bearer auth + follow redirects

### "How do I create a meeting?"
→ [Meeting Lifecycle](examples/meeting-lifecycle.md) - Full working examples

---

## Related Skills

| Skill | Use When |
|-------|----------|
| **[zoom-oauth](../oauth/SKILL.md)** | Implementing OAuth flows, token management |
| **[zoom-webhooks](../webhooks/SKILL.md)** | Deep webhook implementation, event catalog |
| **[zoom-websockets](../websockets/SKILL.md)** | WebSocket event streaming |
| **[zoom-general](../general/SKILL.md)** | Cross-product patterns, community repos |

---

**Based on Zoom REST API v2 (current) and GraphQL v3 (beta)**

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/rivet-sdk', 'business', 'rivet-sdk', '', 'rivet-sdk', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Rivet SDK

Background reference for Zoom Rivet as a JavaScript and TypeScript server framework for Zoom integrations.

Implementation guidance for Zoom Rivet (JavaScript/TypeScript) as a server-side framework for:
- OAuth and token handling
- Webhook event consumption
- Typed REST API endpoint wrappers
- Multi-module server composition

Official docs:
- https://developers.zoom.us/docs/rivet/
- https://developers.zoom.us/docs/rivet/javascript/
- https://zoom.github.io/rivet-javascript/

Reference samples:
- https://github.com/zoom/rivet-javascript-sample
- https://github.com/zoom/isv-rivet-starter
- https://github.com/zoom/Rivet-Server-Sample
- https://github.com/zoom/rivet-javascript

## Routing Guardrail

- Rivet SDK is a Node.js framework that bundles Zoom auth handling, webhook receivers, and typed API wrappers.
- Rivet is recommended for faster server-side scaffolding, but it is not mandatory.
- At planning start, confirm preference:
- `Do you want Rivet SDK, or direct OAuth + REST without Rivet?`
- Use Rivet when the user wants a Node.js server that combines Zoom auth + webhooks + API calls with minimal glue code.
- If the user only needs direct API calls from an existing backend, chain with [../rest-api/SKILL.md](../rest-api/SKILL.md).
- If the user is focused on Zoom Team Chat app cards/commands behavior, chain with [../team-chat/SKILL.md](../team-chat/SKILL.md).
- If the user needs SDK embed (Meeting SDK/Video SDK client runtime), route to [../meeting-sdk/SKILL.md](../meeting-sdk/SKILL.md) or [../video-sdk/SKILL.md](../video-sdk/SKILL.md).

## Quick Links

Start here:
1. [concepts/architecture-and-lifecycle.md](concepts/architecture-and-lifecycle.md)
2. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
3. [examples/getting-started-pattern.md](examples/getting-started-pattern.md)
4. [examples/multi-client-pattern.md](examples/multi-client-pattern.md)
5. [references/rivet-reference-map.md](references/rivet-reference-map.md)
6. [references/versioning-and-compatibility.md](references/versioning-and-compatibility.md)
7. [references/samples-validation.md](references/samples-validation.md)
8. [references/source-map.md](references/source-map.md)
9. [references/environment-variables.md](references/environment-variables.md)
10. [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
11. [RUNBOOK.md](RUNBOOK.md)
12. [rivet-sdk.md](rivet-sdk.md)

## Common Lifecycle Pattern

1. Choose modules and auth model per module (Client Credentials, User OAuth, S2S OAuth, Video SDK JWT).
2. Instantiate client(s) with credentials, webhook secret, and per-module port.
3. Register event handlers (`webEventConsumer.event(...)` or shortcuts).
4. Implement API calls through `client.endpoints.*`.
5. Start receiver(s) and expose webhook endpoint(s) (`/zoom/events`) to Zoom.
6. Persist tokens/state for OAuth workloads and enforce signature verification.
7. Monitor module-specific failures and rotate secrets/version with changelog cadence.

## High-Level Scenarios

- Team Chat slash-command bot + Team Chat data API enrichment.
- Multi-module backend (Users + Meetings + Team Chat + Phone) sharing one process.
- Video SDK telemetry backend using `videosdk` module event stream + API surfaces.
- ISV orchestration layer with tenant-aware token storage and per-module webhooks.
- AWS Lambda webhook processor with Rivet `AwsLambdaReceiver`.

See [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md) for details.

## Chaining

- OAuth architecture and grant selection: [../oauth/SKILL.md](../oauth/SKILL.md)
- API endpoint semantics and request payload details: [../rest-api/SKILL.md](../rest-api/SKILL.md)
- Team Chat app cards, command and bot UX: [../team-chat/SKILL.md](../team-chat/SKILL.md)
- Video SDK API-specific behavior and BYOS context: [../video-sdk/SKILL.md](../video-sdk/SKILL.md)

## Environment Variables

- See [references/environment-variables.md](references/environment-variables.md) for standardized `.env` keys and where to find each value.

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/rtms', 'business', 'rtms', '', 'rtms', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom Realtime Media Streams (RTMS)

Background reference for live Zoom media pipelines. Prefer `build-zoom-bot` first, then use this skill for stream types, capabilities, and RTMS-specific implementation constraints.

# Zoom Realtime Media Streams (RTMS)

Expert guidance for accessing live audio, video, transcript, chat, and screen share data from Zoom meetings, webinars, Video SDK sessions, and Zoom Contact Center Voice in real-time. RTMS uses a WebSocket-based protocol with open standards and does not require a meeting bot to capture the media plane.

## Read This First (Critical)

RTMS is primarily a **backend media ingestion service**.

- Your backend receives and processes live media: **audio, video, screen share, chat, transcript**.
- RTMS is not a frontend UI SDK by itself.
- Processing is **event-triggered**: backend waits for RTMS start webhook events before stream handling begins.

Optional architecture (common):

- Add a **Zoom App SDK** frontend for in-client UI/controls.
- Stream backend RTMS outputs to frontend via **WebSocket** (or SSE, gRPC, queue workers, etc.).

Use RTMS for media/data plane, and use frontend frameworks/Zoom Apps for presentation + user interactions.

**Official Documentation**: https://developers.zoom.us/docs/rtms/
**SDK Reference (JS)**: https://zoom.github.io/rtms/js/
**SDK Reference (Python)**: https://zoom.github.io/rtms/py/
**Sample Repository**: https://github.com/zoom/rtms-samples

## Quick Links

**New to RTMS? Follow this path:**

1. **[Connection Architecture](concepts/connection-architecture.md)** - Two-phase WebSocket design
2. **[SDK Quickstart](examples/sdk-quickstart.md)** - Fastest way to receive media (recommended)
3. **[Manual WebSocket](examples/manual-websocket.md)** - Full protocol control without SDK
4. **[Media Types](references/media-types.md)** - Audio, video, transcript, chat, screen share

**Complete Implementation:**
- **[RTMS Bot](examples/rtms-bot.md)** - End-to-end bot implementation guide

**Reference:**
- **[Lifecycle Flow](concepts/lifecycle-flow.md)** - Complete webhook-to-streaming flow
- **[Data Types](references/data-types.md)** - All enums and constants
- **[Webhooks](references/webhooks.md)** - Event subscription details
- **[Environment Variables](references/environment-variables.md)** - credential modes and runtime knobs
- **[Quickstart Notes](references/quickstart.md)** - Secondary quickstart guide
- **Integrated Index** - see the section below in this file

**Having issues?**
- Connection fails -> [Common Issues](troubleshooting/common-issues.md)
- Duplicate connections -> [Webhook Gotchas](troubleshooting/common-issues.md#webhook-response-timing)
- No audio/video -> [Media Configuration](references/media-types.md)
- Start with preflight checks -> [5-Minute Runbook](RUNBOOK.md)

## Supported Products

| Product | Webhook Event | Payload ID | App Type |
|---------|--------------|------------|----------|
| **Meetings** | `meeting.rtms_started` / `meeting.rtms_stopped` | `meeting_uuid` | General App |
| **Webinars** | `webinar.rtms_started` / `webinar.rtms_stopped` | `meeting_uuid` (same!) | General App |
| **Video SDK** | `session.rtms_started` / `session.rtms_stopped` | `session_id` | Video SDK App |
| **Zoom Contact Center Voice** | Product-specific RTMS/ZCC Voice events | Product-specific stream/session identifiers | Contact Center / approved RTMS integration |

Once connected, the core signaling/media socket model is shared across products. Meetings, webinars, and Video SDK sessions use the familiar start/stop webhooks. Zoom Contact Center Voice adds its own RTMS/ZCC Voice event family and should be treated as the same transport model with product-specific event payloads.

## RTMS Overview

RTMS is a data pipeline that gives your app access to live media from Zoom meetings, webinars, and Video SDK sessions **without participant bots**. Instead of having automated clients join meetings, use RTMS to collect media data directly from Zoom's infrastructure.

### What RTMS Provides

| Media Type | Format | Use Cases |
|------------|--------|-----------|
| **Audio** | PCM (L16), G.711, G.722, Opus | Transcription, voice analysis, recording |
| **Video** | H.264, JPG, PNG | Recording, AI vision, thumbnails, active participant selection |
| **Screen Share** | H.264, JPG, PNG | Content capture, slide extraction |
| **Transcript** | JSON text | Meeting notes, search, compliance |
| **Chat** | JSON text | Archive, sentiment analysis |

### March 2026 Protocol Changes

- **Zoom Contact Center Voice support**: RTMS now covers Contact Center Voice audio and transcript scenarios.
- **Transcript Language Identification control**: transcript media handshakes now support `src_language` and `enable_lid`. Default behavior is LID enabled. Set `enable_lid: false` to force a fixed language.
- **Single individual video stream subscription**: RTMS can now stream one participant's camera feed at a time when `data_opt` is set to `VIDEO_SINGLE_INDIVIDUAL_STREAM`.
- **Graceful client-initiated shutdown**: backends can send `STREAM_CLOSE_REQ` over the signaling socket and wait for `STREAM_CLOSE_RESP`.
- **Media keep-alive tolerance increased**: media socket keep-alive timeout is now **65 seconds**, not 35.

### Two Approaches

| Approach | Best For | Complexity |
|----------|----------|------------|
| **SDK** (`@zoom/rtms`) | Most use cases | Low - handles WebSocket complexity |
| **Manual WebSocket** | Custom protocols, other languages | High - full protocol implementation |

## Prerequisites

- **Node.js 20.3.0+** (24 LTS recommended) for JavaScript SDK
- **Python 3.10+** for Python SDK
- Zoom General App (for meetings/webinars) or Video SDK App (for Video SDK) with RTMS feature enabled
- Webhook endpoint for RTMS events
- Server to receive WebSocket streams

> **Need RTMS access?** Post in [Zoom Developer Forum](https://devforum.zoom.us/) requesting RTMS access with your use case.

## Quick Start (SDK - Recommended)

```javascript
import rtms from "@zoom/rtms";

// All RTMS start/stop events across products
const RTMS_EVENTS = ["meeting.rtms_started", "webinar.rtms_started", "session.rtms_started"];

// Handle webhook events
rtms.onWebhookEvent(({ event, payload }) => {
  if (!RTMS_EVENTS.includes(event)) return;

  const client = new rtms.Client();

  client.onAudioData((data, timestamp, metadata) => {
    console.log(`Audio from ${metadata.userName}: ${data.length} bytes`);
  });

  client.onTranscriptData((data, timestamp, metadata) => {
    const text = data.toString('utf8');
    console.log(`${metadata.userName}: ${text}`);
  });

  client.onJoinConfirm((reason) => {
    console.log(`Joined session: ${reason}`);
  });

  // SDK handles all WebSocket connections automatically
  // Accepts both meeting_uuid and session_id transparently
  client.join(payload);
});
```

## Quick Start (Manual WebSocket)

For full control or non-SDK languages, implement the two-phase WebSocket protocol:

```javascript
const WebSocket = require('ws');
const crypto = require('crypto');

const RTMS_EVENTS = ['meeting.rtms_started', 'webinar.rtms_started', 'session.rtms_started'];

// 1. Generate signature
// For meetings/webinars: uses meeting_uuid. For Video SDK: uses session_id.
function generateSignature(clientId, idValue, streamId, clientSecret) {
  const message = `${clientId},${idValue},${streamId}`;
  return crypto.createHmac('sha256', clientSecret).update(message).digest('hex');
}

// 2. Handle webhook
app.post('/webhook', (req, res) => {
  res.status(200).send();  // CRITICAL: Respond immediately!
  
  const { event, payload } = req.body;
  if (RTMS_EVENTS.includes(event)) {
    connectToRTMS(payload);
  }
});

// 3. Connect to signaling WebSocket
function connectToRTMS(payload) {
  const { server_urls, rtms_stream_id } = payload;
  // meeting_uuid for meetings/webinars, session_id for Video SDK
  const idValue = payload.meeting_uuid || payload.session_id;
  const signature = generateSignature(CLIENT_ID, idValue, rtms_stream_id, CLIENT_SECRET);
  
  const signalingWs = new WebSocket(server_urls);
  
  signalingWs.on('open', () => {
    signalingWs.send(JSON.stringify({
      msg_type: 1,  // Handshake request
      protocol_version: 1,
      meeting_uuid: idValue,
      rtms_stream_id,
      signature,
      media_type: 9  // AUDIO(1) | TRANSCRIPT(8)
    }));
  });
  
  // ... handle responses, connect to media WebSocket
}
```

**See**: [Manual WebSocket Guide](examples/manual-websocket.md) for complete implementation.

## Media Type Bitmask

Combine types with bitwise OR:

| Type | Value | Description |
|------|-------|-------------|
| Audio | 1 | PCM audio samples |
| Video | 2 | H.264/JPG video frames |
| Screen Share | 4 | **Separate from video!** |
| Transcript | 8 | Real-time speech-to-text |
| Chat | 16 | In-meeting chat messages |
| All | 32 | All media types |

**Example**: Audio + Transcript = `1 | 8` = `9`

## Critical Gotchas

| Issue | Solution |
|-------|----------|
| **Only 1 connection allowed** | New connections kick out existing ones. Track active sessions! |
| **Respond 200 immediately** | If webhook delays, Zoom retries creating duplicate connections |
| **Heartbeat mandatory** | Respond to msg_type 12 with msg_type 13, or connection dies |
| **Reconnection is YOUR job** | RTMS doesn't auto-reconnect. Media keep-alive tolerance is now about **65s**; signaling remains around **60s** |
| **Transcript language drift** | Use `src_language` plus `enable_lid: false` when you want fixed-language transcription instead of automatic language switching |
| **Single participant video only** | `VIDEO_SINGLE_INDIVIDUAL_STREAM` supports one participant at a time. A new `VIDEO_SUBSCRIPTION_REQ` overrides the previous selection |
| **Graceful close is explicit now** | Use `STREAM_CLOSE_REQ` / `STREAM_CLOSE_RESP` when your backend wants to terminate the stream cleanly |

## Environment Variables

### SDK Environment Variables

```bash
# Required - Authentication
ZM_RTMS_CLIENT=your_client_id          # Zoom OAuth Client ID
ZM_RTMS_SECRET=your_client_secret      # Zoom OAuth Client Secret

# Optional - Webhook server
ZM_RTMS_PORT=8080                      # Default: 8080
ZM_RTMS_PATH=/webhook                  # Default: /

# Optional - Logging
ZM_RTMS_LOG_LEVEL=info                 # error, warn, info, debug, trace
ZM_RTMS_LOG_FORMAT=progressive         # progressive or json
ZM_RTMS_LOG_ENABLED=true
```

### Manual Implementation Variables

```bash
ZOOM_CLIENT_ID=your_client_id
ZOOM_CLIENT_SECRET=your_client_secret
ZOOM_SECRET_TOKEN=your_webhook_token   # For webhook validation
```

## Zoom App Setup

### For Meetings and Webinars (General App)

1. Go to [marketplace.zoom.us](https://marketplace.zoom.us) -> Develop -> Build App
2. Choose **General App** -> **User-Managed**
3. Features -> Access -> **Enable Event Subscription**
4. Add Events -> Search "rtms" -> Select:
   - `meeting.rtms_started`
   - `meeting.rtms_stopped`
   - `webinar.rtms_started` (if using webinars)
   - `webinar.rtms_stopped` (if using webinars)
5. Scopes -> Add Scopes -> Search "rtms" -> Add:
   - `meeting:read:meeting_audio`
   - `meeting:read:meeting_video`
   - `meeting:read:meeting_transcript`
   - `meeting:read:meeting_chat`
   - `webinar:read:webinar_audio` (if using webinars)
   - `webinar:read:webinar_video` (if using webinars)
   - `webinar:read:webinar_transcript` (if using webinars)
   - `webinar:read:webinar_chat` (if using webinars)

### For Video SDK (Video SDK App)

1. Go to [marketplace.zoom.us](https://marketplace.zoom.us) -> Develop -> Build App
2. Choose **Video SDK App**
3. Use your SDK Key and SDK Secret (not OAuth Client ID/Secret)
4. Add Events:
   - `session.rtms_started`
   - `session.rtms_stopped`

## Sample Repositories

### Official Samples

| Repository | Description |
|------------|-------------|
| [rtms-samples](https://github.com/zoom/rtms-samples) | RTMSManager, boilerplates, AI samples |
| [rtms-quickstart-js](https://github.com/zoom/rtms-quickstart-js) | JavaScript SDK quickstart |
| [rtms-quickstart-py](https://github.com/zoom/rtms-quickstart-py) | Python SDK quickstart |
| [rtms-sdk-cpp](https://github.com/zoom/rtms-sdk-cpp) | C++ SDK |
| [zoom-rtms](https://github.com/zoom/rtms) | Main SDK repository |

### AI Integration Samples

| Sample | Description |
|--------|-------------|
| [rtms-meeting-assistant-starter-kit](https://github.com/zoom/rtms-meeting-assistant-starter-kit) | AI meeting assistant with summaries |
| [arlo-meeting-assistant](https://github.com/zoom/arlo-meeting-assistant) | Production meeting assistant with DB |
| [videosdk-rtms-transcribe-audio](https://github.com/zoom/videosdk-rtms-transcribe-audio) | Whisper transcription |

## Complete Documentation

### Concepts
- **[Connection Architecture](concepts/connection-architecture.md)** - Two-phase WebSocket design
- **[Lifecycle Flow](concepts/lifecycle-flow.md)** - Webhook to streaming flow

### Examples
- **[SDK Quickstart](examples/sdk-quickstart.md)** - Using @zoom/rtms SDK
- **[Manual WebSocket](examples/manual-websocket.md)** - Raw protocol implementation
- **[RTMS Bot](examples/rtms-bot.md)** - Complete bot implementation guide
- **[AI Integration](examples/ai-integration.md)** - Transcription and analysis patterns

### References
- **[Media Types](references/media-types.md)** - Audio, video, transcript, chat, screen share
- **[Data Types](references/data-types.md)** - All enums and constants
- **[Connection](references/connection.md)** - WebSocket protocol details
- **[Webhooks](references/webhooks.md)** - Event subscription

### Troubleshooting
- **[Common Issues](troubleshooting/common-issues.md)** - FAQ and solutions

## Resources

- **Official docs**: https://developers.zoom.us/docs/rtms/
- **Data types**: https://developers.zoom.us/docs/rtms/data-types/
- **Media params**: https://developers.zoom.us/docs/rtms/media-parameter-definition/
- **Developer forum**: https://devforum.zoom.us/

---

**Need help?** Start with Integrated Index section below for complete navigation.

---

## Integrated Index

_This section was migrated from `SKILL.md`._

RTMS provides real-time access to live audio, video, transcript, chat, and screen share from Zoom meetings, webinars, and Video SDK sessions.

## Critical Positioning

Treat RTMS as a **backend service** for receiving and processing media streams.

- Backend role: ingest audio/video/share/chat/transcript, run AI/analytics, persist/forward data.
- Optional frontend role: Zoom App SDK or web dashboard that consumes processed stream data from backend transport (WebSocket/SSE/other).
- Kickoff model: backend waits for RTMS start webhook events, then starts stream processing.

Do not model RTMS as a frontend-only SDK.

## Quick Start Path

**If you're new to RTMS, follow this order:**

1. **Run preflight checks first** -> [RUNBOOK.md](RUNBOOK.md)
2. **Understand the architecture** -> [concepts/connection-architecture.md](concepts/connection-architecture.md)
   - Two-phase WebSocket: Signaling + Media
   - Why RTMS doesn't use bots

3. **Choose your approach** -> SDK or Manual
   - SDK (recommended): [examples/sdk-quickstart.md](examples/sdk-quickstart.md)
   - Manual WebSocket: [examples/manual-websocket.md](examples/manual-websocket.md)

4. **Understand the lifecycle** -> [concepts/lifecycle-flow.md](concepts/lifecycle-flow.md)
   - Webhook -> Signaling -> Media -> Streaming

5. **Configure media types** -> [references/media-types.md](references/media-types.md)
   - Audio, video, transcript, chat, screen share

6. **Troubleshoot issues** -> [troubleshooting/common-issues.md](troubleshooting/common-issues.md)
   - Connection problems, duplicate webhooks, missing data

---

## Documentation Structure

```
rtms/
├── SKILL.md                           # Main skill overview
├── SKILL.md                           # This file - navigation guide
│
├── concepts/                          # Core architectural patterns
│   ├── connection-architecture.md     # Two-phase WebSocket design
│   └── lifecycle-flow.md              # Webhook to streaming flow
│
├── examples/                          # Complete working code
│   ├── sdk-quickstart.md              # Using @zoom/rtms SDK
│   ├── manual-websocket.md            # Raw protocol implementation
│   ├── rtms-bot.md                    # Complete RTMS bot implementation
│   └── ai-integration.md              # Transcription and analysis
│
├── references/                        # Reference documentation
│   ├── media-types.md                 # Audio, video, transcript, chat, share
│   ├── data-types.md                  # All enums and constants
│   ├── connection.md                  # WebSocket protocol details
│   └── webhooks.md                    # Event subscription
│
└── troubleshooting/                   # Problem solving guides
    └── common-issues.md               # FAQ and solutions
```

---

## By Use Case

### I want to get meeting transcripts
1. [SDK Quickstart](examples/sdk-quickstart.md) - Fastest approach
2. [Media Types](references/media-types.md#transcript) - Transcript configuration
3. [AI Integration](examples/ai-integration.md) - Whisper, Deepgram, AssemblyAI

### I want to record meetings
1. [Media Types](references/media-types.md) - Audio + Video configuration
2. [SDK Quickstart](examples/sdk-quickstart.md) - Receiving media
3. [AI Integration](examples/ai-integration.md#audio-recording) - Gap-filled recording

### I want to build an AI meeting assistant
1. [AI Integration](examples/ai-integration.md) - Complete patterns
2. [SDK Quickstart](examples/sdk-quickstart.md) - Media ingestion
3. [Lifecycle Flow](concepts/lifecycle-flow.md) - Event handling

### I want to build a complete RTMS bot
1. [RTMS Bot](examples/rtms-bot.md) - **Complete implementation guide**
2. [Lifecycle Flow](concepts/lifecycle-flow.md) - Webhook to streaming flow
3. [Connection Architecture](concepts/connection-architecture.md) - Two-phase design

### I need full protocol control
1. [Manual WebSocket](examples/manual-websocket.md) - **START HERE**
2. [Connection Architecture](concepts/connection-architecture.md) - Two-phase design
3. [Data Types](references/data-types.md) - All message types and enums
4. [Connection](references/connection.md) - Protocol details

### I'm getting connection errors
1. [Common Issues](troubleshooting/common-issues.md) - Diagnostic checklist
2. [Connection Architecture](concepts/connection-architecture.md) - Verify flow
3. [Webhooks](references/webhooks.md) - Validation and timing

### I want to understand the architecture
1. [Connection Architecture](concepts/connection-architecture.md) - Two-phase WebSocket
2. [Lifecycle Flow](concepts/lifecycle-flow.md) - Complete flow diagram
3. [Data Types](references/data-types.md) - Protocol constants

---

## By Product

### I'm building for Zoom Meetings
- Standard RTMS setup. Webhook event: `meeting.rtms_started`. Uses General App with OAuth.
- Start with [SDK Quickstart](examples/sdk-quickstart.md) or [Manual WebSocket](examples/manual-websocket.md).

### I'm building for Zoom Webinars
- Same as meetings, but webhook event is `webinar.rtms_started`. Payload still uses `meeting_uuid` (NOT `webinar_uuid`).
- Add webinar scopes and event subscriptions. See [Webhooks](references/webhooks.md).
- Only **panelist** streams are confirmed available. Attendee streams may not be individual.

### I'm building for Zoom Video SDK
- Webhook event: `session.rtms_started`. Payload uses `session_id` (NOT `meeting_uuid`).
- Requires a **Video SDK App** with SDK Key/Secret (not OAuth Client ID/Secret).
- Once connected, the protocol is **identical** to meetings.
- See [Webhooks](references/webhooks.md) for payload details.

---

## Key Documents

### 1. Connection Architecture (CRITICAL)
**[concepts/connection-architecture.md](concepts/connection-architecture.md)**

RTMS uses **two separate WebSocket connections**:
- **Signaling WebSocket**: Authentication, control, heartbeats
- **Media WebSocket**: Actual audio/video/transcript data

### 2. SDK vs Manual (DECISION POINT)
**[examples/sdk-quickstart.md](examples/sdk-quickstart.md)** vs **[examples/manual-websocket.md](examples/manual-websocket.md)**

| SDK | Manual |
|-----|--------|
| Handles WebSocket complexity | Full protocol control |
| Automatic reconnection | DIY reconnection |
| Less code | More code |
| Best for most use cases | Best for custom requirements |

### 3. Critical Gotchas (MOST COMMON ISSUES)
**[troubleshooting/common-issues.md](troubleshooting/common-issues.md)**

1. **Respond 200 immediately** - Delayed webhook responses cause duplicates
2. **Only 1 connection per stream** - New connections kick out existing
3. **Heartbeat required** - Must respond to keep-alive or connection dies
4. **Track active sessions** - Prevent duplicate join attempts

---

## Key Learnings

### Critical Discoveries:

1. **Two-Phase WebSocket Design**
   - Signaling: Control plane (handshake, heartbeat, start/stop)
   - Media: Data plane (audio, video, transcript, chat, share)
   - See: [Connection Architecture](concepts/connection-architecture.md)

2. **Webhook Response Timing**
   - MUST respond 200 BEFORE any processing
   - Delayed response -> Zoom retries -> duplicate connections
   - See: [Common Issues](troubleshooting/common-issues.md#webhook-response-timing)

3. **Heartbeat is Mandatory**
   - Signaling: Receive msg_type 12, respond with msg_type 13
   - Media: Same pattern
   - Failure to respond = connection closed
   - See: [Connection](references/connection.md#heartbeat)

4. **Signature Generation**
   - Format: `HMAC-SHA256(clientSecret, "clientId,meetingUuid,streamId")`
   - For Video SDK, use `session_id` in place of `meetingUuid`
   - Webinars still use `meeting_uuid` (not `webinar_uuid`)
   - Required for both signaling and media handshakes
   - See: [Manual WebSocket](examples/manual-websocket.md#signature-generation)

5. **Media Types are Bitmasks**
   - Audio=1, Video=2, Share=4, Transcript=8, Chat=16, All=32
   - Combine with OR: Audio+Transcript = 1|8 = 9
   - See: [Media Types](references/media-types.md)

6. **Screen Share is SEPARATE from Video**
   - Different msg_type (16 vs 15)
   - Different media flag (4 vs 2)
   - Must subscribe separately
   - See: [Media Types](references/media-types.md#screen-share)

---

## Quick Reference

### "Connection fails"
-> [Common Issues](troubleshooting/common-issues.md)

### "Duplicate connections"
-> [Webhook timing](troubleshooting/common-issues.md#webhook-response-timing)

### "No audio/video data"
-> [Media Types](references/media-types.md) - Check configuration

### "How do I implement manually?"
-> [Manual WebSocket](examples/manual-websocket.md)

### "What message types exist?"
-> [Data Types](references/data-types.md)

### "How do I integrate AI?"
-> [AI Integration](examples/ai-integration.md)

---

## Document Version

Based on **Zoom RTMS SDK v1.x** and official documentation as of 2026.

---

**Happy coding!**

Remember: Start with [SDK Quickstart](examples/sdk-quickstart.md) for the fastest path, or [Manual WebSocket](examples/manual-websocket.md) if you need full control.$body$),
('marketplace:knowledge-work-plugins/knowledge-work-plugins/partner-built/zoom-plugin/skills/scribe', 'business', 'scribe', '', 'scribe', '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:knowledge-work-plugins', '', $body$# Zoom AI Services Scribe

Background reference for Zoom AI Services Scribe across:
- synchronous single-file transcription (`POST /aiservices/scribe/transcribe`)
- asynchronous batch jobs (`/aiservices/scribe/jobs*`)
- browser microphone pseudo-streaming via repeated short file uploads
- webhook-driven batch status updates
- Build-platform JWT generation and credential handling

Official docs:
- https://developers.zoom.us/docs/ai-services/
- https://developers.zoom.us/docs/ai-services/scribe/
- https://developers.zoom.us/docs/api/ai-services/
- https://developers.zoom.us/api-hub/ai-services/methods/endpoints.json
- Quickstart sample: https://github.com/zoom/scribe-quickstart/

## Routing Guardrail

- If the user needs **uploaded or stored media transcribed into text**, route here first.
- If the user needs **live meeting media** without file-based upload/batch jobs, route to [../rtms/SKILL.md](../rtms/SKILL.md).
- If the user needs **Zoom REST API inventory** for AI Services paths, chain [../rest-api/SKILL.md](../rest-api/SKILL.md).
- If the user needs webhook signature patterns or generic HMAC receiver hardening, optionally chain [../webhooks/SKILL.md](../webhooks/SKILL.md).

## Quick Links

1. [concepts/auth-and-processing-modes.md](concepts/auth-and-processing-modes.md)
2. [scenarios/high-level-scenarios.md](scenarios/high-level-scenarios.md)
3. [examples/fast-mode-node.md](examples/fast-mode-node.md)
4. [examples/batch-webhook-pipeline.md](examples/batch-webhook-pipeline.md)
5. [references/api-reference.md](references/api-reference.md)
6. [references/environment-variables.md](references/environment-variables.md)
7. [references/samples-validation.md](references/samples-validation.md)
8. [references/versioning-and-drift.md](references/versioning-and-drift.md)
9. [troubleshooting/common-drift-and-breaks.md](troubleshooting/common-drift-and-breaks.md)
10. [RUNBOOK.md](RUNBOOK.md)

## Core Workflow

1. Get Build-platform credentials and generate an HS256 JWT.
2. Choose **fast mode** for one short file or **batch mode** for stored archives / large sets.
3. Submit the transcription request.
4. For batch jobs, poll job/file status or receive webhook notifications.
5. Persist and post-process transcript JSON.

## Hosted Fast-Mode Guardrail

- The formal fast-mode API limits are `100 MB` and `2 hours`, but hosted browser flows can still time out before the upstream response returns.
- Current deployed-sample observations:
  - ~17.2 MB MP4 completed in about `26s`
  - ~38.6 MB MP4 completed in about `26-37s`
  - ~59.2 MB MP4 completed in about `32-34s` on the backend
  - some ~59.2 MB browser requests still surfaced as frontend `504` while backend logs later showed `200`
- Treat frontend `504` plus backend `200` as a browser/edge timeout race, not an automatic transcription failure.
- For hosted UIs, prefer an async request/polling wrapper for fast mode instead of holding the browser open for the full upstream response.
- For larger or less predictable media, prefer batch mode even when the file is still within the formal fast-mode size limit.

## Browser Microphone Pattern

- `scribe` does not expose a documented real-time streaming API surface.
- If you want a browser microphone experience, use pseudo-streaming:
  1. capture microphone audio in short chunks
  2. upload each chunk through the async fast-mode wrapper
  3. poll for completion
  4. append chunk transcripts in sequence
- Recommended starting cadence:
  - chunk size: `5 seconds`
  - acceptable range: `5-10 seconds`
  - in-flight chunk requests: `2-3`
- This is a practical UI pattern for incremental transcript updates, not a substitute for `rtms`.
- Treat this as a fallback demo pattern, not the preferred production architecture.
- It adds repeated upload overhead, chunk-boundary drift, browser codec/container variability, and transcript stitching complexity.
- If the user asks for actual live stream ingestion, low-latency continuous media, or server-push media transport, route to [../rtms/SKILL.md](../rtms/SKILL.md) instead.

## Endpoint Surface

| Mode | Method | Path | Use |
|------|--------|------|-----|
| Fast | `POST` | `/aiservices/scribe/transcribe` | Synchronous transcription for one file |
| Batch | `POST` | `/aiservices/scribe/jobs` | Submit asynchronous batch job |
| Batch | `GET` | `/aiservices/scribe/jobs` | List jobs |
| Batch | `GET` | `/aiservices/scribe/jobs/{jobId}` | Inspect job summary/state |
| Batch | `DELETE` | `/aiservices/scribe/jobs/{jobId}` | Cancel queued/processing job |
| Batch | `GET` | `/aiservices/scribe/jobs/{jobId}/files` | Inspect per-file results |

## High-Level Scenarios

- On-demand clip transcription after a user uploads one recording.
- Batch transcription of stored S3 call archives.
- Webhook-driven ETL pipeline that writes transcripts to your database/search index.
- Re-transcription of Zoom-managed recordings after exporting them to your own storage.
- Offline compliance or QA workflows that need timestamps, channel separation, and speaker hints.

## Chaining

- Stored Zoom recordings -> [../rest-api/SKILL.md](../rest-api/SKILL.md) + `scribe`
- Webhook verification hardening -> [../webhooks/SKILL.md](../webhooks/SKILL.md)
- Real-time live transcript/media -> [../rtms/SKILL.md](../rtms/SKILL.md)
- Cross-product routing -> [../general/SKILL.md](../general/SKILL.md)

## Operations

- [RUNBOOK.md](RUNBOOK.md) - 5-minute preflight and debugging checklist.$body$)
ON CONFLICT (skill_key) DO NOTHING;
