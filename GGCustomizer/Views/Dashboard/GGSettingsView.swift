import SwiftUI

struct GGSettingsView: View {
    @EnvironmentObject private var store: ThemeStore

    var body: some View {
        Form {
            Section("Local profile") {
                TextField("Display name", text: Binding(
                    get: { store.profile.displayName },
                    set: { store.profile.displayName = String($0.prefix(48)) }
                ))
                TextField("Short bio", text: Binding(
                    get: { store.profile.bio },
                    set: { store.profile.bio = String($0.prefix(160)) }
                ), axis: .vertical)
                .lineLimit(2...4)
            }

            Section("Appearance") {
                Picker("Mode", selection: Binding(
                    get: { store.settings.appearance },
                    set: { store.settings.appearance = $0 }
                )) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.settingsTitle).tag(appearance)
                    }
                }
                Picker("Language", selection: Binding(
                    get: { store.settings.languageOverride },
                    set: { store.settings.languageOverride = $0 }
                )) {
                    Text("System").tag("system")
                    Text("English").tag("en")
                    Text("العربية").tag("ar")
                }
                Text("GG uses your chosen locale for its interface. Some system-provided labels remain controlled by iOS.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section("Experience") {
                Toggle("Haptic feedback", isOn: Binding(
                    get: { store.settings.hapticsEnabled },
                    set: { store.settings.hapticsEnabled = $0 }
                ))
                Toggle("Optional in-app sounds", isOn: Binding(
                    get: { store.settings.soundsEnabled },
                    set: { store.settings.soundsEnabled = $0 }
                ))
                Toggle("Automatic local backups", isOn: Binding(
                    get: { store.settings.automaticBackupEnabled },
                    set: { store.settings.automaticBackupEnabled = $0 }
                ))
            }

            Section("Smart schedule") {
                Picker("Change GG theme", selection: Binding(
                    get: { store.settings.themeScheduleRule },
                    set: { store.settings.themeScheduleRule = $0 }
                )) {
                    ForEach(ThemeScheduleRule.allCases) { rule in
                        Text(rule.settingsTitle).tag(rule)
                    }
                }
                Text("iOS does not guarantee exact background scheduling. GG checks this rule while it is open or during an allowed refresh opportunity; it never changes the iOS system theme.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section("Privacy") {
                Label("No ads", systemImage: "nosign")
                Label("No subscription", systemImage: "creditcard")
                Label("No user tracking", systemImage: "hand.raised")
                Text("GG Customizer stores its content locally. Use the iOS share sheet only when you choose to share a design.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings & Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension AppAppearance {
    var settingsTitle: LocalizedStringKey {
        switch self { case .system: return "System"; case .light: return "Light"; case .dark: return "Dark" }
    }
}

private extension ThemeScheduleRule {
    var settingsTitle: LocalizedStringKey {
        switch self {
        case .disabled: return "Disabled"
        case .onAppLaunch: return "When GG opens"
        case .daily: return "Daily when iOS allows"
        case .weekly: return "Weekly when iOS allows"
        }
    }
}
