import SwiftUI

enum AveluneTheme {
    static let background = Color(red: 0.035, green: 0.045, blue: 0.105)
    static let surface = Color(red: 0.085, green: 0.105, blue: 0.19)
    static let surfaceRaised = Color(red: 0.12, green: 0.14, blue: 0.24)
    static let lilac = Color(red: 0.76, green: 0.71, blue: 1)
    static let cyan = Color(red: 0.61, green: 0.91, blue: 1)
    static let muted = Color(red: 0.68, green: 0.71, blue: 0.81)
    static let border = Color.white.opacity(0.1)
    static let accent = LinearGradient(
        colors: [lilac, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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
                colors: [.white.opacity(0.025), .clear, AveluneTheme.lilac.opacity(0.035)],
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
            .foregroundStyle(.white)
            .padding(.horizontal, circular ? 0 : 18)
            .frame(minWidth: circular ? 52 : 0, minHeight: 50)
            .background(.ultraThinMaterial, in: shape)
            .background {
                if prominent {
                    shape.fill(AveluneTheme.lilac.opacity(0.4))
                }
            }
            .overlay(shape.strokeBorder(.white.opacity(prominent ? 0.34 : 0.2), lineWidth: 1))
            .shadow(color: AveluneTheme.lilac.opacity(prominent ? 0.18 : 0.08), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
