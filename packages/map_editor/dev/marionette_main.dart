import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

/// Debug-only entrypoint for deterministic, observable macOS QA.
void main() {
  // Marionette must be the sole binding initializer in this process.
  MarionetteBinding.ensureInitialized();

  const configuredProjectPath = String.fromEnvironment(
    MarionetteProjectBootstrap.projectPathDefine,
  );
  final bootstrap = MarionetteProjectBootstrap.load(configuredProjectPath);
  final initialState = bootstrap.createInitialState();
  final container = ProviderContainer(
    overrides: <Override>[
      editorNotifierProvider.overrideWith(
        () => _MarionetteSeededEditorNotifier(initialState),
      ),
    ],
  );

  // Force provider creation before runApp, then expose the live provider state
  // so the driver can prove that the rendered shell owns the expected copy.
  container.read(editorNotifierProvider);
  registerMarionetteExtension(
    name: 'pokemap.activeProjectPath',
    description: 'Returns the active and expected PokeMap project roots.',
    callback: (_) async {
      final activePath = container.read(editorNotifierProvider).projectRootPath;
      return MarionetteExtensionResult.success(<String, dynamic>{
        'activeProjectPath': activePath,
        'expectedProjectPath': bootstrap.projectRootPath,
        'matches': activePath == bootstrap.projectRootPath,
      });
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MapEditorApp(),
    ),
  );
}

/// Seeds only the debug container; production continues to use EditorNotifier.
final class _MarionetteSeededEditorNotifier extends EditorNotifier {
  _MarionetteSeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() => initialState;
}
