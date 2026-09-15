# AltPlay — CarPlay for Your iPhone

A CarPlay-style dashboard experience that runs directly on your iPhone. Landscape-only, dark UI, large touch targets, navigation with voice guidance, and music controls — all the CarPlay essentials without needing a car screen.

> **Not for the App Store.** This app uses private Apple APIs and is built for personal use only. You will need a paid Apple Developer account ($99/year) to sign and install it.

---

## Features

| Screen | What it does |
|--------|-------------|
| **Dashboard** | Clock, battery, Now Playing widget, Navigation widget, and app grid |
| **Navigation** | Apple Maps (MapKit) with search, route calculation, turn-by-turn voice guidance |
| **Music** | Play/pause/skip via `MPMusicPlayerController` — controls Apple Music and synced libraries |
| **Contacts** | Your real contacts (or sample data) with one-tap Call and Directions |
| **Messages** | Quick-phrase compose buttons that open the Messages app |
| **Podcasts** | Stub UI with sample shows and episodes |
| **Settings** | Keep screen awake toggle, voice guidance toggle, system settings link |

---

## Requirements

- **macOS** — GitHub Actions builds it for you, no Mac needed
- **Paid Apple Developer account** — to sign and install on your device via TestFlight
- **iPhone running iOS 17+**
- **XcodeGen** — generates the `.xcodeproj` from `project.yml` (installed automatically in CI)

---

## Project Structure

```
Alt-Mobile-Play/
├── project.yml                  # XcodeGen spec
├── App/
│   ├── AltPlayApp.swift         # Entry point (landscape lock, idle timer)
│   ├── AppDelegate.swift        # Battery monitoring, idle timer
│   ├── Info.plist               # Landscape-only, permission strings
│   ├── Assets.xcassets/
│   ├── DesignSystem/Theme.swift # Colors, fonts, tile style, helpers
│   ├── Router/AppRouter.swift   # Full-screen navigation (home → apps)
│   ├── Services/
│   │   ├── AppSettings.swift    # UserDefaults-backed settings
│   │   ├── NowPlayingService.swift  # Music playback + now playing info
│   │   ├── ContactsService.swift    # CNContactStore + sample fallback
│   │   └── NavigationState.swift    # Route calc, turn-by-turn, voice
│   └── Screens/
│       ├── Home/        HomeScreenView (dashboard + widgets)
│       ├── Navigation/  NavigationView (MapKit + search + directions)
│       ├── Music/       MusicView (player controls + volume)
│       ├── Phone/       ContactsView (call + directions)
│       ├── Messages/    QuickMessagesView (quick phrase compose)
│       ├── Podcasts/    PodcastsView (stub)
│       └── Settings/    SettingsView (toggles + about)
├── .github/workflows/build.yml  # CI: simulator build + TestFlight
├── Gemfile / fastlane/          # Fastlane for TestFlight upload
└── README.md
```

---

## Building

### Option A: TestFlight (recommended — no Mac needed)

Every push to `main` validates the build on a macOS CI runner. To build and install on your iPhone:

#### 1. One-time setup (Developer Portal)

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. **Register your iPhone UDID** (Settings → General → About → copy the identifier)
3. Create an **App ID** for the app:
   - Go to Identifiers → + → App IDs → App
   - Bundle ID: `com.altmobileplay.altplay` (must match `project.yml`)
   - Enable capabilities: Maps, Music, Contacts
4. Create a **Development Provisioning Profile** (or App Store for TestFlight):
   - Profiles → + → App Store → select your App ID → select your device
   - Download the `.mobileprovision` file
5. Create an **App Store Connect API Key**:
   - Go to App Store Connect → Users and Access → Keys → Generate
   - Save the `.p8` file, note the Key ID and Issuer ID

#### 2. Create a `match` repository

`fastlane match` stores your signing certificate and profiles in a git repo.

1. Create an empty **private** GitHub repo (e.g. `YourUser/match-signing`)
2. In your GitHub repo, go to Settings → Secrets and variables → Actions
3. Add these **repository secrets**:

| Secret | Value |
|--------|-------|
| `APP_ID` | `com.altmobileplay.altplay` |
| `TEAM_ID` | Your Apple Developer Team ID (find it at [developer.apple.com](https://developer.apple.com/account) under Membership) |
| `APPLE_KEY_ID` | The Key ID from your App Store Connect API key |
| `APPLE_ISSUER_ID` | The Issuer ID (shown on the API keys page) |
| `APPLE_KEY_CONTENT` | Base64-encoded `.p8` file: `base64 -i AuthKey_XXX.p8 \| tr -d '\n'` |
| `MATCH_REPOSITORY` | `https://YOUR_USER:YOUR_GITHUB_PAT@github.com/YOUR_USER/match-signing.git` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 of `YOUR_USER:YOUR_GITHUB_PAT` — generate with: `echo -n 'YOUR_USER:YOUR_GITHUB_PAT' \| base64` |

> `YOUR_GITHUB_PAT` is a Personal Access Token with `repo` scope. Generate one at [github.com/settings/tokens](https://github.com/settings/tokens).

#### 3. Trigger the build

Go to Actions → Build → Run workflow → check "Build for device and upload to TestFlight" → Run workflow.

Fastlane will:
1. Generate the Xcode project
2. Create/refresh the signing certificate and profile via `match`
3. Build and archive the app
4. Upload to TestFlight

Once uploaded, install via the **TestFlight app** on your iPhone.

### Option B: Simulator-only (no signing needed)

Push any change to `main` — the CI runs a simulator build automatically to validate the code compiles. This is for validation only; the app won't run in a simulator (needs real Maps, Contacts, Music).

---

## What Runs Where

| Feature | Works in Simulator | Works on Device |
|---------|-------------------|-----------------|
| Compile & run UI | ✓ (no signing) | ✓ (needs signing) |
| Turn-by-turn navigation | Partially (no GPS) | ✓ (GPS + MapKit) |
| Music controls | ✓ (no music library) | ✓ (Apple Music) |
| Contacts | ✓ (sample data) | ✓ (real contacts) |
| Messages deep-links | ✓ (opens Messages) | ✓ (opens Messages) |
| Podcasts (stub) | ✓ | ✓ |
| Screen keep-awake | ✓ | ✓ |

---

## How It Works

- **Landscape lock** enforced via `Info.plist` (`UISupportedInterfaceOrientations`)
- **Idle timer disabled** via `UIApplication.shared.isIdleTimerDisabled` (toggle in Settings)
- **Status bar hidden** and **home indicator hidden** for full-screen driving mode
- **Navigation** uses `MKDirections` for route calculation and `AVSpeechSynthesizer` for voice guidance
- **Music** uses `MPMusicPlayerController.systemMusicPlayer` to control playback and display now-playing info
- **Contacts** uses `CNContactStore` with a sample fallback when access is denied
- **Home button** floats in the bottom-left on all non-home screens (CarPlay-style)
- **Dark theme** with rounded fonts, large touch targets, and minimal visual noise

---

## Known Limitations

- **No cross-app music control**: `systemMusicPlayer` only controls Apple Music. Spotify/other apps need private MediaRemote APIs.
- **Messages can't prefill text**: `sms:` URLs open the Messages app but don't fill in the message body (private ChatKit API required).
- **No real podcast playback**: The Podcasts screen is a UI stub with sample data.
- **No Siri integration**: Adding SiriKit would require a Siri entitlement and App Store review.
- **Voice guidance is text-to-speech**: Uses `AVSpeechSynthesizer` rather than turn-by-turn navigation audio.

---

## Adding Features

### Voice guidance for Spotify / other apps

The `MediaRemote` private framework can read system-wide now-playing info and control other apps. You'd need:
1. Link `MediaRemote.framework` privately
2. Use `MRMediaRemoteGetNowPlayingInfo` for cross-app now-playing
3. Add the `com.apple.private.applemediaremotenowplaying.info` entitlement (requires jailbreak or enterprise cert)

### Messages with ChatKit

CarPlay's messaging uses `CKSendMessage` from the private `ChatKit.framework`. For a sideloaded personal app:
1. Link `ChatKit.framework` and `ChatKitUI.framework` privately
2. Use `CKSendMessage` to send without opening the Messages app
3. Add the `com.apple.private.imessaging` entitlement

### Turn-by-turn with MapKit

The current implementation works well for driving directions. To add:
- **Toll/highway warnings**: Parse `MKRoute.Step` for toll/highway components
- **Alternative routes**: Enable `request.requestsAlternateRoutes = true`
- **ETA updates**: Poll `route.expectedTravelTime` as you drive

---

## License

This is a personal project — use it however you like.
