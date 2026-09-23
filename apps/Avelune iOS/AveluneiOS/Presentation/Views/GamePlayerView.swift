import Flutter
import SwiftUI

/// Full-screen host for the Flutter runtime.
///
/// Splash, intro, title menu, saves and gameplay all live inside the runtime,
/// so this view mounts it and stays out of the way.
struct GamePlayerView: View {
    @ObservedObject var viewModel: GamePlayerViewModel
    let game: Game
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let engine = viewModel.flutterEngine {
                FlutterGameView(engine: engine)
                    .ignoresSafeArea()
            }

            if let error = viewModel.errorMessage {
                errorOverlay(error)
            }
        }
        .statusBarHidden()
        .task {
            await viewModel.start(game) { onClose() }
        }
    }

    private func errorOverlay(_ message: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text(message)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Fermer") { onClose() }
                    .aveluneGlassButton(prominent: true)
            }
        }
    }
}

struct FlutterGameView: UIViewControllerRepresentable {
    let engine: FlutterEngine

    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        controller.view.backgroundColor = .black
        return controller
    }

    func updateUIViewController(_ controller: FlutterViewController, context: Context) {}
}
