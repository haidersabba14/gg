import SwiftUI

/// Designs a non-system keypad. The real Phone app's appearance cannot be
/// themed by a sandboxed iOS app; calling uses the user's normal tel: handler.
struct DialerStudioView: View {
    @Environment(\.openURL) private var openURL
    @State private var theme = DialerPreviewTheme.glass
    @State private var number = ""
    @State private var callError: String?

    private let keys = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["*", "0", "#"]]

    var body: some View {
        ZStack {
            RoyalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RoyalSectionHeader("Dialer Theme Studio", subtitle: "Visual design for a non-system keypad")
                        .foregroundStyle(.white)
                    LimitDisclosureCard(
                        title: "Phone app is protected",
                        message: "GG Customizer cannot change the iPhone Phone app or its dialing screen. This is a private preview. A call opens through the normal iOS Phone handler only after you choose Call.",
                        icon: "phone.badge.checkmark"
                    )

                    dialerPreview

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            RoyalSectionHeader("Keypad material")
                            Picker("Dialer theme", selection: $theme) {
                                ForEach(DialerPreviewTheme.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                            Button("Restore Original Preview") {
                                withAnimation { theme = .glass; number = "" }
                            }
                            .buttonStyle(RoyalButtonStyle())
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dialer Studio")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Call could not start", isPresented: Binding(get: { callError != nil }, set: { if !$0 { callError = nil } })) {
            Button("OK", role: .cancel) { callError = nil }
        } message: { Text(callError ?? "") }
    }

    private var dialerPreview: some View {
        VStack(spacing: 18) {
            Text(number.isEmpty ? "Enter number" : number)
                .font(.system(.title2, design: .rounded).monospacedDigit())
                .foregroundStyle(number.isEmpty ? .white.opacity(0.5) : .white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 42)
                .accessibilityLabel(number.isEmpty ? "No number entered" : "Number \(number)")

            VStack(spacing: 13) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 18) {
                        ForEach(row, id: \.self) { key in
                            Button { if number.count < 24 { number.append(key) } } label: {
                                Text(key)
                                    .font(.title2.weight(.medium))
                                    .frame(width: 70, height: 70)
                                    .background(theme.buttonStyle, in: Circle())
                                    .overlay { Circle().stroke(theme.accent.opacity(0.42), lineWidth: 1) }
                                    .foregroundStyle(theme.foreground)
                                    .shadow(color: theme.accent.opacity(0.32), radius: 9, y: 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Dial \(key)")
                        }
                    }
                }
            }

            HStack(spacing: 22) {
                Button { if !number.isEmpty { number.removeLast() } } label: {
                    Image(systemName: "delete.left.fill").frame(width: 62, height: 54)
                }
                .foregroundStyle(.white)
                .accessibilityLabel("Delete last digit")
                Button { placeCall() } label: {
                    Image(systemName: "phone.fill")
                        .font(.title2)
                        .frame(width: 62, height: 54)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                }
                .disabled(number.isEmpty)
                .opacity(number.isEmpty ? 0.45 : 1)
                .accessibilityLabel("Call using iOS Phone")
                Button { number = "" } label: {
                    Text("Clear").frame(width: 62, height: 54)
                }
                .foregroundStyle(.white)
            }
        }
        .padding(24)
        .background(theme.background, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 1) }
    }

    private func placeCall() {
        let allowed = CharacterSet(charactersIn: "0123456789*#,+")
        let sanitized = number.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !sanitized.isEmpty, let url = URL(string: "tel:\(sanitized)") else {
            callError = "Enter a valid phone number first."
            return
        }
        openURL(url) { accepted in
            if !accepted { callError = "This device cannot open the Phone handler." }
        }
    }
}

private enum DialerPreviewTheme: String, CaseIterable, Identifiable {
    case glass, gold, neon
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self { case .glass: return "Glass"; case .gold: return "Gold"; case .neon: return "Neon" }
    }
    var accent: Color {
        switch self { case .glass: return .cyan; case .gold: return RoyalPalette.gold; case .neon: return .purple }
    }
    var foreground: Color { self == .gold ? .black : .white }
    var buttonStyle: AnyShapeStyle {
        switch self {
        case .glass: return AnyShapeStyle(.ultraThinMaterial)
        case .gold: return AnyShapeStyle(RoyalPalette.goldGradient)
        case .neon: return AnyShapeStyle(LinearGradient(colors: [.purple.opacity(0.85), .black], startPoint: .top, endPoint: .bottom))
        }
    }
    var background: LinearGradient {
        switch self {
        case .glass: return LinearGradient(colors: [.indigo.opacity(0.75), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold: return LinearGradient(colors: [.black, Color(red: 0.22, green: 0.16, blue: 0.02)], startPoint: .top, endPoint: .bottom)
        case .neon: return LinearGradient(colors: [.black, .purple.opacity(0.52), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
