import 'package:map_core/map_core.dart';

typedef SceneInteractiveCommandHandler = Future<String> Function(
  SceneInteractiveCommand command,
);

/// Closed dispatcher for awaitable Scene commands.
///
/// Validation happens before the host handler is invoked. A bad command or an
/// unsupported result therefore cannot partially advance the Scene graph.
final class SceneInteractiveCommandRuntimeExecutor {
  const SceneInteractiveCommandRuntimeExecutor({
    required this.warp,
    required this.openShop,
    required this.openPc,
  });

  final SceneInteractiveCommandHandler warp;
  final SceneInteractiveCommandHandler openShop;
  final SceneInteractiveCommandHandler openPc;

  Future<String> execute(SceneRuntimePlanIntent intent) async {
    if (intent.kind != SceneRuntimePlanIntentKind.executeInteractiveCommand) {
      throw ArgumentError.value(
        intent.kind,
        'intent',
        'Expected an interactive Scene command intent.',
      );
    }
    final command = intent.interactiveCommand;
    if (command == null) {
      throw StateError('Interactive Scene intent has no command payload.');
    }
    final handler = switch (command.kind) {
      SceneInteractiveCommandKind.warp => warp,
      SceneInteractiveCommandKind.openShop => openShop,
      SceneInteractiveCommandKind.openPc => openPc,
    };
    final output = await handler(command);
    if (!command.outputPortIds.contains(output)) {
      throw StateError(
        'Unsupported ${command.kind.name} result "$output"; expected '
        '${command.outputPortIds.join(', ')}.',
      );
    }
    return output;
  }
}
