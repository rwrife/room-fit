# Room Fit

**Pitch:** An offline room planner for renters, movers, and rearrangers: sketch a room to scale, drag in real furniture sizes, and check clearances and fit on phone, tablet, and Windows — no account, no cloud.

## Overview

Room Fit is a local-first 2D room planner built with Flutter (Windows + Android + iOS from one codebase). Draw the room you actually have (four walls plus doors and windows), drop furniture from a realistic size library or your own custom pieces, and immediately see whether the layout works: walkway widths, door swing clearance, and a printable checklist you can carry to the store or the loading dock.

## Motivation

Existing room planners (Planner 5D, magicplan, IKEA Kreativ) lead with 3D renders, AR scanning, accounts, and subscriptions, and most are phone/tablet-only. The actual job — "will this couch fit, and can I still walk past it?" — is a simple scaled-2D geometry problem that deserves a fast, offline, free tool that also runs full-screen on a desktop where measuring and dragging are comfortable.

## Target users

- Renters and movers checking whether existing or intended furniture fits a room before buying or hauling.
- Homeowners rearranging a room and comparing layout options.
- Anyone who wants dimensions on paper, not a 3D flythrough.

## Use cases

1. Measure a bedroom with a tape measure, sketch it in Room Fit in under a minute, add bed/nightstands/wardrobe, and see that the wardrobe door needs 60 cm it doesn't have.
2. At the store, open the saved plan on the phone, enter the dimensions from the box label, and check the walkway still clears 70 cm.
3. On a Windows desktop before moving day, lay out three candidate furniture arrangements and export the chosen one as a shareable plan file for the movers.

## How to use (intended workflow)

1. New space → add rooms with real measurements (metric or imperial), add doors/windows with hinge and swing side.
2. Add furniture from the built-in library (standard sizes) or define custom pieces with your own dimensions.
3. Drag, rotate, and nudge pieces on the scaled canvas. Snapping and clearance readouts update live; violations are highlighted.
4. Save layouts per room, duplicate to compare options, export/import everything as JSON (one file, yours).

## MVP features

- Rectangular rooms with per-room dimensions; doors (swing arc) and windows on walls.
- Furniture library of ~40 common pieces with realistic footprint sizes + custom pieces.
- Drag/rotate/nudge placement with unit snapping, live clearance and walkway-width readouts, and violation highlighting (overlap, blocked door swing, walkway under threshold).
- Metric + imperial units; per-layout save, duplicate, rename, delete.
- JSON export/import and full data wipe; all data stays on device.
- Adaptive platform-native UI (Fluent on Windows, Material 3 on Android, Cupertino on iOS), touch + mouse/keyboard (arrow-key nudge, Delete, shortcuts).

## Non-goals

- No 3D rendering, AR camera scanning, or photorealistic visualization.
- No accounts, cloud sync, collaboration, or analytics; no network requests at all.
- No multi-floor building editor or construction/architectural features (permits, code compliance).
- No item-level store catalogs, prices, or shopping links.
- Non-medical: Room Fit makes no claims about accessibility code compliance; clearance readouts are planning aids, not legal or building-code advice.

## Privacy, permissions, and data storage

- Zero network access. No account, no telemetry, no ads, no trackers.
- No camera, location, or microphone permissions. File save/open access only for explicit user export/import.
- Plans are stored locally as JSON under the app's documents directory; export produces a plain JSON file the user owns; delete removes it immediately.

## Current status

Flutter workspace (Windows + Android + iOS) with an adaptive shell and CI
(Windows test/release build, Android test/debug APK). Domain geometry, editor
UI, and persistence land in the issue backlog below the skeleton milestone.

## Milestones

1. Flutter skeleton (windows/android/ios enabled) + CI (Windows release build lane, Linux checks).
2. Pure-Dart domain core: rooms, furniture, placement geometry, clearance engine + tests.
3. Editor canvas + furniture library UI with adaptive widgets.
4. Persistence, export/import, privacy controls.
5. Windows portable release on `v*` tags via GitHub release (Android APK compile gate; iOS/TestFlight later).

## Development / build quickstart

CI runs on hosted x64 Windows/Linux runners with Flutter 3.47.7. Build locally
on an x64 host with Flutter 3.47.7:

```
flutter pub get --enforce-lockfile
flutter analyze && flutter test
flutter build windows --release  # Windows only
flutter build apk --debug       # Linux x64 or Windows with Android SDK
```

This development host is Linux ARM64. Its official Flutter archive is x64-only;
for local format/analyze/test checks it uses an official Dart 3.13.5 ARM64 SDK
grafted into Flutter 3.47.7 sources. Flutter Windows builds require Windows;
Android APKs require a working x64 Android SDK/host; iOS builds require macOS
and Xcode. CI records those platform build results separately.

Pinned toolchain: see `toolchain.json` (Flutter 3.47.7 stable / Dart 3.13.5). Identifiers: `com.infinityball.roomfit` (Android applicationId, iOS bundle ID, Windows identity `cominfinityball.roomfit`). Windows identity is reserved for future MSIX packaging; current CI produces a portable build.
