# Wild Pairs — Permission Audit

> *Canonical sources: for data models, `technical-architecture.md` §Model Reference is canonical. For game rules, `game-rules.md`. For visual tokens, `design-system.md`. Where this document disagrees with its canonical source, the canonical source wins.*

> Last updated: 2026-06-21  
> Status: Living document — update whenever new features are added that might require permissions.

---

## TL;DR

Wild Pairs requires **zero runtime permissions** for all gameplay features.

- No permission prompt ever appears during normal gameplay.
- No protected-resource usage description keys appear in `Info.plist`.
- No entitlements beyond simulator code-signing defaults are enabled.
- No background modes are enabled.
- No network APIs are in source.

This is by design and must be preserved. Any future feature proposal that requires a runtime permission must go through explicit product and privacy review before implementation.

---

## 1. Runtime Permissions — Complete Assessment

The following table covers every iOS protected resource permission. For each, the current status is "Not used" along with the reason.

| Permission | Status | Reason not needed |
|---|---|---|
| **Camera** | Not used | No photo capture, no QR scanning, no augmented reality |
| **Microphone** | Not used | No audio input, no speech recognition, no voice chat |
| **Photo Library (read)** | Not used | No photo import feature |
| **Photo Library (write)** | Not used | No screenshot-to-library feature, no card export |
| **Location (when in use)** | Not used | Offline card game; no location-based features |
| **Location (always)** | Not used | Same as above; no background location |
| **Precise Location** | Not used | Same as above |
| **Contacts** | Not used | No player roster linked to contacts, no social features |
| **Calendars** | Not used | No event scheduling, no reminder features |
| **Reminders** | Not used | Same as above |
| **Bluetooth** | Not used | No wireless multiplayer, no external accessories, no beacons |
| **Local Network** | Not used | No peer-to-peer discovery, no Bonjour, no LAN multiplayer |
| **Push Notifications** | Not used | No server-side events, no alerts, no badges requiring permission |
| **Face ID / Touch ID (LocalAuthentication)** | Not used | No authentication, no secure enclave access |
| **Speech Recognition** | Not used | No voice command, no dictation |
| **HealthKit** | Not used | No health or fitness data |
| **HomeKit** | Not used | No smart home integration |
| **App Tracking Transparency** | Not used | No user tracking, no advertising, no cross-app data sharing |
| **CoreMotion (step count, activity)** | Not used | No fitness tracking; standard device orientation via UIKit does not require permission |
| **Media Library / Music** | Not used | No music playback from user library; any in-game audio uses bundled assets |
| **Siri / Shortcuts** | Not used | No voice shortcuts, no SiriKit integration |
| **NFC** | Not used | No NFC reading or writing |
| **Motion & Fitness (CMMotionActivityManager)** | Not used | Not accessed |
| **Crash Reporting / Diagnostics** | Not used | No third-party crash SDK; OS crash reports managed by Apple under user's existing consent |

### Verification

```bash
# Check Info.plist for any usage description keys (there should be none)
grep -E "UsageDescription" WildPairsApp/Info.plist
# Expected: no output

# Check source for permission-requesting API calls
grep -rE \
  "requestAccess|requestPermission|requestAuthorization|AVCaptureDevice\.requestAccess\|CLLocationManager|CNContactStore|EKEventStore|CBCentralManager|UNUserNotificationCenter\.current\(\)\.requestAuthorization|ATTrackingManager|CMMotionActivityManager|HKHealthStore|INPreferences" \
  WildPairsCore/Sources/ WildPairsApp/ --include="*.swift"
# Expected: no matches
```

---

## 2. Info.plist Required Keys

The `Info.plist` contains only the minimum keys required for a Universal iOS app. No protected-resource usage description keys are present.

### Required keys

| Key | Value | Purpose |
|---|---|---|
| `CFBundleDisplayName` | `WildPairs` | App name shown under icon |
| `CFBundleIdentifier` | `com.wildpairs.app` | App bundle ID (adjust to actual) |
| `CFBundleVersion` | (build number) | Build number |
| `CFBundleShortVersionString` | (version string) | User-facing version |
| `UIApplicationSceneManifest` | Standard scene config | Enables multi-window scene lifecycle |
| `UISupportedInterfaceOrientations` | Portrait + all landscape | Full rotation support on iPhone |
| `UISupportedInterfaceOrientations~ipad` | All orientations | Full rotation support on iPad |
| `UILaunchScreen` | Standard storyboard or SwiftUI | Required by App Store |
| `UIDeviceFamily` | `[1, 2]` | iPhone (1) + iPad (2) — Universal |
| `MinimumOSVersion` | `17.0` | iOS 17.0 deployment target |
| `LSRequiresIPhoneOS` | `true` | iOS-only (not macOS Catalyst) |

### Explicitly absent keys (and why)

| Key | Why absent |
|---|---|
| `NSCameraUsageDescription` | Camera not used |
| `NSMicrophoneUsageDescription` | Microphone not used |
| `NSPhotoLibraryUsageDescription` | Photo library not used |
| `NSPhotoLibraryAddUsageDescription` | Photo library not used |
| `NSLocationWhenInUseUsageDescription` | Location not used |
| `NSLocationAlwaysUsageDescription` | Location not used |
| `NSContactsUsageDescription` | Contacts not used |
| `NSCalendarsUsageDescription` | Calendars not used |
| `NSRemindersUsageDescription` | Reminders not used |
| `NSBluetoothAlwaysUsageDescription` | Bluetooth not used |
| `NSBluetoothPeripheralUsageDescription` | Bluetooth not used |
| `NSLocalNetworkUsageDescription` | Local network not used |
| `NSFaceIDUsageDescription` | Face ID not used |
| `NSSpeechRecognitionUsageDescription` | Speech recognition not used |
| `NSHealthShareUsageDescription` | HealthKit not used |
| `NSHealthUpdateUsageDescription` | HealthKit not used |
| `NSHomeKitUsageDescription` | HomeKit not used |
| `NSMotionUsageDescription` | CoreMotion not used |
| `NSAppleMusicUsageDescription` | Media library not used |
| `NSSiriUsageDescription` | Siri not used |
| `NFCReaderUsageDescription` | NFC not used |
| `NSUserTrackingUsageDescription` | ATT not used; no tracking |

### Info.plist validation

```bash
# Confirm no usage description keys are present
plutil -p WildPairsApp/Info.plist | grep -i "UsageDescription"
# Expected: no output

# Confirm file is valid XML
plutil -lint WildPairsApp/Info.plist
# Expected: WildPairsApp/Info.plist: OK
```

---

## 3. Entitlements

### 3.1 Expected entitlements — simulator development

For simulator builds (no Apple Developer account required), Xcode assigns automatic code-signing entitlements. The expected `.entitlements` file contains only:

| Entitlement | Value | Notes |
|---|---|---|
| `application-identifier` | `$(AppIdentifierPrefix)$(CFBundleIdentifier)` | Auto-set by Xcode |
| `get-task-allow` | `true` | Debug only; removed in release builds |

### 3.2 Expected entitlements — personal team device build

For device builds using a free personal Apple ID team:

| Entitlement | Value | Notes |
|---|---|---|
| `application-identifier` | `$(AppIdentifierPrefix)$(CFBundleIdentifier)` | Auto-set by Xcode |
| `get-task-allow` | `true` | Debug only |

### 3.3 Entitlements that must NOT be present

The following entitlements must not appear unless a specific approved feature explicitly requires them:

| Entitlement | Risk if wrongly present |
|---|---|
| `com.apple.developer.icloud-container-identifiers` | Enables iCloud — contradicts offline-only design |
| `com.apple.developer.ubiquity-kvstore-identifier` | iCloud key-value store |
| `com.apple.developer.associated-domains` | Universal links / Sign in with Apple |
| `aps-environment` | Push notifications |
| `com.apple.security.application-groups` | App Groups / widget data sharing |
| `com.apple.developer.healthkit` | HealthKit |
| `com.apple.developer.homekit` | HomeKit |
| `com.apple.developer.pass-type-identifiers` | Wallet / Apple Pay |
| `com.apple.developer.game-center` | Game Center |
| `com.apple.developer.siri` | Siri / Shortcuts |
| `keychain-access-groups` | Shared keychain |
| `com.apple.developer.networking.network-extension` | VPN / network extension |
| `com.apple.developer.networking.HotspotConfiguration` | Hotspot configuration |
| `com.apple.developer.nearby-interaction` | Nearby Interaction |
| `com.apple.developer.in-app-payments` | In-App Purchase |

### 3.4 Entitlements verification

```bash
# List entitlements from a built app (simulator)
# Replace path with actual DerivedData path after building
codesign -d --entitlements - \
  ~/Library/Developer/Xcode/DerivedData/WildPairs-*/Build/Products/Debug-iphonesimulator/WildPairs.app

# Expected output contains only: application-identifier, get-task-allow
```

---

## 4. Xcode Capabilities

### 4.1 Current capabilities — none beyond defaults

In Xcode's Signing & Capabilities tab for the `WildPairsApp` target, only the following should be present:

- The default signing configuration (Team, Bundle Identifier, automatic signing)

No additional capability tiles should be added.

### 4.2 Capabilities to never enable (unless explicitly approved)

| Capability | Why to avoid |
|---|---|
| Push Notifications | Requires APS entitlement; no server needed |
| iCloud | Contradicts offline-only data model |
| CloudKit | Same |
| App Groups | Widens sandbox; no widget or extension planned |
| Associated Domains | Universal links / Sign in with Apple not needed |
| Background Modes | No background execution needed; game state saved on background transition |
| HealthKit | Not relevant |
| HomeKit | Not relevant |
| Wallet | Not relevant |
| Apple Pay | Not relevant |
| Siri | Not relevant |
| Maps | Not relevant |
| Game Center | No leaderboards, no achievements; contradicts offline-first |
| Keychain Sharing | No cross-app data to share |
| Network Extensions | No VPN or content filter |
| Hotspot Configuration | Not relevant |
| Nearby Interaction | No proximity feature planned |
| Inter-App Audio | Not relevant |
| Sign in with Apple | No account system |
| In-App Purchase | Free app; no IAP planned |
| CoreML Models | Not relevant |
| Access WiFi Information | Not relevant |

### 4.3 Verification in Xcode

1. Open the project in Xcode.
2. Select the `WildPairsApp` target.
3. Click "Signing & Capabilities".
4. Confirm no capability tiles beyond the default signing section are present.

---

## 5. Background Modes

### 5.1 Current status: none

No background modes are enabled. The `UIBackgroundModes` key is absent from `Info.plist`.

### 5.2 Behaviour when app enters background

When the user presses the home button or switches apps:

1. `sceneDidEnterBackground(_:)` is called.
2. The game state is saved synchronously to `wildpairs-game.json`.
3. The app suspends. No background task is requested.

### 5.3 Background modes that must NOT be enabled

| Mode | `Info.plist` value | Risk if wrongly enabled |
|---|---|---|
| Audio | `audio` | App plays audio when backgrounded — App Store rejection risk |
| Location updates | `location` | Background location — requires Always permission |
| Voip | `voip` | Legacy VoIP — not applicable |
| Newsstand downloads | `newsstand-content` | Not applicable |
| External accessory communication | `external-accessory` | Not applicable |
| Bluetooth central | `bluetooth-central` | Background Bluetooth |
| Bluetooth peripheral | `bluetooth-peripheral` | Background Bluetooth |
| Background fetch | `fetch` | Triggers periodic background launches — no server to fetch from |
| Remote notifications | `remote-notification` | Silent push — requires APN setup |
| Processing | `processing` | BGProcessingTask — no long-running background work needed |

---

## 6. App Sandbox

Wild Pairs runs in the standard iOS app sandbox. No additional sandbox exceptions are required or enabled.

The app's data directory is:

```
<app-sandbox>/Documents/
  wildpairs-game.json
  wildpairs-settings.json
  wildpairs-stats.json
```

The app does not attempt to access files outside its own sandbox. It does not use shared containers, iCloud containers, or group containers.

---

## 7. Verification Procedures

### 7.1 Automated checks

```bash
#!/usr/bin/env bash
# scripts/check_permissions_minimal.sh
# Verifies Info.plist contains no protected-resource usage description keys.

set -euo pipefail

PLIST="WildPairsApp/Info.plist"

echo "Checking $PLIST for usage description keys..."

USAGE_KEYS=$(plutil -p "$PLIST" | grep -i "UsageDescription" || true)

if [ -z "$USAGE_KEYS" ]; then
  echo "PASS: No usage description keys found in Info.plist."
else
  echo "FAIL: Usage description keys found (should be absent):"
  echo "$USAGE_KEYS"
  exit 1
fi

echo "PASS: Permission check complete."
```

```bash
#!/usr/bin/env bash
# scripts/check_project_capabilities.sh
# Verifies .entitlements file contains only expected keys.

set -euo pipefail

ENTITLEMENTS=$(find WildPairsApp -name "*.entitlements" | head -1)

if [ -z "$ENTITLEMENTS" ]; then
  echo "INFO: No .entitlements file found (simulator builds may not have one)."
  exit 0
fi

echo "Checking $ENTITLEMENTS..."

UNEXPECTED=$(plutil -p "$ENTITLEMENTS" | grep -vE \
  "application-identifier|get-task-allow|keychain-access-groups|com\.apple\.developer\.team-identifier" \
  || true)

if [ -z "$UNEXPECTED" ]; then
  echo "PASS: Only expected entitlements found."
else
  echo "WARNING: Unexpected entitlements detected — review required:"
  echo "$UNEXPECTED"
fi
```

### 7.2 Manual verification checklist

Run this checklist at each phase gate:

- [ ] Launch app on iPhone simulator → play 5 turns → confirm zero permission prompts appeared
- [ ] Launch app on iPad simulator → play 5 turns → confirm zero permission prompts appeared
- [ ] Enable Airplane Mode → launch app → play full game → confirm zero network-related errors
- [ ] Review Info.plist: confirm no `UsageDescription` keys present
- [ ] Review Signing & Capabilities in Xcode: confirm no capability tiles beyond signing
- [ ] Run `scripts/check_permissions_minimal.sh` → PASS
- [ ] Run `scripts/check_project_capabilities.sh` → PASS or no unexpected entries
- [ ] Review `.entitlements` file: confirm only `application-identifier` and `get-task-allow`

---

## 8. Audit History

| Date | Phase | Finding | Status |
|---|---|---|---|
| 2026-06-22 | Phase 5 — App build (G6 quality gate) | `check_no_network_usage.sh` flagged `SettingsView.swift:80` for the keyword "tracking" in the empty-stats placeholder copy: `"Play a round to start tracking your stats."` | Pass — false positive. This refers to local `GameStats` (round/win counts persisted to `wildpairs-stats.json`), not analytics/ad tracking. No `UIUserTrackingUsageDescription`, no `AppTrackingTransparency`, no network code anywhere in the scan paths. No action needed. |

> Add a row here after each formal permission audit. Columns: Date of audit, development phase (e.g. "Phase 3 — Game Engine"), finding (e.g. "No permissions required"), status (e.g. "Pass — no action").
