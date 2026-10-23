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
    this.giveItem,
    this.moveNpc,
    this.movePlatform,
    this.setPropState,
    this.openShop,
    this.openHeal,
    this.whiteOut,
    this.openPc,
    this.playCharacterAnimation,
    this.playModelAnimation,
    this.railJourney,
    this.worldTone,
    this.wait,
    this.waitForActorRoutes,
    this.playSoundEffect,
    this.playMusicEffect,
    this.sceneMusic,
    this.actorRoute,
    this.actorVisibility,
    this.openWorldService,
  });

  final SceneInteractiveCommandHandler warp;
  final SceneInteractiveCommandHandler? giveItem;
  final SceneInteractiveCommandHandler? moveNpc;
  final SceneInteractiveCommandHandler? movePlatform;
  final SceneInteractiveCommandHandler? setPropState;
  final SceneInteractiveCommandHandler? openShop;
  final SceneInteractiveCommandHandler? openHeal;
  final SceneInteractiveCommandHandler? whiteOut;
  final SceneInteractiveCommandHandler? openPc;
  final SceneInteractiveCommandHandler? playCharacterAnimation;
  final SceneInteractiveCommandHandler? playModelAnimation;
  final SceneInteractiveCommandHandler? railJourney;
  final SceneInteractiveCommandHandler? worldTone;
  final SceneInteractiveCommandHandler? wait;
  final SceneInteractiveCommandHandler? waitForActorRoutes;
  final SceneInteractiveCommandHandler? playSoundEffect;
  final SceneInteractiveCommandHandler? playMusicEffect;
  final SceneInteractiveCommandHandler? sceneMusic;
  final SceneInteractiveCommandHandler? actorRoute;
  final SceneInteractiveCommandHandler? actorVisibility;
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
      SceneInteractiveCommandKind.inputIntegerToFact || SceneInteractiveCommandKind.tryPayMoney => throw StateError('Integer input and payment require the Scene transaction host.'),
      SceneInteractiveCommandKind.inputTextToFact => throw StateError('Text Fact input requires the Scene transaction host.'),
      SceneInteractiveCommandKind.receivePokemonFromCatalog => throw StateError('Pokemon gifts require the Scene transaction host.'),
      SceneInteractiveCommandKind.giveItem => await _executeRequired(
          command,
          handler: giveItem,
        ),
      SceneInteractiveCommandKind.warp => await warp(command),
      SceneInteractiveCommandKind.movePlatform => await _executeRequired(command, handler: movePlatform),
      SceneInteractiveCommandKind.setPropState => await _executeRequired(command, handler: setPropState),
      SceneInteractiveCommandKind.moveNpc => await _executeRequired(
          command,
          handler: moveNpc,
        ),
      SceneInteractiveCommandKind.openShop => await _executeService(
          command,
          legacyHandler: openShop,
        ),
      SceneInteractiveCommandKind.openHeal => await _executeService(
          command,
          legacyHandler: openHeal,
        ),
      SceneInteractiveCommandKind.whiteOut => await _executeRequired(
        command,
        handler: whiteOut,
      ),
      SceneInteractiveCommandKind.openPc => await _executeService(
          command,
          legacyHandler: openPc,
        ),
      SceneInteractiveCommandKind.openPartyTrade => await _executeService(
        command,
        legacyHandler: null,
      ),
      SceneInteractiveCommandKind.openRegionalMap => await _executeService(
          command,
          legacyHandler: null,
        ),
      SceneInteractiveCommandKind.playCharacterAnimation =>
        await _executeRequired(
          command,
          handler: playCharacterAnimation,
        ),
      SceneInteractiveCommandKind.playModelAnimation => await _executeRequired(
          command,
          handler: playModelAnimation,
        ),
      SceneInteractiveCommandKind.railJourney => await _executeRequired(
          command,
          handler: railJourney,
        ),
      SceneInteractiveCommandKind.wait => await _executeRequired(
          command,
          handler: wait,
        ),
      SceneInteractiveCommandKind.waitForActorRoutes => await _executeRequired(
          command,
          handler: waitForActorRoutes,
        ),
      SceneInteractiveCommandKind.worldTone => await _executeRequired(
          command,
          handler: worldTone,
        ),
      SceneInteractiveCommandKind.sceneMusic => await _executeRequired(command, handler: sceneMusic),
      SceneInteractiveCommandKind.playMusicEffect => await _executeRequired(command, handler: playMusicEffect),
      SceneInteractiveCommandKind.playSoundEffect => await _executeRequired(
          command,
          handler: playSoundEffect,
        ),
      SceneInteractiveCommandKind.actorRoute => await _executeRequired(
          command,
          handler: actorRoute,
        ),
      SceneInteractiveCommandKind.actorVisibility => await _executeRequired(
          command,
          handler: actorVisibility,
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

  Future<String> _executeRequired(
    SceneInteractiveCommand command, {
    required SceneInteractiveCommandHandler? handler,
  }) {
    if (handler == null) {
      throw StateError(
        'No handler is installed for ${command.kind.name}.',
      );
    }
    return handler(command);
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
      SceneOpenHealInteractiveCommand(:final requiresConfirmation, :final displayEntityId) =>
        OpenHealService(
          interactionId: 'scene.openHeal',
          requiresConfirmation: requiresConfirmation,
          displayEntityId: displayEntityId,
        ),
      SceneOpenPcInteractiveCommand(:final storageId) => OpenPcService(
          interactionId: 'scene.openPc:${storageId ?? 'default'}',
          storageId: storageId,
        ),
      SceneOpenPartyTradeInteractiveCommand() => const OpenPartyTradeService(
        interactionId: 'scene.openPartyTrade',
      ),
      SceneOpenRegionalMapInteractiveCommand() => const OpenRegionalMapService(
          interactionId: 'scene.openRegionalMap',
        ),
      SceneWarpInteractiveCommand() => throw StateError(
          'Warp commands are not world services.',
        ),
      SceneMoveNpcInteractiveCommand() => throw StateError(
          'NPC movement commands are not world services.',
        ),
      SceneCharacterCustomAnimationInteractiveCommand() => throw StateError(
          'Character animation commands are not world services.',
        ),
      _ => throw StateError(
          'Unsupported world-service command: ${command.kind.name}.',
        ),
    };
  }
}
