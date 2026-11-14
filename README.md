# GG Customizer

**Your iPhone. Your Style. Your Rules.**

GG Customizer is a privacy-first SwiftUI studio for creating premium icon packs,
wallpapers, theme palettes, home-screen mockups, app widgets, and Live Activities.
It has no ads, subscriptions, analytics SDKs, or required server.

> العربية: [README.ar.md](README.ar.md) · Installation: [docs/INSTALLATION.md](docs/INSTALLATION.md) · Capability boundaries: [docs/CAPABILITIES.md](docs/CAPABILITIES.md)

## What the first release does

- Creates and exports PNG/WebP-based icon designs with local effects, shapes,
  shadows, reflections, scale controls, and an optional on-device foreground-mask
  workflow where iOS supports it.
- Stores reusable theme packages, ratings, favourites, undo history, automatic
  backups, recovery reports, and local import/export packages on the device.
- Includes 20 free Royal Theme Store presets, a Smart Theme Engine, and a random
  theme generator. Applying a theme changes GG Customizer and its own supported
  widgets only.
- Provides interactive Passcode and Dialer design studios as **visual previews**;
  neither requests nor stores a device passcode.
- Creates home-screen and lock-screen previews, exports wallpapers, and provides
  official iOS instructions for applying exported results.
- Starts Live Activities for GG Customizer tasks on compatible devices, and ships
  an optional Control Center control for supported iOS versions.
- Provides a Device Compatibility Center and an Emergency Recovery Center that
  operate only on GG Customizer's sandboxed files and settings.

## Important iOS boundary

This project deliberately does **not** jailbreak devices, use private APIs,
replace SpringBoard files, or disguise shortcuts as icon replacement.

iOS does not permit a normal app to change other apps' original icons, enumerate
all installed apps, change the system passcode keypad, rearrange the Home Screen,
set the system wallpaper programmatically, or restyle the system Dynamic Island,
Phone app, or Control Center. GG Customizer labels those workflows as preview,
export, or unsupported; it never presents them as applied system changes.

See the complete, feature-by-feature statement in
[docs/CAPABILITIES.md](docs/CAPABILITIES.md).

## Requirements

- Xcode 16 or newer on macOS (the project uses iOS 17 as its base deployment
  target and enables newer APIs only behind availability checks).
- An iPhone/iPad running iOS 17 or later for the core app.
- A Dynamic Island-capable device for Dynamic Island presentation.
- iOS 18 or later for the optional Control Center control.
- An Apple Developer signing identity and matching provisioning profiles to put
  a build on a physical device. These are never committed to this repository.

The target OS version reported by a device is evaluated at runtime. A future iOS
version is not claimed as tested merely because its version number is higher.

## Build and test

Open `GGCustomizer.xcodeproj` in Xcode, select the `GGCustomizer` scheme, then
run the unit tests on an iOS Simulator:

```sh
xcodebuild \
  -project GGCustomizer.xcodeproj \
  -scheme GGCustomizer \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  clean test CODE_SIGNING_ALLOWED=NO
```

GitHub Actions runs the equivalent unsigned simulator checks for pushes and pull
requests. A separate manually triggered workflow can make a signed IPA when the
repository owner configures the required GitHub Secrets. See
[docs/INSTALLATION.md](docs/INSTALLATION.md).

## Privacy

- Theme metadata, backups, generated previews, and optional local profile data
  remain in the app container unless the person explicitly shares or exports them.
- Imported images are used only for the requested design operation.
- Location, calendar, photo, and notification access are requested only when the
  person activates the related feature.
- The app does not collect an Apple ID, device passcode, UDID, IMEI, serial
  number, or tracking identifier.

## Project layout

```text
GGCustomizer/                 Main SwiftUI application
GGCustomizerWidgets/          Home and lock screen widgets
GGCustomizerLiveActivity/     ActivityKit / Dynamic Island presentation
GGCustomizerControlWidget/    Optional iOS 18+ Control Center control
GGCustomizerTests/            Unit tests for local models and recovery
docs/                         Installation and platform-boundary documentation
.github/workflows/            Unsigned CI and manually triggered signed archive
```

## Signing policy

Never add certificates, provisioning profiles, private keys, Apple passwords,
or `*.p12` files to source control. The signed IPA workflow accepts temporary
base64-encoded signing material through GitHub Actions Secrets and removes it at
the end of the job.

## License

Released under the [MIT License](LICENSE).
