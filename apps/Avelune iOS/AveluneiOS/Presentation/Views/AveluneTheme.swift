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
        }
        .ignoresSafeArea()
    }
}

struct AvelunePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(AveluneTheme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(AveluneTheme.accent, in: RoundedRectangle(cornerRadius: 18))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}
