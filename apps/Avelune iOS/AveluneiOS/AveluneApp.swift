import SwiftUI

@main
struct AveluneApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AveluneRootView(language: appState.composition.languagePreferences)
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await appState.composition.languagePreferences.refresh() }
            }
        }
    }
}

private struct AveluneRootView: View {
    let language: AppLanguageSettings

    var body: some View {
        ContentView()
            .environment(\.locale, language.locale)
    }
}

@MainActor
final class AppState: ObservableObject {
    let composition: AppComposition
    let gameListViewModel: GameListViewModel
    let gamePlayerViewModel: GamePlayerViewModel

    @Published var selectedTab: AppTab = .games
    @Published var presentedGame: Game?

    init() {
        composition = AppComposition()
        gameListViewModel = composition.makeGameListViewModel()
        gamePlayerViewModel = composition.makeGamePlayerViewModel()
    }
}

enum AppTab: CaseIterable {
    case games
    case settings

    var title: LocalizedStringKey {
        switch self {
        case .games: return "Jeux"
        case .settings: return "Réglages"
        }
    }

    var icon: String {
        switch self {
        case .games: return "gamecontroller"
        case .settings: return "gear"
        }
    }
}
