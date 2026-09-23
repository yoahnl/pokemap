import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            GameListView(viewModel: appState.gameListViewModel) { game in
                appState.presentedGame = game
            }
            .tabItem {
                Label(AppTab.games.rawValue, systemImage: AppTab.games.icon)
            }
            .tag(AppTab.games)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(AveluneTheme.lilac)
        .toolbarBackground(AveluneTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $appState.presentedGame) { game in
            GamePlayerView(
                viewModel: appState.gamePlayerViewModel,
                game: game
            ) {
                Task {
                    await appState.gamePlayerViewModel.stop()
                    appState.presentedGame = nil
                    await appState.gameListViewModel.refresh()
                }
            }
        }
    }
}
