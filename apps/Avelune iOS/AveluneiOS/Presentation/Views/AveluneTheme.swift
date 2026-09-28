import SwiftUI

enum AveluneTheme {
    static let background = adaptive(dark: UIColor(red: 0.035, green: 0.045, blue: 0.105, alpha: 1), light: UIColor(red: 0.96, green: 0.97, blue: 1, alpha: 1))
    static let surface = adaptive(dark: UIColor(red: 0.085, green: 0.105, blue: 0.19, alpha: 1), light: .white)
    static let surfaceRaised = adaptive(dark: UIColor(red: 0.12, green: 0.14, blue: 0.24, alpha: 1), light: UIColor(red: 0.91, green: 0.93, blue: 0.99, alpha: 1))
    static let lilac = adaptive(dark: UIColor(red: 0.76, green: 0.71, blue: 1, alpha: 1), light: UIColor(red: 0.43, green: 0.35, blue: 0.84, alpha: 1))
    static let cyan = adaptive(dark: UIColor(red: 0.61, green: 0.91, blue: 1, alpha: 1), light: UIColor(red: 0.2, green: 0.43, blue: 0.73, alpha: 1))
    static let rose = adaptive(dark: UIColor(red: 1, green: 0.62, blue: 0.8, alpha: 1), light: UIColor(red: 0.8, green: 0.35, blue: 0.59, alpha: 1))
    static let mint = adaptive(dark: UIColor(red: 0.55, green: 0.94, blue: 0.8, alpha: 1), light: UIColor(red: 0.2, green: 0.58, blue: 0.49, alpha: 1))
    static let text = adaptive(dark: .white, light: UIColor(red: 0.07, green: 0.11, blue: 0.23, alpha: 1))
    static let muted = adaptive(dark: UIColor(red: 0.68, green: 0.71, blue: 0.81, alpha: 1), light: UIColor(red: 0.36, green: 0.42, blue: 0.57, alpha: 1))
    static let border = adaptive(dark: UIColor.white.withAlphaComponent(0.12), light: UIColor(red: 0.75, green: 0.79, blue: 0.9, alpha: 0.65))
    static let action = lilac
    static let accent = LinearGradient(
        colors: [lilac, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func artworkStyle(for game: Game) -> AveluneArtworkStyle {
        let palettes: [AveluneArtworkStyle] = [
            .init(glow: Color(red: 0.32, green: 0.75, blue: 0.88), secondary: Color(red: 0.19, green: 0.37, blue: 0.65), action: Color(red: 0.20, green: 0.49, blue: 0.65)),
            .init(glow: Color(red: 1, green: 0.65, blue: 0.43), secondary: Color(red: 0.78, green: 0.32, blue: 0.50), action: Color(red: 0.74, green: 0.35, blue: 0.43)),
            .init(glow: Color(red: 0.70, green: 0.60, blue: 1), secondary: Color(red: 0.34, green: 0.43, blue: 0.82), action: Color(red: 0.48, green: 0.40, blue: 0.77)),
            .init(glow: Color(red: 0.64, green: 0.84, blue: 0.57), secondary: Color(red: 0.18, green: 0.53, blue: 0.56), action: Color(red: 0.25, green: 0.53, blue: 0.46))
        ]

        var hash: UInt32 = 2_166_136_261
        for byte in game.title.utf8 {
            hash = (hash ^ UInt32(byte)) &* 16_777_619
        }

        let palette = palettes[Int(hash % UInt32(palettes.count))]
        guard let accent = color(from: game.accentColor) else { return palette }
        return .init(glow: accent, secondary: palette.secondary, action: palette.action)
    }

    private static func color(from value: String?) -> Color? {
        guard let value else { return nil }
        let hex = value.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6, let number = UInt32(hex, radix: 16) else { return nil }
        return Color(
            red: Double((number >> 16) & 0xff) / 255,
            green: Double((number >> 8) & 0xff) / 255,
            blue: Double(number & 0xff) / 255
        )
    }

    private static func adaptive(dark: UIColor, light: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct AveluneArtworkStyle {
    let glow: Color
    let secondary: Color
    let action: Color
}

struct AveluneBackground: View {
    var accent: Color = AveluneTheme.cyan

    var body: some View {
        ZStack {
            AveluneTheme.background

            RadialGradient(
                colors: [accent.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 340
            )

            RadialGradient(
                colors: [AveluneTheme.lilac.opacity(0.09), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    @ViewBuilder
    func aveluneQuickArtwork(id: String, in namespace: Namespace.ID, reduceMotion: Bool, isSource: Bool = true) -> some View {
        if reduceMotion {
            self
        } else {
            matchedGeometryEffect(id: id, in: namespace, isSource: isSource)
        }
    }

    @ViewBuilder
    func aveluneZoomSource(id: String, in namespace: Namespace.ID, reduceMotion: Bool) -> some View {
        if #available(iOS 18.0, *), !reduceMotion {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func aveluneZoomDestination(id: String, in namespace: Namespace.ID, reduceMotion: Bool) -> some View {
        if #available(iOS 18.0, *), !reduceMotion {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }

    @ViewBuilder
    func aveluneGlassButton(prominent: Bool = false, circular: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
                    .buttonBorderShape(circular ? .circle : .capsule)
                    .tint(AveluneTheme.lilac)
            } else {
                buttonStyle(.glass)
                    .buttonBorderShape(circular ? .circle : .capsule)
            }
        } else {
            buttonStyle(AveluneLegacyGlassButtonStyle(prominent: prominent, circular: circular))
        }
    }
}

private struct AveluneLegacyGlassButtonStyle: ButtonStyle {
    let prominent: Bool
    let circular: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: circular ? 27 : 22, style: .continuous)

        return configuration.label
            .foregroundStyle(AveluneTheme.text)
            .padding(.horizontal, circular ? 0 : 18)
            .frame(minWidth: circular ? 52 : 0, minHeight: 50)
            .background(.ultraThinMaterial, in: shape)
            .background {
                if prominent {
                    shape.fill(AveluneTheme.lilac.opacity(0.4))
                }
            }
            .overlay(shape.strokeBorder(AveluneTheme.border, lineWidth: 1))
            .shadow(color: AveluneTheme.lilac.opacity(prominent ? 0.18 : 0.08), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
