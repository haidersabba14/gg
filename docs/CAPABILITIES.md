# GG Customizer capability boundaries

This document is part of the product contract. A green feature means it is
implemented through public Apple APIs. A yellow feature is a preview, local
editor, export, or user-initiated integration. A red feature is intentionally
not offered as an applied system customization.

| Area | Status | What GG Customizer can do | What it will not claim or attempt |
| --- | --- | --- | --- |
| Icon Studio | ✅ Supported / ⚠️ Export | Import PNG/WebP, draw, render effects, save packs, share files, and attempt local foreground masking on supported iOS versions. | Change the original icon of another installed app, replace app files, enumerate all installed apps, or hide a Shortcut workaround. |
| Passcode Studio | ⚠️ Preview only | Create interactive keypad concepts, touch effects, and export designs. | Read, request, retain, validate, or change the device passcode or system keypad. |
| Royal Theme Store | ✅ Local app theme | Apply colours, templates, and settings to GG Customizer and its own supported widgets; save, rate, export, and restore packages. | Apply a global iOS theme or change another app's look. |
| Home Screen Designer | ✅ Editor / ⚠️ Export | Create multi-page mockups, add GG widgets, save layouts, export a preview, and provide official placement instructions. | Rearrange SpringBoard, create system pages, or control other developers' widgets. |
| Weather widget | ⚠️ Permission/service dependent | Use approved location and WeatherKit data when the user grants access and the developer has enabled WeatherKit. | Promise live weather without permission, entitlement, connectivity, or a service response. |
| Dynamic Island Studio | ✅ For GG activities | Start and update ActivityKit Live Activities for GG Customizer tasks on eligible devices. | Redesign the system Dynamic Island, affect another app's activity, or force a device to show it. |
| Lock Screen Studio | ✅ Export / ⚠️ Preview | Build and export wallpapers; offer GG lock-screen widgets; explain Apple's wallpaper flow. | Set a system wallpaper, change the lock-screen clock, or guarantee iOS depth-effect acceptance. |
| Control Center Studio | ✅ Own control on iOS 18+ | Publish an optional `ControlWidget`/App Intent that the person may add themselves. | Change the appearance, order, or behaviour of Apple's built-in controls. |
| Dialer Theme Studio | ⚠️ Preview only | Design, save, share, and preview dial-pad skins; optionally invoke `tel:` only after user action. | Theme or replace the Phone app's keypad. |
| Smart Theme Engine | ✅ Local | Extract local image colours, recommend palettes, generate themes, preserve history, and schedule in-app refresh attempts within iOS limits. | Modify iOS theming in the background or promise precise recurring scheduling. |
| Recovery Center | ✅ GG sandbox only | Undo GG actions, restore GG backups, repair GG metadata, clean GG temporary files, and make recovery reports. | Delete, repair, inspect, or restore system files, other apps, or user content outside GG's sandbox. |
| Device Compatibility Center | ✅ Public signals | Report OS version, form factor, permission state, and public feature availability. | Read IMEI/UDID/serial number, detect undocumented exploits, or guess jailbreak/system-modification compatibility. |

## Status language in the app

- **Supported / تعمل:** A public API performs the described GG Customizer action.
- **Limited / تعمل جزئيًا:** The result depends on permission, hardware, iOS
  availability, user action, or an Apple service.
- **Unsupported / غير مدعومة:** Apple prevents the requested system-level change.
  The UI explains why and does not expose a deceptive Apply button.

## Data and safety commitments

1. A device passcode is never requested, sent, stored, or inferred.
2. User photos and imported images are kept in the app sandbox unless explicitly
   exported through the system share/save interface.
3. Recovery only changes records created by GG Customizer. It does not use root
   access, private frameworks, configuration profiles, or boot-time changes.
4. There is no hidden server dependency, advertising SDK, subscription gate, or
   behavioural tracking in the application.
