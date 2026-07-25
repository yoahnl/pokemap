import 'package:map_core/map_core.dart';

import '../../player/runtime_world_service_models.dart';

typedef SceneInteractiveCommandHandler = Future<String> Function(
  SceneInteractiveCommand command,
);
typedef SceneWorldServiceRequestHandler = Future<String> Function(
  RuntimeWorldServiceRequest request,
);

/// Closed dispatcher for awaitable Scene commands.
///
/// Validation happens before the host handler is invoked. A bad command or an
/// unsupported result therefore cannot partially advance the Scene graph.
final class SceneInteractiveCommandRuntimeExecutor {
  const SceneInteractiveCommandRuntimeExecutor({
    required this.warp,
    this.openShop,
    this.openHeal,
    this.openPc,
    this.openWorldService,
  });

  final SceneInteractiveCommandHandler warp;
  final SceneInteractiveCommandHandler? openShop;
  final SceneInteractiveCommandHandler? openHeal;
  final SceneInteractiveCommandHandler? openPc;
  final SceneWorldServiceRequestHandler? openWorldService;

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
    final output = switch (command.kind) {
      SceneInteractiveCommandKind.warp => await warp(command),
      SceneInteractiveCommandKind.openShop => await _executeService(
          command,
          legacyHandler: openShop,
        ),
      SceneInteractiveCommandKind.openHeal => await _executeService(
          command,
          legacyHandler: openHeal,
        ),
      SceneInteractiveCommandKind.openPc => await _executeService(
          command,
          legacyHandler: openPc,
        ),
    };
    if (!command.outputPortIds.contains(output)) {
      throw StateError(
        'Unsupported ${command.kind.name} result "$output"; expected '
        '${command.outputPortIds.join(', ')}.',
      );
    }
    return output;
  }

  Future<String> _executeService(
    SceneInteractiveCommand command, {
    required SceneInteractiveCommandHandler? legacyHandler,
  }) {
    final worldHandler = openWorldService;
    if (worldHandler != null) {
      return worldHandler(_worldServiceRequest(command));
    }
    if (legacyHandler == null) {
      throw StateError(
        'No handler is installed for ${command.kind.name}.',
      );
    }
    return legacyHandler(command);
  }

  RuntimeWorldServiceRequest _worldServiceRequest(
    SceneInteractiveCommand command,
  ) {
    return switch (command) {
      SceneOpenShopInteractiveCommand(:final shopId) => OpenShopService(
          interactionId: 'scene.openShop:$shopId',
          shopId: shopId,
        ),
      SceneOpenHealInteractiveCommand(:final requiresConfirmation) =>
        OpenHealService(
          interactionId: 'scene.openHeal',
          requiresConfirmation: requiresConfirmation,
        ),
      SceneOpenPcInteractiveCommand(:final storageId) => OpenPcService(
          interactionId: 'scene.openPc:${storageId ?? 'default'}',
          storageId: storageId,
        ),
      SceneWarpInteractiveCommand() => throw StateError(
          'Warp commands are not world services.',
        ),
      _ => throw StateError(
          'Unsupported world-service command: ${command.kind.name}.',
        ),
    };
  }
}
