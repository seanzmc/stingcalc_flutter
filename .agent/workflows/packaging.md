---
description: How to package and build the app for all platforms
---

# Packaging & Building Guide

This workflow guides you through building release versions of the StingCalc app for all supported platforms.

## Prerequisites

- Ensure you have a valid signing configuration for Android (Keystore) and iOS/macOS (Apple Developer Account/Certificates).
- Run `flutter doctor` to ensure all build tools are installed.

## 1. Android

To build an Android App Bundle (AAB) for the Play Store:

```bash
flutter build appbundle
```

The output will be located at: `build/app/outputs/bundle/release/app-release.aab`

> [!NOTE]
> Ensure `android/key.properties` exists and is referenced in `android/app/build.gradle` for signing.

## 2. iOS

To build an IPA for the App Store or TestFlight:

```bash
flutter build ipa
```

The output will be located at: `build/ios/archive/Runner.xcarchive`

> [!IMPORTANT]
> You must open `ios/Runner.xcworkspace` in Xcode to configure signing capabilities and upload the archive to App Store Connect.

## 3. macOS

To build a macOS application:

```bash
flutter build macos
```

The output will be located at: `build/macos/Build/Products/Release/stingcalc_flutter.app`

> [!TIP]
> For distribution (DMG or App Store), you will need to use Xcode to archive and sign the application, similar to iOS.

## 4. Web

To build for the web:

```bash
flutter build web --release
```

The output will be located at: `build/web`

> [!NOTE]
> There is a `deploy.sh` script in the root directory that handles building for web and moving files to `docs/` for GitHub Pages hosting.
> Run it with: `./deploy.sh`

## 5. Windows

To build for Windows:

```bash
flutter build windows
```

The output will be located at: `build/windows/runner/Release/`

## 6. Linux

To build for Linux:

```bash
flutter build linux
```

The output will be located at: `build/linux/x64/release/bundle/`
