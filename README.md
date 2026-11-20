# Minis Pulse

A small native iOS app built entirely from an iPhone — SwiftUI, no Mac required.

## What it does

Three screens, all offline, no network, no tracking:

| Screen | Features |
|---|---|
| **Device** | Live battery %, charging state, thermal state, low-power mode, storage bar, RAM, CPU cores, uptime, machine identifier, iOS version. Refreshes every 2 s. |
| **Focus** | Pomodoro timer with animated progress ring, focus/short-break/long-break phases, auto-advance after 4 sessions, haptic feedback, persistent session counter. |
| **Notes** | Create / edit / delete / pin notes, full-text search, `UserDefaults` persistence, context menu actions. |

## Build

The app is compiled on GitHub's macOS runners — no local Xcode needed.

```
.github/workflows/build.yml
```

On every push to `main` the workflow:

1. Installs **XcodeGen** and generates `MinisPulse.xcodeproj` from `project.yml`
2. Builds for `iphoneos` with code signing disabled
3. Packages the `.app` into `Payload/` and zips it as `MinisPulse-unsigned.ipa`
4. Uploads the IPA as a downloadable artifact

### Install on device

The IPA is **unsigned**. Sign it with one of:

- **AltStore** / **SideStore** (free Apple ID, 7-day refresh)
- **Sideloadly** (Windows / macOS)
- **Apple Configurator** (macOS)

## Project layout

```
project.yml                 XcodeGen spec (target, bundle id, Info.plist keys)
Support/Info.plist          App metadata
Sources/
  MinisPulseApp.swift       @main entry point
  AppStore.swift            ObservableObject: notes + pomodoro state, persistence
  RootView.swift            Tab bar + theme
  DeviceView.swift          DeviceMonitor (UIKit/ProcessInfo) + telemetry UI
  FocusView.swift           Pomodoro ring + controls
  NotesView.swift           Notes list, search, editor sheet
.github/workflows/build.yml CI: build + package unsigned IPA
```

## Requirements

- iOS 17.0+
- Xcode 15+ (on the CI runner)

## License

MIT
