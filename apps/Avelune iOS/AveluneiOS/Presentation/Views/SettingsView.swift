import SwiftUI

struct SettingsView: View {
    @AppStorage("showDebugInfo") private var showDebug = false
    @State private var showsLanguageSaveError = false
    let language: AppLanguageSettings

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                settingsHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("PRÉFÉRENCES")

                            languageSetting
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("POUR LES CURIEUX")

                            HStack(spacing: 15) {
                                settingIcon("waveform.path.ecg")

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Infos de debug")
                                        .font(.headline)
                                        .foregroundStyle(AveluneTheme.text)
                                    Text("FPS, latence de rendu, mémoire et CPU dans le jeu")
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
            .alert("Langue de l’application", isPresented: $showsLanguageSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Impossible d’enregistrer la langue. Réessayez.")
            }
        }
    }

    @ViewBuilder
    private var languageSetting: some View {
        if let preferences = language.confirmed {
            Menu {
                Picker("Langue de l’application", selection: Binding(
                    get: { preferences.appLanguage },
                    set: { choice in
                        Task {
                            let saved = await language.select(choice)
                            showsLanguageSaveError = !saved
                        }
                    }
                )) {
                    ForEach([AppLanguage.system] + preferences.supportedAppLanguages, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                languageRow {
                    Text(preferences.appLanguage.title)
                        .multilineTextAlignment(.trailing)

                    if language.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .disabled(language.isSaving)
            .accessibilityLabel("Langue")
            .accessibilityValue(Text(preferences.appLanguage.title))
            .accessibilityIdentifier("app-language-menu")
        } else if language.readFailed {
            Button {
                Task { await language.refresh() }
            } label: {
                languageRow { Text("Réessayer") }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Réessayer de charger la langue")
        } else {
            languageRow {
                ProgressView()
                    .accessibilityLabel("Chargement de la langue")
            }
        }
    }

    private func languageRow<Value: View>(@ViewBuilder value: () -> Value) -> some View {
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

            Spacer(minLength: 0)

            HStack(spacing: 6, content: value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AveluneTheme.muted)
        }
        .padding(18)
        .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AveluneTheme.border))
        .contentShape(Rectangle())
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
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
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

private extension AppLanguage {
    var title: LocalizedStringKey {
        switch self {
        case .system: return "Suivre le téléphone"
        case .french: return "Français"
        case .english: return "English"
        }
    }
}
