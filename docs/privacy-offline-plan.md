# Wild Pairs — Privacy and Offline Plan

> Last updated: 2026-06-21  
> Status: Living document — update whenever data model or API usage changes.

---

## TL;DR

| Question | Answer |
|---|---|
| What data is stored? | Game state snapshot, user preferences, aggregate play statistics |
| Where is it stored? | App's own Documents directory on-device (FileManager) |
| Does any data leave the device? | **Never** |
| Network calls at runtime? | **Zero** |
| Third-party SDKs? | **Zero** |
| Protected-resource permissions? | **Zero** |
| Personal information collected? | **Zero** |
| Advertising identifiers? | **Zero** |

Wild Pairs is a fully offline card game. It stores exactly three JSON files on the user's device, all within the app's sandboxed Documents directory, purely to support the user's own gameplay (resume a game, remember settings, track personal statistics). No data is transmitted anywhere, ever.

---

## 1. Offline-First Guarantee

"Offline-first" for Wild Pairs means:

- **No network call at launch.** The app does not check for updates, ping analytics endpoints, fetch remote configuration, or validate a licence on startup.
- **No network call during play.** All game logic, AI computation, card rendering, and rule enforcement run entirely on-device.
- **No network call in background.** The app has no background modes enabled. When it enters background it saves game state synchronously to a local file and stops executing.
- **No error dialogs if offline.** The app has no code path that could produce a "no internet connection" dialog because there is no code that attempts a network connection.
- **Permanent airplane mode operation.** The app works correctly in airplane mode from first launch through every subsequent session. There is no feature that degrades or disappears without connectivity.
- **No CDN assets.** All game assets (card artwork, colours, sounds if any) are bundled in the app binary at build time.
- **No remote feature flags.** Feature availability is determined by the compiled binary, not by a remote configuration service.

### How to verify the offline guarantee

```bash
# Scan source for any network API usage
grep -rE \
  "URLSession|URLRequest|Network\.|WKWebView|NSURLConnection|CFNetwork|NWConnection|NWPathMonitor" \
  WildPairsCore/Sources/ WildPairsApp/ \
  --include="*.swift"
# Expected output: no matches
```

If the above grep returns any matches, investigate before shipping.

---

## 2. Data Inventory

### 2.1 wildpairs-game.json — Current Game State

| Field | Value |
|---|---|
| **What it is** | Complete snapshot of the current (or most recently played) game |
| **FileManager path** | `<app-Documents>/wildpairs-game.json` |
| **Why it's needed** | Allows the player to close the app and resume exactly where they left off |
| **When written** | After every player turn (including AI turns), and synchronously when the app enters background |
| **When read** | At app launch, to determine whether a resumable game exists |
| **When deleted** | When the player starts a new game (old snapshot replaced), or when "Reset Local Data" is confirmed in Settings |
| **Leaves device?** | **Never** |

**Fields stored in wildpairs-game.json:**

- `gameMode` — one of `standardTeams`, `allWildTeams`, `sideToSideTeams`
- `difficulty` — one of `easy`, `medium`, `hard`, `expert`
- `players` — array of player descriptors (name string, `isHuman` bool, `teamIndex` int)
- `hands` — array of arrays of card identifiers (each player's current hand)
- `drawPile` — ordered array of card identifiers remaining in the draw pile
- `discardPile` — ordered array of card identifiers in the discard pile (top = last element)
- `currentPlayerIndex` — integer index into `players`
- `direction` — `clockwise` or `counterclockwise`
- `pendingAction` — nullable; describes any pending colour choice or target choice awaiting human input
- `soloCallState` — per-player flags for the Solo! mechanic
- `scores` — per-team round scores
- `roundNumber` — integer

**Not stored:**

- No device identifier
- No player real name (player names are user-entered display names only, e.g. "Player 1")
- No timestamps of individual turns
- No IP address or network identifier
- No advertising identifier

### 2.2 wildpairs-settings.json — User Preferences

| Field | Value |
|---|---|
| **What it is** | User-configurable preferences that persist across sessions |
| **FileManager path** | `<app-Documents>/wildpairs-settings.json` |
| **Why it's needed** | Remembers the player's preferred game experience without requiring re-entry each session |
| **When written** | Immediately when the user changes any setting |
| **When read** | At app launch, before presenting any UI |
| **When deleted** | When "Reset Local Data" is confirmed in Settings; settings return to compiled defaults |
| **Leaves device?** | **Never** |

**Fields stored in wildpairs-settings.json:**

- `animationSpeed` — `slow`, `normal`, `fast`
- `hapticsEnabled` — bool
- `colourBlindModeEnabled` — bool
- `largeCardsEnabled` — bool
- `reducedMotionEnabled` — bool (mirrors system setting but user-overridable in-app)
- `houseRuleDefaults` — dictionary of house rule toggles the user last used
- `lastDifficulty` — the difficulty the user most recently selected
- `lastGameMode` — the game mode the user most recently selected

**Not stored:**

- No personal information
- No device identifier
- No usage timestamps

### 2.3 wildpairs-stats.json — Aggregate Play Statistics

| Field | Value |
|---|---|
| **What it is** | Aggregate counts and rates of games played, won, and statistics per mode |
| **FileManager path** | `<app-Documents>/wildpairs-stats.json` |
| **Why it's needed** | Lets the player see their win rate and streaks in the Stats screen |
| **When written** | At the end of each completed game round |
| **When read** | When the Stats screen is opened |
| **When deleted** | When "Reset Local Data" is confirmed in Settings; statistics clear to zero |
| **Leaves device?** | **Never** |

**Fields stored in wildpairs-stats.json:**

- `totalGamesPlayed` — integer
- `totalGamesWon` — integer (human team wins)
- `currentWinStreak` — integer
- `longestWinStreak` — integer
- `perMode` — dictionary keyed by game mode:
  - `gamesPlayed` — integer
  - `gamesWon` — integer
  - `averageTurnsToWin` — float (running average)
- `perDifficulty` — dictionary keyed by difficulty:
  - `gamesPlayed` — integer
  - `gamesWon` — integer

**Not stored:**

- No timestamps of individual games (only aggregate counts)
- No records of individual game outcomes (only totals)
- No opponent names from individual games
- No device identifier
- No personal information

### 2.4 What is NOT stored

| Item | Stored? | Notes |
|---|---|---|
| Device identifier (IDFV, IDFA) | No | Never accessed |
| Advertising identifier (IDFA) | No | No ad framework linked |
| IP address | No | No network code |
| Location | No | Not accessed |
| Contacts | No | Not accessed |
| Camera/microphone data | No | Not accessed |
| Crash reports | No | No third-party crash SDK; OS-level crash reports managed by Apple |
| Analytics events | No | No analytics SDK |
| Real player names | No | Display names only, user-entered |

---

## 3. Required-Reason APIs Audit

Apple classifies certain APIs as "required-reason APIs" that must be declared in `PrivacyInfo.xcprivacy` with a justification code.

### 3.1 FileManager

- **Used?** Yes.
- **Purpose:** Reading and writing the three JSON persistence files listed in Section 2.
- **Justification category:** The files are created by and for the app itself; their content is never transmitted.
- **Required-reason code:** `DDA9.1` — "Declare this API usage only if your app uses the API to access the app's own containers on-device."
- **Action:** Include in `PrivacyInfo.xcprivacy` under `NSPrivacyAccessedAPITypes`.

### 3.2 UserDefaults

- **Used?** No — by design.
- **Policy:** All persistent data uses the FileManager-based JSON approach described above. `UserDefaults` is not used for any application data. If a future developer introduces `UserDefaults`, it must be declared in `PrivacyInfo.xcprivacy` with reason code `CA92.1` (user defaults that the app itself manages) and this document must be updated.
- **Action:** Do not include in `PrivacyInfo.xcprivacy` unless introduced.
- **Verification:**
  ```bash
  grep -rE "UserDefaults" WildPairsCore/Sources/ WildPairsApp/ --include="*.swift"
  # Expected: no matches
  ```

### 3.3 All Other Required-Reason APIs

| API | Used? | Notes |
|---|---|---|
| `NSFileSystemFreeSize`, `NSFileSystemSize` | No | No disk-space checks |
| `sysctl` (system info) | No | No hardware queries |
| `NSProcessInfo.systemUptime` | No | Not used |
| `UIDevice.identifierForVendor` | No | Not accessed |
| Disk space APIs | No | Not used |
| Active keyboard APIs | No | Not used |

---

## 4. PrivacyInfo.xcprivacy

### 4.1 Is a PrivacyInfo.xcprivacy required?

Yes. Because the app uses `FileManager` (a required-reason API), a `PrivacyInfo.xcprivacy` file must be present in the app target. Without it, App Store submission will fail privacy manifest validation.

### 4.2 Required fields

| Key | Value | Notes |
|---|---|---|
| `NSPrivacyTracking` | `false` | App does not track users |
| `NSPrivacyTrackingDomains` | `[]` (empty array) | No tracking domains |
| `NSPrivacyCollectedDataTypes` | `[]` (empty array) | No data types collected |
| `NSPrivacyAccessedAPITypes` | See below | FileManager declared |

### 4.3 PrivacyInfo.xcprivacy template

Place this file at `WildPairsApp/PrivacyInfo.xcprivacy` and add it to the app target in Xcode (not the Swift Package target).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App does not track users across apps or websites -->
    <key>NSPrivacyTracking</key>
    <false/>

    <!-- No tracking domains -->
    <key>NSPrivacyTrackingDomains</key>
    <array/>

    <!-- No data types are collected from users -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>

    <!-- Required-reason APIs used by this app -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <!-- FileManager: used to read/write the app's own JSON persistence files -->
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <!-- DDA9.1: App uses the API to access app's own containers on-device -->
                <string>DDA9.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

> **Note:** If `UserDefaults` is introduced in future, add a second entry under `NSPrivacyAccessedAPITypes` with type `NSPrivacyAccessedAPICategoryUserDefaults` and reason `CA92.1`.

### 4.4 Verification

After adding PrivacyInfo.xcprivacy to the project:

```bash
# Confirm file exists in app target directory
ls WildPairsApp/PrivacyInfo.xcprivacy

# Validate XML is well-formed
plutil -lint WildPairsApp/PrivacyInfo.xcprivacy
# Expected: WildPairsApp/PrivacyInfo.xcprivacy: OK
```

In Xcode: select `PrivacyInfo.xcprivacy` in the Project Navigator and confirm it appears in the Target Membership for `WildPairsApp` (not for `WildPairsCore`).

---

## 5. Network-Free Verification

### 5.1 Source scan script

```bash
#!/usr/bin/env bash
# scripts/check_no_network_usage.sh
# Scans Swift source for any network-capable APIs.
# Expected: zero matches. Any match must be reviewed before shipping.

set -euo pipefail

SOURCES=(
  "WildPairsCore/Sources"
  "WildPairsApp"
)

PATTERNS=(
  "URLSession"
  "URLRequest"
  "Network\."
  "NWConnection"
  "NWPathMonitor"
  "WKWebView"
  "NSURLConnection"
  "CFNetwork"
  "CFHTTPMessage"
  "CFReadStream"
  "CFWriteStream"
  "SCNetworkReachability"
  "Reachability"
  "AF\."              # Alamofire
  "Moya"
)

PATTERN_ARGS=""
for p in "${PATTERNS[@]}"; do
  PATTERN_ARGS="$PATTERN_ARGS -e $p"
done

echo "Scanning for network API usage..."
MATCHES=$(grep -rE $PATTERN_ARGS "${SOURCES[@]}" --include="*.swift" 2>/dev/null || true)

if [ -z "$MATCHES" ]; then
  echo "PASS: No network API usage found."
  exit 0
else
  echo "FAIL: Network API usage detected:"
  echo "$MATCHES"
  exit 1
fi
```

### 5.2 Airplane mode manual test

1. On an iPhone or iPad simulator: Settings → toggle Airplane Mode ON.
2. Force-quit Wild Pairs if running.
3. Launch Wild Pairs.
4. Play a full game (at least 10 turns).
5. Background the app (swipe up on simulator), wait 5 seconds, return.
6. Verify game resumes correctly.
7. Complete the game.
8. Open Stats screen. Verify stats updated.

Expected at every step: no network error dialogs, no spinners, no degraded functionality.

### 5.3 What would indicate a network call

- Any `URLError` in the console
- Any `nw_` log lines in the Xcode console
- Any OS-level "App is using network" indicator in Screen Time or developer tools
- Any outbound connection in Charles Proxy / Network Link Conditioner if attached

---

## 6. Third-Party SDK Assessment

### 6.1 Current status: zero third-party SDKs

Wild Pairs has no third-party runtime dependencies. The only Swift Package dependency is `WildPairsCore`, a local package within the same repository.

### 6.2 How to verify

```bash
# Check Package.resolved for remote dependencies
cat WildPairsApp/WildPairsApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
# Expected: empty or contains only local package references

# Check for CocoaPods
ls Podfile 2>/dev/null && echo "WARNING: Podfile found" || echo "No Podfile — OK"

# Check for Carthage
ls Cartfile 2>/dev/null && echo "WARNING: Cartfile found" || echo "No Cartfile — OK"

# Check SPM Package.swift for remote dependencies
grep -E "\.package\(url:" Package.swift
# Expected: no matches (no remote URL dependencies)
```

### 6.3 Policy for future dependencies

Before adding any Swift Package dependency, the following must be assessed:

1. Does it make network calls? If yes, do not add without explicit approval and privacy manifest update.
2. Does it access any required-reason APIs? If yes, update `PrivacyInfo.xcprivacy`.
3. Does it have its own `PrivacyInfo.xcprivacy`? If not, its API usage must be declared in the app's manifest.
4. Does it collect any data? If yes, `NSPrivacyCollectedDataTypes` must be updated.

---

## 7. Data Minimisation Practices

### 7.1 Game snapshot

The game snapshot stores only what is mechanically necessary to reconstruct the game state so play can resume. It does not store:

- Turn history or move logs
- Timestamps of individual turns
- Player identifiers beyond the display name entered for that session
- Device-level identifiers

### 7.2 Statistics

Statistics store only aggregate integer counts and running averages. They do not store:

- Timestamps of individual games
- Records of individual game outcomes (only totals)
- Opponent names from past games
- Session identifiers

### 7.3 Settings

Settings store only the preferences the user has actively configured. Default values are compiled into the binary; the settings file is only written when the user changes something from the default.

### 7.4 Data retention

Data is retained until the user explicitly resets it (Section 8) or uninstalls the app. There is no automatic expiry, no cloud backup, and no synchronisation across devices.

---

## 8. Reset Local Data

### 8.1 Location in UI

Settings screen → scroll to "Data" section → "Reset All Data" button.

### 8.2 User flow

1. User taps "Reset All Data".
2. App presents a confirmation dialog:
   > **Reset All Data?**
   > This will delete your saved game, all statistics, and return settings to defaults. This cannot be undone.
   > [Cancel] [Reset]
3. If user taps "Reset": all three JSON files are deleted, game returns to home screen with no saved game, settings revert to compiled defaults, statistics show zeros.
4. If user taps "Cancel": no change.

### 8.3 Implementation

```swift
// DataResetService.swift (WildPairsCore)
func resetAllLocalData() throws {
    let documentsURL = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    )
    let filesToDelete = [
        "wildpairs-game.json",
        "wildpairs-settings.json",
        "wildpairs-stats.json"
    ]
    for filename in filesToDelete {
        let fileURL = documentsURL.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
```

### 8.4 Post-reset state

After reset:

- `wildpairs-game.json` — deleted; home screen shows no "Resume" option
- `wildpairs-settings.json` — deleted; app uses compiled defaults on next launch
- `wildpairs-stats.json` — deleted; Stats screen shows all zeros

---

## 9. Trademark and Brand Safety

Wild Pairs is designed to be legally distinct from any existing card game, including UNO (Mattel, Inc.).

### 9.1 Original elements

| Element | Wild Pairs choice | UNO equivalent (avoided) |
|---|---|---|
| Game name | Wild Pairs | UNO |
| Card colours | Crimson, Cobalt, Jade, Amber | Red, Blue, Green, Yellow |
| "Going out" call | "Solo!" | "UNO!" |
| Game publisher | — | Mattel |

### 9.2 Verification scan

```bash
grep -rEi "UNO|Mattel|mattel" \
  docs/ WildPairsCore/ WildPairsApp/ \
  --include="*.swift" --include="*.md" \
  --include="*.plist" --include="*.strings" \
  --include="*.json"
# Expected: no matches
```

If any match is found in app content, UI strings, or metadata, it must be replaced with the Wild Pairs equivalent before submission.

### 9.3 App Store metadata policy

- App Store title: "Wild Pairs"
- Keywords: must not include "UNO", "Mattel", or any trademarked competitor terms
- Description: must not reference UNO or claim compatibility

---

## 10. Audit Trail

| Date | Change | Author |
|---|---|---|
| 2026-06-21 | Initial version | Wild Pairs team |

> Update this table whenever the data model, API usage, or SDK list changes.
