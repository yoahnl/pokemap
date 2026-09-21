import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredLocale") private var locale = "fr-FR"
    @AppStorage("showDebugInfo") private var showDebug = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Général") {
                    Picker("Langue", selection: $locale) {
                        Text("Français").tag("fr-FR")
                        Text("English").tag("en-US")
                    }
                }

                Section("Développement") {
                    Toggle("Infos de debug", isOn: $showDebug)
                }

                Section("À propos") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Moteur", value: "Flutter + Flame")
                    LabeledContent("Runtime", value: "map_runtime")
                }
            }
            .navigationTitle("Réglages")
        }
    }
}
