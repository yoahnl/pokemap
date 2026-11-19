import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            GameListView(viewModel: appState.gameListViewModel) { game in
                appState.presentedGame = game
            }
            .tabItem {
                Label(AppTab.games.title, systemImage: AppTab.games.icon)
            }
            .tag(AppTab.games)

            SettingsView(language: appState.composition.languagePreferences)
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(AveluneTheme.action)
        .fullScreenCover(item: $appState.presentedGame) { game in
            GamePlayerView(
                viewModel: appState.gamePlayerViewModel,
                game: game
            ) {
                Task {
                    await appState.gamePlayerViewModel.stop()
                    appState.presentedGame = nil
                    await appState.gameListViewModel.refresh()
                    await appState.composition.languagePreferences.refresh()
                }
            }
        }
    }
}
