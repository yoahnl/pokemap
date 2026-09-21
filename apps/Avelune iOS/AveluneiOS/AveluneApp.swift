import SwiftUI

@main
struct AveluneApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
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

enum AppTab: String, CaseIterable {
    case games = "Jeux"
    case settings = "Réglages"

    var icon: String {
        switch self {
        case .games: return "gamecontroller"
        case .settings: return "gear"
        }
    }
}
