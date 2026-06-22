# Wild Pairs — Enterprise Build Notes

> *Canonical sources: for data models, `technical-architecture.md` §Model Reference is canonical. For game rules, `game-rules.md`. For visual tokens, `design-system.md`. Where this document disagrees with its canonical source, the canonical source wins.*

> Last updated: 2026-06-21  
> Audience: Developers building this project in an enterprise-managed macOS environment.

---

## TL;DR

- Build on a Mac with Xcode 15+ (free from Mac App Store)
- Simulator builds require no Apple Developer account
- Zero external dependencies — `swift build` makes no network calls
- Zero special entitlements or capabilities needed
- All source is written on Windows (Claude Code) and built on macOS

---

## 1. Prerequisites

### Required software

| Tool | Version | Source | Cost |
|---|---|---|---|
| macOS | 14.0 (Sonoma) or later | Apple Software Update | Free |
| Xcode | 15.0 or later | Mac App Store | Free |
| Swift | Bundled with Xcode 15 | — | Free |

### Not required

| Tool | Why not needed |
|---|---|
| Homebrew | No build-time tools from Homebrew |
| CocoaPods | No CocoaPods dependencies |
| Carthage | No Carthage dependencies |
| Ruby / Bundler | No Ruby build scripts |
| Node.js / npm | No JavaScript tooling |
| Python | No Python build scripts |
| Apple Developer account | Not needed for simulator builds |
| Internet connection | Not needed after Xcode is installed; no remote SPM dependencies |

### Confirming Xcode installation

```bash
# Confirm Xcode command-line tools are active
xcode-select -p
# Expected: /Applications/Xcode.app/Contents/Developer

# Confirm Swift version
swift --version
# Expected: swift-driver version: ... Swift version 5.9 (or later)

# Confirm xcodebuild is available
xcodebuild -version
# Expected: Xcode 15.x.x (or later)
```

If `xcode-select -p` returns `/Library/Developer/CommandLineTools`, run:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

---

## 2. Repository Layout

```
WildPairs/
├── Package.swift                  # WildPairsCore Swift Package manifest
├── WildPairsCore/
│   └── Sources/
│       └── WildPairsCore/         # Core game engine (no UIKit/SwiftUI)
├── WildPairsApp/
│   ├── WildPairsApp.xcodeproj/    # Xcode project (create on macOS)
│   └── WildPairsApp/              # SwiftUI app target sources
├── docs/                          # Project documentation
└── scripts/                       # Verification shell scripts
```

The `WildPairsApp.xcodeproj` is created on macOS and committed to the repository. Source files in `WildPairsCore/` and `WildPairsApp/WildPairsApp/` are edited on Windows via Claude Code and built on macOS.

---

## 3. First-Time Setup

Follow these steps in order on a Mac.

### Step 1 — Get the source

GitHub is the source-sync mechanism between the Windows editing machine and this Mac. **Do not use OneDrive to copy source files** — OneDrive conflict copies and casing differences have caused sync issues; see `docs/git-workflow.md`.

```bash
git clone https://github.com/alastairlivingston-sudo/wild-pairs.git WildPairs
cd WildPairs
```

If a copy already exists from a previous OneDrive sync, wire it to GitHub instead of re-cloning:

```bash
cd ~/Developer/WildPairs
git remote add origin https://github.com/alastairlivingston-sudo/wild-pairs.git
git fetch origin
git checkout -B main origin/main
```

Always run `git pull --ff-only` before starting work on this machine. See `docs/git-workflow.md` for the full branch strategy and daily workflow.

### Step 2 — Verify the Swift Package builds

```bash
cd ~/Developer/WildPairs
swift build
```

Expected output: build succeeds with no errors. This confirms `WildPairsCore` is correctly structured as a Swift Package.

If this step fails, do not proceed to Xcode. Fix the compilation errors first.

### Step 3 — Create the Xcode project (first time only)

If `WildPairsApp/WildPairsApp.xcodeproj` does not yet exist:

1. Open Xcode.
2. File → New → Project.
3. Select **iOS** → **App** → Next.
4. Configure:
   - **Product Name:** `WildPairs`
   - **Team:** None (for simulator) or personal Apple ID team
   - **Organization Identifier:** `com.wildpairs` (or your preferred reverse-DNS)
   - **Bundle Identifier:** `com.wildpairs.app`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Include Tests:** Yes
5. Save to `WildPairs/WildPairsApp/` (so the `.xcodeproj` is at `WildPairs/WildPairsApp/WildPairsApp.xcodeproj`).

### Step 4 — Add WildPairsCore as a local Swift Package dependency

1. In Xcode, with `WildPairsApp` project open.
2. File → Add Package Dependencies.
3. Click "Add Local..." at the bottom of the dialog.
4. Navigate to the `WildPairs/` directory (the root, where `Package.swift` is located).
5. Click "Add Package".
6. In the "Choose Package Products" dialog, add `WildPairsCore` to the `WildPairsApp` target.
7. Click "Add Package".

Confirm in the Project Navigator that `WildPairsCore` appears under "Package Dependencies".

### Step 5 — Configure deployment target and device family

1. Select the `WildPairsApp` project in the Project Navigator.
2. Select the `WildPairsApp` target.
3. General tab:
   - **Deployment Info → iOS:** `17.0`
   - **Deployment Info → iPhone:** checked
   - **Deployment Info → iPad:** checked
   - **Device Orientation:** Portrait, Landscape Left, Landscape Right (for both device families)

### Step 6 — Remove unneeded capabilities

1. Select the `WildPairsApp` target → Signing & Capabilities tab.
2. Confirm no capability tiles are present beyond the default signing section.
3. If any capability tile was auto-added, click the `—` button to remove it.

### Step 7 — Add PrivacyInfo.xcprivacy

1. Copy `WildPairsApp/PrivacyInfo.xcprivacy` from the repository (if it exists) into the Xcode project, or create it:
   - File → New → File → Resource → Property List
   - Name it `PrivacyInfo`
   - Change the file type from generic Property List to Privacy Manifest (use the template in `docs/privacy-offline-plan.md`)
2. Ensure `PrivacyInfo.xcprivacy` is a member of the `WildPairsApp` target (not the test target).

### Step 8 — Build and run on simulator

1. Select a simulator: **iPhone 15** (or any iOS 17+ simulator).
2. Product → Build (⌘B). Confirm zero errors.
3. Product → Run (⌘R). App launches in simulator.
4. Play through a few turns. Confirm no errors in the Xcode console.

---

## 4. Building for iPhone Simulator

```bash
xcodebuild build \
  -scheme WildPairs \
  -project WildPairsApp/WildPairsApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

Expected: `** BUILD SUCCEEDED **`

> `CODE_SIGN_IDENTITY=""` and `CODE_SIGNING_REQUIRED=NO` allow building for simulator without a provisioning profile. Omit these flags when building for a physical device.

---

## 5. Building for iPad Simulator

```bash
xcodebuild build \
  -scheme WildPairs \
  -project WildPairsApp/WildPairsApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPad Air (5th generation),OS=latest' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

Expected: `** BUILD SUCCEEDED **`

---

## 6. Running Tests

### Swift Testing runtime requirement (KI-028)

`WildPairsTests` uses the Swift Testing framework (`import Testing`). On a machine with **only the Command Line Tools** (no `Xcode.app`), `Testing.framework` and `lib_TestingInterop.dylib` ship inside the active developer dir but are **not** on the default dyld search paths, so a bare `swift test` fails with `error: no such module 'Testing'`.

Use the wrapper, which derives the framework search path and runtime rpaths from `xcode-select -p` and works on both Command-Line-Tools-only and full-Xcode machines:

```bash
# Canonical, portable test command — works with CLT only or full Xcode
./scripts/swift_test.sh

# Pass-through args are forwarded to `swift test`
./scripts/swift_test.sh --filter EngineTests
./scripts/swift_test.sh --verbose
```

Bare `swift test` (below) works **only once full Xcode is installed** (`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`). The library target builds fine either way: `swift build` / `swift build --target WildPairsCore` need no wrapper.

### Swift Package unit tests (no Xcode project needed)

```bash
# Build the pure-logic library (no wrapper needed)
swift build --target WildPairsCore

# Run all tests in WildPairsCore (requires full Xcode; otherwise use the wrapper above)
swift test --package-path .

# Run a specific test target
swift test --package-path . --filter WildPairsTests

# Run with verbose output (shows individual test names)
swift test --package-path . --verbose

# Run with a specific filter (Swift Testing)
swift test --package-path . --filter "testHumanHasNoValidCardMustDraw"
```

### Xcode scheme tests (includes UI tests)

```bash
xcodebuild test \
  -scheme WildPairs \
  -project WildPairsApp/WildPairsApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### Simulation balance tests (slower suite)

```bash
# Run only the balance simulation tests
swift test --package-path . --filter BalanceSimulationTests --verbose
```

Balance tests may take several minutes. Run these at phase gates, not in pre-commit.

---

## 7. Physical Device Deployment (Optional)

Physical device deployment is optional. All development and testing can be done in the simulator.

### Requirements for device deployment

- Apple ID (a free personal team is sufficient; no paid developer programme needed for sideloading)
- USB connection between Mac and device, or wireless pairing

### Steps

1. Open the project in Xcode.
2. Select the `WildPairsApp` target → Signing & Capabilities.
3. Under "Signing":
   - Check "Automatically manage signing".
   - Select your personal Apple ID team from the Team dropdown. If your Apple ID is not listed, add it via Xcode → Settings → Accounts.
4. Connect your iPhone or iPad via USB.
5. On the device, trust the Mac when prompted.
6. Select the physical device from the scheme selector in the toolbar.
7. Product → Run (⌘R).
8. On first install, the device may prompt: Settings → General → VPN & Device Management → trust your developer certificate.

### Notes

- No provisioning profiles need to be manually downloaded; Xcode manages them.
- No special entitlements are needed beyond what Xcode assigns automatically.
- The app is sideloaded (not submitted to the App Store).
- Free personal team apps expire after 7 days and must be reinstalled. Paid developer programme apps are valid for 1 year.
- No internet connection is required at runtime; only at initial code-signing if Xcode needs to register the device with Apple.

---

## 8. Enterprise Environment Friction Points

### Code signing errors

**Symptom:** "No signing certificate found" or "Provisioning profile doesn't include the currently selected device."

**Fix:**
- For simulator: add `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` to the `xcodebuild` command.
- For device: ensure "Automatically manage signing" is checked and a valid Team is selected.
- Do not attempt to manually manage provisioning profiles unless your organisation requires it.

---

### Gatekeeper blocks Xcode

**Symptom:** macOS blocks Xcode or command-line tools from running.

**Fix:** Xcode installed from the Mac App Store is notarized by Apple. If Gatekeeper still blocks it, the issue is likely an MDM policy. Contact IT. Do not attempt to bypass Gatekeeper with `spctl --disable`.

---

### Firewall blocks `swift build` / package resolution

**Symptom:** `swift build` hangs or fails with a network error.

**Analysis:** Wild Pairs has zero remote Swift Package dependencies. `swift build` should make no network calls. If it does:
- Check whether Xcode automatically fetched any unexpected packages. Review `Package.resolved`.
- If the project has no remote dependencies and `swift build` still makes network calls, this may be a macOS telemetry or Xcode update check. These are not required for the build to succeed — disable network and retry.

**Fix:** There are no remote dependencies. If `swift build` fails with a network error, it is not because a package download failed. Check for compilation errors instead.

---

### MDM restrictions on simulators

**Symptom:** Simulator cannot be launched; Xcode reports "Unable to boot device."

**Analysis:** Some enterprise MDM policies restrict simulator usage.

**Fix:** Most MDM policies allow Xcode simulator development for recognised development tools. If blocked, raise a request with IT citing: "Need Xcode iOS Simulator access for local app development — no network access, no external services."

---

### Enterprise certificate conflicts

**Symptom:** Xcode selects an enterprise distribution certificate instead of a development certificate, causing code signing to fail for local builds.

**Fix:** In Signing & Capabilities, explicitly select "Automatically manage signing" and select a personal team (Apple ID). This bypasses enterprise certificate selection for local simulator development.

---

### MDM blocks physical device trust

**Symptom:** iPhone connected to Mac shows "Not Trusted" and cannot be trusted through Settings.

**Fix:** This is an MDM restriction. Use simulator builds only; physical device deployment is optional. Escalate to IT only if physical device testing is specifically required.

---

## 9. Claude Code Permission Posture

Claude Code runs on Windows and performs the following operations on the repository:

| Operation type | What Claude Code does | Network involved? |
|---|---|---|
| Read files | Reads `.swift`, `.md`, `.json`, `.plist` files within the repo | No |
| Write files | Creates or edits files within the repo directory | No |
| Bash commands | Runs `ls`, `grep`, `find` within the repo; reads directory listings | No |
| Git commands | `git status`, `git diff`, `git log`, `git add`, `git commit` | No (unless pushing) |
| Build commands | Does NOT run `xcodebuild` or `swift build` from Windows; these must be run manually on Mac | — |

Claude Code does **not**:
- Run `sudo` or any elevated-privilege command
- Install packages or modify system configuration
- Make outbound network requests from the build host
- Access files outside the repository directory
- Run build or test commands automatically (all build commands in this document are run manually on Mac)

### Approving Claude Code commands

If Claude Code requests permission to run a shell command, assess it by this checklist:

- [ ] Is it a read-only command (ls, grep, find, cat) within the repo? → Allow.
- [ ] Is it a git command (status, diff, log, add, commit)? → Allow.
- [ ] Is it a file write within the repo? → Allow.
- [ ] Does it reference `sudo`? → Do not allow without explicit user instruction.
- [ ] Does it reference `npm install`, `brew install`, or any package manager install? → Do not allow; there are no build-time dependencies to install.
- [ ] Does it reference a path outside the WildPairs repo directory? → Do not allow without review.

See `CLAUDE.md` for the current approved command list.

---

## 10. Capabilities to Never Enable

The following Xcode capabilities must not be added to the `WildPairsApp` target unless a specific, approved feature requires them. Each would change the app's permission footprint, entitlements, or privacy manifest requirements.

| Capability | Reason to avoid |
|---|---|
| Push Notifications | Requires APNs entitlement; no server-side events in this app |
| iCloud | Contradicts offline-only data model; adds entitlement and privacy manifest requirements |
| CloudKit | Same as iCloud |
| App Groups | Widens sandbox; no widget or extension planned |
| Associated Domains | Universal links or Sign in with Apple not planned |
| Background Modes | No background execution needed; contradicts minimal-permission posture |
| HealthKit | Not relevant |
| HomeKit | Not relevant |
| Wallet | Not relevant |
| Apple Pay | Free app; no payments |
| Siri | No voice integration planned |
| Maps | Not relevant |
| Game Center | No leaderboards or achievements; contradicts offline-first |
| Keychain Sharing | No cross-app secrets |
| Network Extensions | No VPN or content filter |
| Hotspot Configuration | Not relevant |
| Nearby Interaction | No proximity feature |
| Inter-App Audio | Not relevant |
| Sign in with Apple | No account system |
| In-App Purchase | Free app |
| CoreML Models (on-device) | Not currently planned; assess if AI model added |
| Access WiFi Information | Not relevant |

---

## 11. What Triggers Enterprise Security Prompts

Understanding what triggers enterprise security tooling helps prevent false positives and unnecessary IT escalations.

| Trigger | Does this app do it? | Notes |
|---|---|---|
| Outbound network request | No | Zero network calls at runtime |
| Installation of tools or packages | No | No build-time package manager needed |
| `sudo` or privilege escalation | No | Not used |
| Accessing protected resources (camera, location, etc.) | No | Not accessed |
| Modifying system preferences | No | Not done |
| Writing outside the app sandbox | No | FileManager writes to app's own Documents only |
| Launching background daemons | No | No background modes |
| Accessing the keychain | No | Not used |
| Enterprise certificate (distribution) signing | No | Personal team or simulator signing only |

**Expected number of enterprise security prompts during normal Claude Code operation on repo files: zero.**

If a security prompt does appear, it is most likely triggered by Xcode itself (e.g. Xcode requesting network access for updates or telemetry), not by Wild Pairs source code or Claude Code file operations.
