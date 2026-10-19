# Room Fit — implementation plan

## Scope and architecture

Flutter single-codebase app for Windows, Android, iOS (phones + tablets). Pure-Dart domain model computes room geometry, furniture footprint intersections, door swing arcs, and the minimum passable walkway width on a grid; widgets render its results and never own geometry rules. Local JSON persistence via the documents directory; explicit JSON import/export. No network.

## Technology and UX

Flutter 3.47.7 stable + Dart 3.13.5; folders `windows/`, `android/`, `ios/` created in issue #1. **Strategy A: platform-native adaptive widgets.** Windows: Fluent `NavigationView`, command bars, context menus, resize-aware sidebar, keyboard shortcuts, mouse hover. Android: Material 3 dynamic color, navigation bar, back handling. iOS/iPadOS: Cupertino navigation, swipe-back, action sheets, haptics. Thin `AdaptiveScaffold` / `AdaptiveDialog` / `AdaptiveButton` layer wraps idioms, screens remain shared. Canvas is bespoke but OS interactions honor scroll physics, text selection, safe area, dialogs, file pickers, font scaling, and accessibility. Do not render Material on iOS, Cupertino on Android, or phone UI on Windows. UI/golden tests target `TargetPlatform.iOS`, `TargetPlatform.android`, `TargetPlatform.windows`; test phone, tablet, and resizable desktop layouts.

No native Swift/Xcode-only implementation; no React Native, Expo, Kotlin Multiplatform, .NET MAUI, Unity, or Godot. Plugins/platform channels only when necessary, with graceful fallback.

## Data and geometry

Versioned JSON schema: `spaces[]` → `rooms[]` with length, width, wall openings (doors/windows and orientation), `pieces[]` with size and (x,y,rotation), and saved named `layouts[]`. One local file; atomic save/restore; reject malformed/incompatible imports before replacing user data. Distances use integer millimeters for stable round-trip and unit conversions. Walkway calculation is approximate; label estimates clearly and don't imply building-code compliance. No medical/safety claims.

Permissions: no camera, GPS, microphone, contacts, or internet. Only user-initiated document-picker read/write for import/export. Provide readable labels/semantics for canvas objects, high contrast, scalable text, full keyboard navigation on Windows, keyboard/mouse + touch drag support, reduced motion preference.

## Milestones (dependency order)

1. **Skeleton/CI**: Flutter project with enabled `windows`, `android`, `ios`, `com.infinityball.roomfit` in Android and iOS, Windows identity `cominfinityball.roomfit`. `windows-latest`: `flutter test` + `flutter build windows --release`; Linux x64 Docker Flutter tests and Android `flutter build apk --debug`. Document actual host limitations.
2. **Domain**: versioned rooms/furniture and deterministic placement/clearance engine with tests; edge cases include touching edges, blocked door swing, narrow passages, and unit conversions.
3. **Editor**: create room, edit door/windows, furniture catalog/custom entries, drag/rotate/nudge/snap and live warnings. Keyboard/mouse/touch tests.
4. **Data and polish**: local atomic save/load, copy layouts, JSON export/import, data wipe, undo/redo; adaptive UI/goldens at 360, 768, and 1280 logical px with per-platform conventions and accessibility checks.
5. **Windows release**: `.github/workflows/release.yml` triggered by `v*` tag or manual dispatch builds on `windows-latest`, zips release binary, attaches to GitHub release. Update `AppStore/description.txt` to match working features and wire actual `AppStore/icon.png` into Windows `.ico`, Android launcher and iOS asset catalog. Android/Play and iOS/TestFlight submission later opt-in milestones (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, ASC_TEAM_ID configured as names-only Actions secrets; no secret values in logs).

## Testing

Pure-Dart geometry unit tests and JSON round-trip/invalid-input tests; widget/golden/screenshot tests under `TargetPlatform.iOS`, `TargetPlatform.android`, `TargetPlatform.windows` for shared screens and responsive breakpoints. Windows build/test in GitHub Actions, Android compile in Linux/Docker. iOS compilation on macOS runner when configured; never claim an iOS build from Linux. Manual desk check for drag, zoom, resize, screen reader, and scaled text before release.

## Packaging

Windows portable ZIP on a `v*` GitHub release; optional MSIX later with `cominfinityball.roomfit`. Android applicationId and iOS bundle ID `com.infinityball.roomfit` (App Store Connect registration: CREATED). AppStore listing and icon are scaffold artifacts; mobile store upload deferred. Keep app-store description honest about what exists today.

## Risks and non-goals

Measurement inaccuracies: show source measurements and uncertainty; never assert a furniture item physically fits based on the app alone. Grid-based walkway widths are approximate; expose thresholds and advise real-world remeasurement. Imports must be validated before touching existing saves. No AR, photorealistic 3D, construction code compliance, account, ads, cloud sync, subscription, or price catalog.
