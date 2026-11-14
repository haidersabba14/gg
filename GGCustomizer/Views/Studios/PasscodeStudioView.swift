import SwiftUI

/// A design sandbox for a *fictional* keypad. It never asks for, records, or
/// compares the device passcode. Taps only create a short visual response.
struct PasscodeStudioView: View {
    @State private var selectedTheme = PasscodePreviewTheme.royalGold
    @State private var activeKey: Int?
    @State private var tapCount = 0

    var body: some View {
        ZStack {
            RoyalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RoyalSectionHeader("Passcode Studio", subtitle: "A visual editor — no device passcode access")
                        .foregroundStyle(.white)

                    LimitDisclosureCard(
                        title: "Preview only",
                        message: "Apple does not permit apps to read, request, store, or redesign the iPhone lock-screen passcode keypad. This studio creates a visual concept only.",
                        icon: "lock.fill"
                    )

                    PasscodePreview(theme: selectedTheme, activeKey: activeKey, tapCount: tapCount) { digit in
                        activeKey = digit
                        tapCount = min(tapCount + 1, 6)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                            activeKey = nil
                        }
                    }
                    .accessibilityLabel("Passcode design preview")

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            RoyalSectionHeader("Material library", subtitle: "Choose a style for the preview")
                            Picker("Passcode material", selection: $selectedTheme) {
                                ForEach(PasscodePreviewTheme.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack {
                                Label("3D depth", systemImage: "cube.transparent")
                                Spacer()
                                Text(selectedTheme.depthLabel).foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            HStack {
                                Label("Touch reaction", systemImage: "hand.tap.fill")
                                Spacer()
                                Text("Visual only").foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RoyalSectionHeader("Ready-made directions")
                            ForEach(PasscodePreviewTheme.allCases) { style in
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedTheme = style
                                        tapCount = 0
                                    }
                                } label: {
                                    HStack {
                                        Circle().fill(style.accent).frame(width: 18, height: 18)
                                        Text(style.title).foregroundStyle(.primary)
                                        Spacer()
                                        if style == selectedTheme {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(RoyalPalette.gold)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Use \(style.title) passcode preview")
                            }

                            Button("Restore Original Preview") {
                                withAnimation { selectedTheme = .royalGold; tapCount = 0; activeKey = nil }
                            }
                            .buttonStyle(RoyalButtonStyle())
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Passcode Studio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum PasscodePreviewTheme: String, CaseIterable, Identifiable {
    case royalGold, silverChrome, liquidGlass, neonViolet

    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .royalGold: return "Royal Gold"
        case .silverChrome: return "Silver Chrome"
        case .liquidGlass: return "Liquid Glass"
        case .neonViolet: return "Neon Violet"
        }
    }
    var accent: Color {
        switch self {
        case .royalGold: return RoyalPalette.gold
        case .silverChrome: return .white
        case .liquidGlass: return .cyan
        case .neonViolet: return .purple
        }
    }
    var depthLabel: LocalizedStringKey {
        switch self {
        case .royalGold, .silverChrome: return "Polished"
        case .liquidGlass: return "Fluid"
        case .neonViolet: return "Luminous"
        }
    }
    var background: LinearGradient {
        switch self {
        case .royalGold:
            return LinearGradient(colors: [Color.black, Color(red: 0.18, green: 0.12, blue: 0.02)], startPoint: .top, endPoint: .bottom)
        case .silverChrome:
            return LinearGradient(colors: [Color(red: 0.06, green: 0.07, blue: 0.10), .gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .liquidGlass:
            return LinearGradient(colors: [.indigo, .cyan.opacity(0.6), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neonViolet:
            return LinearGradient(colors: [.black, .purple.opacity(0.72), .black], startPoint: .top, endPoint: .bottom)
        }
    }
}

private struct PasscodePreview: View {
    let theme: PasscodePreviewTheme
    let activeKey: Int?
    let tapCount: Int
    let tapped: (Int) -> Void
    private let grid = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [-1, 0, -2]]

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < tapCount ? theme.accent : .white.opacity(0.25))
                        .frame(width: 10, height: 10)
                        .shadow(color: theme.accent.opacity(index < tapCount ? 0.9 : 0), radius: 7)
                }
            }
            .accessibilityLabel("\(tapCount) preview dots filled")

            VStack(spacing: 14) {
                ForEach(grid, id: \.self) { row in
                    HStack(spacing: 18) {
                        ForEach(row, id: \.self) { number in
                            if number == -1 {
                                Color.clear.frame(width: 68, height: 68)
                            } else if number == -2 {
                                Button { tapped(-2) } label: {
                                    Image(systemName: "delete.left.fill")
                                        .frame(width: 68, height: 68)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .accessibilityLabel("Preview delete")
                            } else {
                                Button { tapped(number) } label: {
                                    Text("\(number)")
                                        .font(.title2.weight(.medium))
                                        .frame(width: 68, height: 68)
                                        .foregroundStyle(theme == .silverChrome ? .black : .white)
                                        .background(keyBackground(number), in: Circle())
                                        .overlay {
                                            Circle().stroke(.white.opacity(0.32), lineWidth: 1)
                                        }
                                        .shadow(color: theme.accent.opacity(activeKey == number ? 0.92 : 0.36), radius: activeKey == number ? 16 : 7, y: 5)
                                        .scaleEffect(activeKey == number ? 0.92 : 1)
                                        .rotation3DEffect(.degrees(activeKey == number ? 10 : 0), axis: (x: 1, y: 0, z: 0))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Preview digit \(number)")
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 34)
        .frame(maxWidth: .infinity)
        .background(theme.background, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 38, style: .continuous).stroke(theme.accent.opacity(0.38), lineWidth: 1) }
    }

    private func keyBackground(_ number: Int) -> AnyShapeStyle {
        switch theme {
        case .royalGold:
            return AnyShapeStyle(LinearGradient(colors: [RoyalPalette.champagne, RoyalPalette.gold, .brown], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .silverChrome:
            return AnyShapeStyle(LinearGradient(colors: [.white, .gray.opacity(0.65)], startPoint: .top, endPoint: .bottom))
        case .liquidGlass:
            return AnyShapeStyle(.ultraThinMaterial)
        case .neonViolet:
            return AnyShapeStyle(LinearGradient(colors: [.purple.opacity(0.82), .black.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
}
