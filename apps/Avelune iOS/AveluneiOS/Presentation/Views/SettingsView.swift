import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredLocale") private var locale = "fr-FR"
    @AppStorage("showDebugInfo") private var showDebug = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("PRÉFÉRENCES")

                            HStack(spacing: 15) {
                                settingIcon("globe.europe.africa.fill")

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Langue")
                                        .font(.headline)
                                        .foregroundStyle(AveluneTheme.text)
                                    Text("Langue de l’application")
                                        .font(.caption)
                                        .foregroundStyle(AveluneTheme.muted)
                                }

                                Spacer()

                                Menu {
                                    Button("Français") { locale = "fr-FR" }
                                    Button("English") { locale = "en-US" }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(locale == "en-US" ? "English" : "Français")
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                }
                                .aveluneGlassButton()
                                .accessibilityLabel("Langue de l’application")
                            }
                            .padding(18)
                            .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(AveluneTheme.border))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("POUR LES CURIEUX")

                            HStack(spacing: 15) {
                                settingIcon("waveform.path.ecg")

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Infos de debug")
                                        .font(.headline)
                                        .foregroundStyle(AveluneTheme.text)
                                    Text("Afficher les informations techniques")
                                        .font(.caption)
                                        .foregroundStyle(AveluneTheme.muted)
                                }

                                Spacer()

                                Toggle("Infos de debug", isOn: $showDebug)
                                    .labelsHidden()
                                    .tint(AveluneTheme.lilac)
                            }
                            .padding(18)
                            .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(AveluneTheme.border))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("À PROPOS")

                            VStack(spacing: 15) {
                                Text("Des histoires à emporter partout.")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(AveluneTheme.text)

                                Text("Avelune pour iOS · Version \(version)")
                                    .font(.caption)
                                    .foregroundStyle(AveluneTheme.muted)

                                if showDebug {
                                    Divider().overlay(AveluneTheme.border)
                                    Text("Moteur Flutter + Flame · map_runtime")
                                        .font(.caption2)
                                        .foregroundStyle(AveluneTheme.muted)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(AveluneTheme.border))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .background(AveluneBackground())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("AveluneWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 205, height: 58, alignment: .leading)
                .offset(x: -18)
                .shadow(color: AveluneTheme.text.opacity(0.32), radius: 1.5)
                .accessibilityLabel("Avelune")

            Text("VOTRE ESPACE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(AveluneTheme.cyan)

            Text("Réglages")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AveluneTheme.text)

            Text("Une expérience à votre image.")
                .font(.subheadline)
                .foregroundStyle(AveluneTheme.muted)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [AveluneTheme.surface.opacity(0.9), AveluneTheme.background.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            AveluneTheme.border.frame(height: 1)
        }
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(2)
            .foregroundStyle(AveluneTheme.muted)
            .padding(.leading, 4)
    }

    private func settingIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(AveluneTheme.cyan)
            .frame(width: 42, height: 42)
            .background(AveluneTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 13))
    }
}
