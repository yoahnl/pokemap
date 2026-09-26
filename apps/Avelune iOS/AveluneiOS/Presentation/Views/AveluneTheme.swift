import SwiftUI

enum AveluneTheme {
    static let background = adaptive(dark: UIColor(red: 0.035, green: 0.045, blue: 0.105, alpha: 1), light: UIColor(red: 0.96, green: 0.97, blue: 1, alpha: 1))
    static let surface = adaptive(dark: UIColor(red: 0.085, green: 0.105, blue: 0.19, alpha: 1), light: .white)
    static let surfaceRaised = adaptive(dark: UIColor(red: 0.12, green: 0.14, blue: 0.24, alpha: 1), light: UIColor(red: 0.91, green: 0.93, blue: 0.99, alpha: 1))
    static let lilac = adaptive(dark: UIColor(red: 0.76, green: 0.71, blue: 1, alpha: 1), light: UIColor(red: 0.43, green: 0.35, blue: 0.84, alpha: 1))
    static let cyan = adaptive(dark: UIColor(red: 0.61, green: 0.91, blue: 1, alpha: 1), light: UIColor(red: 0.2, green: 0.43, blue: 0.73, alpha: 1))
    static let text = adaptive(dark: .white, light: UIColor(red: 0.07, green: 0.11, blue: 0.23, alpha: 1))
    static let muted = adaptive(dark: UIColor(red: 0.68, green: 0.71, blue: 0.81, alpha: 1), light: UIColor(red: 0.36, green: 0.42, blue: 0.57, alpha: 1))
    static let border = adaptive(dark: UIColor.white.withAlphaComponent(0.12), light: UIColor(red: 0.75, green: 0.79, blue: 0.9, alpha: 0.65))
    static let action = lilac
    static let accent = LinearGradient(
        colors: [lilac, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private static func adaptive(dark: UIColor, light: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct AveluneBackground: View {
    var body: some View {
        ZStack {
            AveluneTheme.background

            RadialGradient(
                colors: [AveluneTheme.lilac.opacity(0.19), .clear],
                center: .topLeading,
                startRadius: 30,
                endRadius: 390
            )

            RadialGradient(
                colors: [AveluneTheme.cyan.opacity(0.1), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 360
            )

            LinearGradient(
                colors: [AveluneTheme.surface.opacity(0.1), .clear, AveluneTheme.lilac.opacity(0.035)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
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
