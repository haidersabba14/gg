import SwiftUI
import UIKit

/// Recovery deliberately operates only on the app's sandboxed theme database and exports.
/// It cannot inspect, repair, or delete device system files, other apps, Photos, or passcodes.
struct RecoveryCenterView: View {
    @EnvironmentObject private var store: ThemeStore

    @State private var health = ThemeHealthReport(checkedAt: .now, validThemeCount: 0, invalidThemeIDs: [], warnings: [])
    @State private var report: RecoveryReport?
    @State private var backupToRestore: ThemeBackup?
    @State private var showResetConfirmation = false
    @State private var alertMessage: String?
    @State private var exportedBackupURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                LimitDisclosureCard(
                    title: "Recovery stays inside GG Customizer",
                    message: "These controls restore only GG designs, settings, and local backups. Photos, passcodes, installed apps, wallpapers, and iOS system files are never changed.",
                    icon: "lock.shield.fill"
                )
                quickRecovery
                protection
                healthSection
                backupsSection
                historySection
                destructiveReset
            }
            .padding()
            .padding(.bottom, 28)
        }
        .background(RoyalBackground())
        .navigationTitle("Recovery Center")
        .navigationBarTitleDisplayMode(.inline)
        .task { refreshHealth() }
        .confirmationDialog(
            "Restore this GG backup?",
            isPresented: Binding(get: { backupToRestore != nil }, set: { if !$0 { backupToRestore = nil } }),
            titleVisibility: .visible
        ) {
            Button("Restore backup", role: .destructive) {
                guard let backupToRestore else { return }
                store.restore(backup: backupToRestore)
                feedback("Backup restored inside GG Customizer.")
                self.backupToRestore = nil
                refreshHealth()
            }
            Button("Cancel", role: .cancel) { backupToRestore = nil }
        } message: {
            Text("This replaces the current GG Customizer state. A safety snapshot is created first when Auto Backup is enabled.")
        }
        .confirmationDialog(
            "Reset All Customizations?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset GG Customizer", role: .destructive) {
                let resetReport = store.resetAllCustomizations()
                report = resetReport
                refreshHealth()
                haptic(.warning)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("A safety backup will be kept locally. Only GG Customizer designs, settings, and temporary exports are reset.")
        }
        .sheet(item: $report) { RecoveryReportSheet(report: $0) }
        .alert("Recovery Center", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Emergency Recovery Center", systemImage: "shield.lefthalf.filled.badge.checkmark")
                .font(.title2.bold())
                .foregroundStyle(RoyalPalette.champagne)
            Text("A reversible safety net for the designs and preferences managed by GG Customizer.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var quickRecovery: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                RoyalSectionHeader("Quick recovery", subtitle: "Undo the last GG change or return to the most recent working backup.")
                HStack(spacing: 12) {
                    Button {
                        if store.undo() {
                            feedback("Last GG Customizer change undone.")
                            refreshHealth()
                            haptic(.success)
                        } else {
                            feedback(store.lastError ?? "There is no previous GG change to undo yet.")
                        }
                    } label: {
                        Label("Quick Undo", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RoyalPalette.amethyst)

                    Button {
                        if store.restoreLastWorkingTheme() {
                            feedback("Last working GG backup restored.")
                            refreshHealth()
                            haptic(.success)
                        } else {
                            feedback(store.lastError ?? "No GG backup is available yet.")
                        }
                    } label: {
                        Label("Restore Last Working", systemImage: "clock.arrow.circlepath")
                    }
                    .buttonStyle(.bordered)
                }
                .labelStyle(.titleAndIcon)
            }
        }
    }

    private var protection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                RoyalSectionHeader("Protection", subtitle: "Backups are local by default; sharing is always an explicit action.")
                Toggle(isOn: Binding(
                    get: { store.settings.automaticBackupEnabled },
                    set: { store.settings.automaticBackupEnabled = $0 }
                )) {
                    Label("Auto Backup", systemImage: "externaldrive.badge.checkmark")
                }
                .tint(RoyalPalette.gold)

                Toggle(isOn: Binding(
                    get: { store.settings.safeModeEnabled },
                    set: { store.setSafeMode($0); haptic(.selection) }
                )) {
                    Label("Emergency Safe Mode", systemImage: "shield.fill")
                }
                .tint(RoyalPalette.gold)

                Button {
                    _ = store.makeBackup(reason: "Manual recovery backup")
                    feedback("A local GG recovery backup was created.")
                    haptic(.success)
                } label: {
                    Label("Create Backup Now", systemImage: "archivebox.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoyalButtonStyle())

                exportBackup
            }
        }
    }

    @ViewBuilder
    private var exportBackup: some View {
        if let exportedBackupURL {
            ShareLink(item: exportedBackupURL) {
                Label("Share Recovery Backup", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        } else {
            Button {
                exportNewestBackup()
            } label: {
                Label("Export Recovery Backup", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var healthSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    RoyalSectionHeader("File health", subtitle: "Checks the local GG theme catalog for recoverable consistency issues.")
                    Spacer()
                    FeatureStatusBadge(status: health.isHealthy ? .supported : .limited)
                }
                HStack(spacing: 18) {
                    Label("\(health.validThemeCount) valid", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(RoyalPalette.emerald)
                    Label("\(health.invalidThemeIDs.count) damaged", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(health.invalidThemeIDs.isEmpty ? .secondary : RoyalPalette.gold)
                }
                .font(.subheadline.weight(.semibold))

                if !health.warnings.isEmpty {
                    ForEach(health.warnings, id: \.self) { warning in
                        Label(warning, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Button { refreshHealth() } label: { Label("Scan", systemImage: "stethoscope") }
                    Spacer()
                    Button {
                        health = store.repairThemeDatabase()
                        feedback(health.isHealthy ? "GG theme database repaired and verified." : "GG repaired what it could; review the remaining warnings.")
                        haptic(health.isHealthy ? .success : .warning)
                    } label: { Label("Repair Database", systemImage: "wrench.and.screwdriver") }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var backupsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoyalSectionHeader("Local backups", subtitle: "The most recent 30 GG backups are retained on this device.")
                if store.backups.isEmpty {
                    Text("No backup has been created yet. Create one before experimenting with designs.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.backups.prefix(5)) { backup in
                        Button {
                            backupToRestore = backup
                            haptic(.selection)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Image(systemName: "archivebox")
                                    .foregroundStyle(RoyalPalette.gold)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(backup.reason).font(.subheadline.weight(.semibold))
                                    Text(backup.createdAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if backup.id != store.backups.prefix(5).last?.id { Divider() }
                    }
                }
            }
        }
    }

    private var historySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoyalSectionHeader("Theme History", subtitle: "A local, reversible record of GG changes.")
                if store.history.isEmpty {
                    Text("Your GG changes will appear here.").font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(store.history.prefix(8)) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: historySymbol(entry.action))
                                .foregroundStyle(RoyalPalette.gold)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.themeName).font(.subheadline.weight(.semibold))
                                Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 6)
                            Text(entry.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
    }

    private var destructiveReset: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoyalSectionHeader("Emergency action", subtitle: "Returns GG Customizer to its built-in catalog with a safety backup.")
                Text("This does not delete Photos, files outside GG Customizer, installed apps, system themes, or device settings.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button(role: .destructive) { showResetConfirmation = true } label: {
                    Label("Reset All Customizations", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                }
                .buttonStyle(RoyalButtonStyle(isDestructive: true))
            }
        }
    }

    private func refreshHealth() {
        health = store.checkHealth()
    }

    private func feedback(_ text: String) {
        alertMessage = text
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        HapticService.notification(type, enabled: store.settings.hapticsEnabled)
    }

    private func exportNewestBackup() {
        do {
            let backup = store.backups.first ?? store.makeBackup(reason: "Exported recovery backup")
            let directory = GGFileLocations.exportsDirectory()
            let url = directory.appendingPathComponent("GG-Recovery-\(backup.id.uuidString).ggbackup")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(backup).write(to: url, options: .atomic)
            exportedBackupURL = url
            feedback("Recovery backup prepared for sharing. Keep it private: it contains your GG designs and preferences.")
            haptic(.success)
        } catch {
            feedback("The recovery backup could not be exported: \(error.localizedDescription)")
            haptic(.error)
        }
    }

    private func historySymbol(_ action: ThemeHistoryAction) -> String {
        switch action {
        case .applied: return "paintpalette.fill"
        case .restored: return "arrow.counterclockwise"
        case .imported: return "square.and.arrow.down"
        case .exported: return "square.and.arrow.up"
        case .created: return "plus.circle.fill"
        case .updated: return "slider.horizontal.3"
        case .deleted: return "trash"
        case .reset: return "exclamationmark.arrow.triangle.2.circlepath"
        case .healthRepair: return "wrench.and.screwdriver"
        case .safeMode: return "shield.fill"
        }
    }
}

private struct RecoveryReportSheet: View {
    let report: RecoveryReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Completed") {
                    ForEach(report.actions, id: \.self) { Label($0, systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
                }
                Section("Protected") {
                    ForEach(report.protectedItems, id: \.self) { Label($0, systemImage: "lock.fill").foregroundStyle(RoyalPalette.gold) }
                }
            }
            .navigationTitle(report.title)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
