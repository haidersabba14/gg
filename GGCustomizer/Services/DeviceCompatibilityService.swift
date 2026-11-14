import CoreLocation
import EventKit
import Foundation
import Photos
import UIKit

#if canImport(ActivityKit)
import ActivityKit
#endif

struct DeviceSnapshot: Hashable, Sendable {
    var systemName: String
    var systemVersion: String
    var deviceClass: String
    var supportsDynamicType: Bool
    var photoAuthorization: String
    var locationAuthorization: String
    var calendarAuthorization: String
}

enum DeviceCompatibilityService {
    static func snapshot() -> DeviceSnapshot {
        let device = UIDevice.current
        return DeviceSnapshot(
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            deviceClass: device.model,
            supportsDynamicType: true,
            photoAuthorization: photoPermissionDescription(PHPhotoLibrary.authorizationStatus(for: .addOnly)),
            locationAuthorization: locationPermissionDescription(CLLocationManager.authorizationStatus()),
            calendarAuthorization: calendarPermissionDescription(EKEventStore.authorizationStatus(for: .event))
        )
    }

    /// This report intentionally lists only public Apple APIs. It does not guess about
    /// jailbreaks, private frameworks, exploits, or an unknown future iOS release.
    static func capabilities() -> [DeviceCapability] {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let supportsIOS17 = version.majorVersion >= 17
        let supportsIOS18 = version.majorVersion >= 18
        let activityEnabled = liveActivitiesEnabled

        return [
            DeviceCapability(
                capability: .localIconStudio,
                status: .supported,
                title: "Icon Studio",
                detail: "Create, import, render, save, and export icon artwork inside GG Customizer.",
                requirement: "PNG and WebP decoding depends on the supplied file and iOS image support."
            ),
            DeviceCapability(
                capability: .localBackgroundRemoval,
                status: supportsIOS17 ? .supported : .limited,
                title: "On-device background removal",
                detail: supportsIOS17 ? "Uses Apple Vision locally when a foreground mask can be generated." : "Requires iOS 17 or later; manual editing remains available.",
                requirement: "iOS 17+; results vary by image."
            ),
            DeviceCapability(
                capability: .otherAppIconReplacement,
                status: .unsupported,
                title: "Replace original icons of other apps",
                detail: "iOS does not let an app replace another installed app’s original icon.",
                requirement: nil
            ),
            DeviceCapability(
                capability: .installedAppSearch,
                status: .unsupported,
                title: "Search all installed apps",
                detail: "iOS does not grant third-party apps a complete installed-app list.",
                requirement: nil
            ),
            DeviceCapability(
                capability: .passcodePreview,
                status: .supported,
                title: "Passcode Studio preview",
                detail: "Create, animate, save, and export a private in-app design preview.",
                requirement: "No device passcode is requested or stored."
            ),
            DeviceCapability(
                capability: .systemPasscodeReplacement,
                status: .unsupported,
                title: "Change the system passcode keypad",
                detail: "The iPhone lock screen and passcode keypad are protected by iOS.",
                requirement: nil
            ),
            DeviceCapability(
                capability: .themeExport,
                status: .supported,
                title: "Local themes and export",
                detail: "Themes, ratings, backups, and GG packages are stored on this device and can be shared by the user.",
                requirement: "Applies to GG Customizer and its official widgets only."
            ),
            DeviceCapability(
                capability: .springBoardLayout,
                status: .unsupported,
                title: "Move SpringBoard icons or pages",
                detail: "GG can design and export a layout preview but cannot rearrange the iOS Home Screen.",
                requirement: nil
            ),
            DeviceCapability(
                capability: .liveActivities,
                status: activityEnabled ? .supported : .limited,
                title: "Live Activities",
                detail: activityEnabled ? "GG task timers and progress can be shown through ActivityKit." : "Live Activities are currently unavailable or disabled for this app/device.",
                requirement: "iOS 16.1+, user permission, and a supported system configuration."
            ),
            DeviceCapability(
                capability: .dynamicIsland,
                status: activityEnabled ? .limited : .limited,
                title: "Dynamic Island",
                detail: "GG can provide its own Live Activity. The system decides whether it appears in Dynamic Island based on hardware and user settings.",
                requirement: "Supported Dynamic Island hardware and Live Activities enabled."
            ),
            DeviceCapability(
                capability: .wallpaperExport,
                status: .supported,
                title: "Wallpaper export",
                detail: "Create and share a wallpaper image, then choose it manually in iOS Settings or Photos.",
                requirement: "User chooses the wallpaper in iOS."
            ),
            DeviceCapability(
                capability: .setSystemWallpaper,
                status: .unsupported,
                title: "Set the system wallpaper automatically",
                detail: "iOS does not allow a third-party app to set the Lock Screen or Home Screen wallpaper.",
                requirement: nil
            ),
            DeviceCapability(
                capability: .lockScreenWidgets,
                status: .supported,
                title: "GG Lock Screen widgets",
                detail: "Official WidgetKit widgets can be added by the user from the iOS widget gallery.",
                requirement: "Widget updates are scheduled by WidgetKit."
            ),
            DeviceCapability(
                capability: .controlCenterControls,
                status: supportsIOS18 ? .supported : .limited,
                title: "GG Control Center control",
                detail: supportsIOS18 ? "A user may add GG’s official Control Center control through iOS." : "Requires iOS 18 or later and a compatible build.",
                requirement: "GG cannot recolor, reorder, or replace Apple's own controls."
            ),
            DeviceCapability(
                capability: .dialerPreview,
                status: .supported,
                title: "Dialer design preview",
                detail: "Create and save a dialer-style visual preview; calling still uses the phone app selected by iOS.",
                requirement: nil
            ),
            DeviceCapability(
                capability: .systemDialerReplacement,
                status: .unsupported,
                title: "Theme the Phone app keypad",
                detail: "GG cannot modify the system Phone app’s interface.",
                requirement: nil
            ),
            DeviceCapability(
                capability: .localBackupRecovery,
                status: .supported,
                title: "GG Recovery Center",
                detail: "Undo, backup, health checks, and reset work only on GG Customizer’s local sandbox data.",
                requirement: "No system files are inspected or deleted."
            ),
            DeviceCapability(
                capability: .weatherData,
                status: weatherStatus(),
                title: "Weather widget data",
                detail: "Location and WeatherKit are optional. Without both, GG uses an explicit preview state rather than inventing live weather.",
                requirement: "Location permission and WeatherKit entitlement/account configuration may be required."
            )
        ]
    }

    private static var liveActivitiesEnabled: Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        #endif
        return false
    }

    private static func weatherStatus() -> CapabilityStatus {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return .limited
        default:
            return .limited
        }
    }

    private static func photoPermissionDescription(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Allowed"
        case .limited: return "Limited"
        @unknown default: return "Unknown"
        }
    }

    private static func locationPermissionDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "While Using"
        @unknown default: return "Unknown"
        }
    }

    private static func calendarPermissionDescription(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Allowed"
        case .fullAccess: return "Full Access"
        case .writeOnly: return "Write Only"
        @unknown default: return "Unknown"
        }
    }
}
