import 'spatial_visual_profile.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:characters/characters.dart';

import '../runtime/character_custom_animation_runtime_contract.dart';
import 'rail_journey.dart';
import 'moving_platform.dart';
import 'moving_prop.dart';
import 'enums.dart';
import 'scene_actor_route.dart';
import 'dialogue_line_feedback.dart';
import 'scene_warp_presentation.dart';
import 'scene_pokemon_gift_moves.dart';
import 'scene_structured_interaction.dart';
import 'scene_integer_operand.dart';

part 'scene_integer_commands.dart';
part 'scene_world_presentation_commands.dart';

enum SceneInteractiveCommandKind {
  inputIntegerToFact,
  tryPayMoney,
  inputTextToFact,
  giveItem,
  receivePokemonFromCatalog,
  warp,
  wait,
  waitForActorRoutes,
  worldTone,
  worldPresentation,
  playSoundEffect,
  stopSoundEffects,
  playMusicEffect,
  sceneMusic,
  actorRoute,
  actorVisibility,
  moveNpc,
  movePlatform,
  setPropState,
  openShop,
  openHeal,
  whiteOut,
  openPc,
  openRegionalMap,
  openPartyTrade,
  playCharacterAnimation,
  playModelAnimation,
  railJourney,
}

enum ScenePokemonGiftNicknamePolicy { disabled, offer }

enum ScenePokemonGiftPokedexPresentationPolicy { never, whenNewAndPokedexVisible }

enum SceneRailJourneyOperation { begin, advance, acknowledge }

enum SceneMusicOperation { play, restore, fadeOut, stop, memorize, restoreMemorized }

enum SceneMusicChannel { music, ambience, both }

enum SceneMusicScope { scene, map }

enum SceneWarpTransition { mapDefault, none }

enum SceneRailJourneyAdvanceEvent {
  doorsClosed,
  arrivalReached,
  destinationDoorUsed,
}

@immutable
abstract base class SceneInteractiveCommand {
  const SceneInteractiveCommand();

  factory SceneInteractiveCommand.inputIntegerToFact({required String factId,
    required SceneInteractionPrompt prompt, required int digits, required int minimum, required int maximum,
    int? initialValue, bool allowCancel, SceneIntegerCancellationPolicy cancellationPolicy,
  }) = SceneInputIntegerToFactInteractiveCommand;

  factory SceneInteractiveCommand.tryPayMoney({required SceneIntegerOperand amount,
    SceneInteractionPrompt? confirmationPrompt,
  }) = SceneTryPayMoneyInteractiveCommand;

  factory SceneInteractiveCommand.inputTextToFact({
    required String factId,
    required SceneInteractionPrompt prompt,
    required SceneInteractionPrompt confirmationPrompt,
    required SceneTextInputConstraints constraints,
    List<String> presetValues,
    String? customChoiceLabel,
    SceneInteractionPrompt? presetChoicePrompt,
  }) = SceneInputTextToFactInteractiveCommand;

  factory SceneInteractiveCommand.giveItem({
    required String itemId,
    required int quantity,
  }) = SceneGiveItemInteractiveCommand;

  factory SceneInteractiveCommand.receivePokemonFromCatalog({
    required String speciesId,
    required String formId,
    required int level,
    required ScenePokemonGiftNicknamePolicy nicknamePolicy,
    required int nicknameMaxGraphemes,
    required ScenePokemonGiftPokedexPresentationPolicy pokedexPresentationPolicy,
    List<String>? moveIds,
  }) = SceneReceivePokemonFromCatalogInteractiveCommand;

  factory SceneInteractiveCommand.warp({
    required String destinationMapId,
    required String warpId,
    EntityFacing? arrivalFacing,
    SceneWarpTransition transition,
    String? arrivalCollisionOwnerEntityId,
    SceneWarpPresentation? presentation,
  }) = SceneWarpInteractiveCommand;

  factory SceneInteractiveCommand.wait({required int durationMs}) =
      SceneWaitInteractiveCommand;

  factory SceneInteractiveCommand.waitForActorRoutes({required String mapId}) =
      SceneWaitForActorRoutesInteractiveCommand;

  factory SceneInteractiveCommand.worldTone({
    required double red,
    required double green,
    required double blue,
    required double gray,
    required int durationMs,
  }) = SceneWorldToneInteractiveCommand;

  factory SceneInteractiveCommand.worldPresentation({
    required SceneWorldPresentationOperation operation,
    SpatialVisualPatch? visualSettings,
    SceneVisualScope scope,
    int? slotId,
    String? mediaAssetId,
    int? referenceWidth,
    int? referenceHeight,
    double? x,
    double? y,
    double scaleX,
    double scaleY,
    double opacity,
    ScenePictureOrigin origin,
    double? red,
    double? green,
    double? blue,
    double? alpha,
    double? power,
    double? speed,
    int durationMs,
    bool waitForCompletion,
  }) = SceneWorldPresentationInteractiveCommand;

  factory SceneInteractiveCommand.playSoundEffect({
    required String mediaAssetId,
    required double volume,
    bool waitForCompletion,
  }) = ScenePlaySoundEffectInteractiveCommand;

  factory SceneInteractiveCommand.stopSoundEffects({
    SceneMusicScope scope,
  }) = SceneStopSoundEffectsInteractiveCommand;

  factory SceneInteractiveCommand.playMusicEffect({
    required String mediaAssetId,
    required double volume,
    required DialogueBgmInterruption bgmInterruption,
    bool waitForCompletion,
  }) = ScenePlayMusicEffectInteractiveCommand;

  factory SceneInteractiveCommand.sceneMusic({
    required SceneMusicOperation operation,
    SceneMusicChannel channel,
    SceneMusicScope scope,
    String? mediaAssetId,
    double? volume,
    int? durationMs,
  }) = SceneMusicInteractiveCommand;

  factory SceneInteractiveCommand.actorRoute({
    required SceneActorTarget target,
    required List<SceneActorRouteStep> steps,
    bool skippable,
    ActorRouteTransientScope transientScope,
  }) = SceneActorRouteInteractiveCommand;

  factory SceneInteractiveCommand.actorVisibility({
    required SceneActorTarget target,
    required bool visible,
  }) = SceneActorVisibilityInteractiveCommand;

  factory SceneInteractiveCommand.moveNpc({
    required String mapId,
    required String entityId,
    required String warpId,
  }) = SceneMoveNpcInteractiveCommand;

  factory SceneInteractiveCommand.movePlatform({
    required String mapId,
    required String platformId,
    required MovingPlatformMotion motion,
  }) = SceneMovePlatformInteractiveCommand;

  factory SceneInteractiveCommand.setPropState({
    required String mapId,
    required List<String> propIds,
    required MovingPropState state,
    int durationMs,
  }) = SceneSetPropStateInteractiveCommand;

  factory SceneInteractiveCommand.openShop({required String shopId}) =
      SceneOpenShopInteractiveCommand;

  factory SceneInteractiveCommand.openHeal({bool requiresConfirmation, String? displayEntityId}) =
      SceneOpenHealInteractiveCommand;

  factory SceneInteractiveCommand.openPc({String storageId}) =
      SceneOpenPcInteractiveCommand;

  factory SceneInteractiveCommand.whiteOut() = SceneWhiteOutInteractiveCommand;

  factory SceneInteractiveCommand.openRegionalMap() =
      SceneOpenRegionalMapInteractiveCommand;

  factory SceneInteractiveCommand.openPartyTrade() =
      SceneOpenPartyTradeInteractiveCommand;

  factory SceneInteractiveCommand.playCharacterAnimation({
    required CharacterCustomAnimationRuntimeCommand runtimeCommand,
  }) = SceneCharacterCustomAnimationInteractiveCommand;

  factory SceneInteractiveCommand.railJourney({
    required String commandId,
    required String journeyId,
    required SceneRailJourneyOperation operation,
    RailJourneyDirection? direction,
    SceneRailJourneyAdvanceEvent? advanceEvent,
    RailJourneyDoorSide? doorSide,
  }) = SceneRailJourneyInteractiveCommand;

  factory SceneInteractiveCommand.playModelAnimation({
    required String mapId,
    required String instanceId,
    required int animationIndex,
    double speed,
    bool? blocksMovementAfter,
  }) = ScenePlayModelAnimationInteractiveCommand;

  factory SceneInteractiveCommand.fromJson(Map<String, dynamic> json) {
    final kind = SceneInteractiveCommandKind.values.firstWhere(
      (value) => value.name == json['kind'],
      orElse: () => throw FormatException(
        'Unknown SceneInteractiveCommand kind: ${json['kind']}',
      ),
    );
    return switch (kind) {
      SceneInteractiveCommandKind.inputIntegerToFact => SceneInputIntegerToFactInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.tryPayMoney => SceneTryPayMoneyInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.inputTextToFact =>
        SceneInputTextToFactInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.receivePokemonFromCatalog =>
        SceneReceivePokemonFromCatalogInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.giveItem => SceneGiveItemInteractiveCommand(
        itemId: _required(json, 'itemId'),
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : throw const FormatException('Item quantity must be an integer.'),
      ),
      SceneInteractiveCommandKind.warp => SceneWarpInteractiveCommand(
        presentation: json.containsKey('presentation')
            ? json['presentation'] is Map<String, dynamic>
                ? SceneWarpPresentation.fromJson(json['presentation'] as Map<String, dynamic>)
                : throw const FormatException('Warp presentation must be an object.')
            : null,
        destinationMapId: _warpDestinationMapId(json),
        warpId: _required(json, 'warpId'),
        arrivalFacing: _optionalEnum(
          json,
          'arrivalFacing',
          EntityFacing.values,
        ),
        transition: json.containsKey('transition')
            ? _optionalEnum(json, 'transition', SceneWarpTransition.values) ??
                (throw const FormatException('transition must be a string.'))
            : SceneWarpTransition.mapDefault,
        arrivalCollisionOwnerEntityId:
            json.containsKey('arrivalCollisionOwnerEntityId')
            ? _arrivalCollisionOwner(json['arrivalCollisionOwnerEntityId'])
            : null,
      ),
      SceneInteractiveCommandKind.wait =>
        SceneWaitInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.waitForActorRoutes =>
        SceneWaitForActorRoutesInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.worldTone =>
        SceneWorldToneInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.worldPresentation =>
        SceneWorldPresentationInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.playMusicEffect =>
        ScenePlayMusicEffectInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.sceneMusic =>
        SceneMusicInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.playSoundEffect =>
        ScenePlaySoundEffectInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.stopSoundEffects =>
        SceneStopSoundEffectsInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.actorRoute =>
        SceneActorRouteInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.actorVisibility =>
        SceneActorVisibilityInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.moveNpc => SceneMoveNpcInteractiveCommand(
        mapId: _required(json, 'mapId'),
        entityId: _required(json, 'entityId'),
        warpId: _required(json, 'warpId'),
      ),
      SceneInteractiveCommandKind.movePlatform => SceneMovePlatformInteractiveCommand(
        mapId: _required(json, 'mapId'), platformId: _required(json, 'platformId'),
        motion: _requiredEnum(json, 'motion', MovingPlatformMotion.values),
      ),
      SceneInteractiveCommandKind.setPropState =>
        SceneSetPropStateInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.openShop => SceneOpenShopInteractiveCommand(
        shopId: _required(json, 'shopId'),
      ),
      SceneInteractiveCommandKind.openHeal => SceneOpenHealInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.whiteOut => SceneWhiteOutInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.openPc => SceneOpenPcInteractiveCommand(
        storageId: _optional(json, 'storageId'),
      ),
      SceneInteractiveCommandKind.openRegionalMap =>
        SceneOpenRegionalMapInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.openPartyTrade =>
        SceneOpenPartyTradeInteractiveCommand.fromJson(json),
      SceneInteractiveCommandKind.playCharacterAnimation =>
        SceneCharacterCustomAnimationInteractiveCommand(
          runtimeCommand: CharacterCustomAnimationRuntimeCommand.fromJson(
            _requiredObject(json, 'runtimeCommand'),
          ),
        ),
      SceneInteractiveCommandKind.playModelAnimation =>
        ScenePlayModelAnimationInteractiveCommand(
          mapId: _required(json, 'mapId'),
          instanceId: _required(json, 'instanceId'),
          animationIndex: json['animationIndex'] is int
              ? json['animationIndex'] as int
              : throw const FormatException(
                  'Model animation index must be an integer.',
                ),
          speed: json['speed'] is num
              ? (json['speed'] as num).toDouble()
              : throw const FormatException(
                  'Model animation speed must be a number.',
                ),
          blocksMovementAfter: _optionalBool(json, 'blocksMovementAfter'),
        ),
      SceneInteractiveCommandKind.railJourney =>
        SceneRailJourneyInteractiveCommand(
          commandId: _required(json, 'commandId'),
          journeyId: _required(json, 'journeyId'),
          operation: _requiredEnum(
            json,
            'operation',
            SceneRailJourneyOperation.values,
          ),
          direction: _optionalRailJourneyDirection(json, 'direction'),
          advanceEvent: _optionalEnum(
            json,
            'advanceEvent',
            SceneRailJourneyAdvanceEvent.values,
          ),
          doorSide: _optionalEnum(json, 'doorSide', RailJourneyDoorSide.values),
        ),
    };
  }

  SceneInteractiveCommandKind get kind;
  List<String> get outputPortIds;
  Map<String, dynamic> toJson();
}

@immutable
final class SceneActorRouteInteractiveCommand extends SceneInteractiveCommand {
  SceneActorRouteInteractiveCommand({
    required this.target,
    required List<SceneActorRouteStep> steps,
    this.skippable = false,
    this.transientScope = ActorRouteTransientScope.route,
  }) : steps = List.unmodifiable(steps) {
    var through = false;
    for (final step in this.steps) {
      if (step is SceneActorThroughStep) {
        through = step.enabled;
      } else if (step is SceneActorMoveStep &&
          step.initialCollisionOwnerEntityId != null &&
          (target.kind != SceneActorTargetKind.player || through)) {
        throw ArgumentError(
          'An initial collision owner requires a player movement without through.',
        );
      }
    }
  }

  factory SceneActorRouteInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json.keys.any(
          (key) =>
              !const {'kind', 'target', 'steps', 'skippable', 'transientScope'}.contains(key),
        ) ||
        json['kind'] != 'actorRoute' ||
        json['steps'] is! List ||
        (json.containsKey('skippable') && json['skippable'] is! bool)) {
      throw const FormatException('Invalid actor route command.');
    }
    try {
      return SceneActorRouteInteractiveCommand(
        target: SceneActorTarget.fromJson(
          _actorCommandObject(json['target'], 'target'),
        ),
        steps: [
          for (final step in json['steps'] as List)
            SceneActorRouteStep.fromJson(_actorCommandObject(step, 'step')),
        ],
        skippable: json['skippable'] as bool? ?? false,
        transientScope: json.containsKey('transientScope')
          ? ActorRouteTransientScope.values.firstWhere((value) => value.name == json['transientScope'],
              orElse: () => throw const FormatException('Unknown actor route transient scope.'))
          : ActorRouteTransientScope.route,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final SceneActorTarget target;
  final List<SceneActorRouteStep> steps;
  final bool skippable;
  final ActorRouteTransientScope transientScope;
  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.actorRoute;
  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'target': target.toJson(),
    'steps': steps.map((step) => step.toJson()).toList(),
    'skippable': skippable,
    if (transientScope != ActorRouteTransientScope.route) 'transientScope': transientScope.name,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneActorRouteInteractiveCommand &&
      target == other.target &&
      skippable == other.skippable &&
      transientScope == other.transientScope &&
      steps.length == other.steps.length &&
      Iterable<int>.generate(
        steps.length,
      ).every((index) => steps[index] == other.steps[index]);
  @override
  int get hashCode =>
      Object.hash(kind, target, skippable, transientScope, Object.hashAll(steps));
}

@immutable
final class SceneActorVisibilityInteractiveCommand
    extends SceneInteractiveCommand {
  const SceneActorVisibilityInteractiveCommand({
    required this.target,
    required this.visible,
  });

  factory SceneActorVisibilityInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    _presentationCommandFields(json, const {'kind', 'target', 'visible'});
    if (json['kind'] != 'actorVisibility' || json['visible'] is! bool) {
      throw const FormatException('Invalid actor visibility command.');
    }
    return SceneActorVisibilityInteractiveCommand(
      target: SceneActorTarget.fromJson(
        _actorCommandObject(json['target'], 'target'),
      ),
      visible: json['visible'] as bool,
    );
  }

  final SceneActorTarget target;
  final bool visible;
  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.actorVisibility;
  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'target': target.toJson(),
    'visible': visible,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneActorVisibilityInteractiveCommand &&
      target == other.target &&
      visible == other.visible;
  @override
  int get hashCode => Object.hash(kind, target, visible);
}

Map<String, dynamic> _actorCommandObject(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$field must be an object with string fields.');
  }
  return Map<String, dynamic>.from(value);
}

@immutable
final class SceneWaitForActorRoutesInteractiveCommand
    extends SceneInteractiveCommand {
  SceneWaitForActorRoutesInteractiveCommand({required this.mapId}) {
    if (mapId.isEmpty || mapId.trim() != mapId) {
      throw ArgumentError.value(mapId, 'mapId', 'Must be nonempty and already trimmed.');
    }
  }

  factory SceneWaitForActorRoutesInteractiveCommand.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 || json['kind'] != 'waitForActorRoutes' || json['mapId'] is! String) {
      throw const FormatException('Invalid global actor route wait command.');
    }
    return SceneWaitForActorRoutesInteractiveCommand(mapId: json['mapId'] as String);
  }

  final String mapId;
  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.waitForActorRoutes;
  @override
  List<String> get outputPortIds => const ['completed'];
  @override
  Map<String, dynamic> toJson() => {'kind': kind.name, 'mapId': mapId};
  @override
  bool operator ==(Object other) =>
      other is SceneWaitForActorRoutesInteractiveCommand &&
      other.mapId == mapId;
  @override
  int get hashCode => Object.hash(kind, mapId);
}

@immutable
final class SceneWaitInteractiveCommand extends SceneInteractiveCommand {
  SceneWaitInteractiveCommand({required this.durationMs}) {
    if (durationMs < 0 || durationMs > 0x7fffffff) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'Must be a nonnegative int32.',
      );
    }
  }

  factory SceneWaitInteractiveCommand.fromJson(Map<String, dynamic> json) {
    _presentationCommandFields(json, const {'kind', 'durationMs'});
    if (json['kind'] != 'wait' || json['durationMs'] is! int) {
      throw const FormatException('Invalid world wait command.');
    }
    return SceneWaitInteractiveCommand(durationMs: json['durationMs'] as int);
  }

  final int durationMs;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.wait;
  @override
  List<String> get outputPortIds => const ['completed'];
  @override
  Map<String, dynamic> toJson() => {'kind': kind.name, 'durationMs': durationMs};
  @override
  bool operator ==(Object other) =>
      other is SceneWaitInteractiveCommand && other.durationMs == durationMs;
  @override
  int get hashCode => Object.hash(kind, durationMs);
}

@immutable
final class SceneWorldToneInteractiveCommand extends SceneInteractiveCommand {
  SceneWorldToneInteractiveCommand({
    required double red,
    required double green,
    required double blue,
    required double gray,
    required this.durationMs,
  }) : red = _boundedPresentationNumber(red, 'red', -255, 255),
       green = _boundedPresentationNumber(green, 'green', -255, 255),
       blue = _boundedPresentationNumber(blue, 'blue', -255, 255),
       gray = _boundedPresentationNumber(gray, 'gray', 0, 255) {
    if (durationMs < 0 || durationMs > 0x7fffffff) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'Must be a nonnegative int32.',
      );
    }
  }

  factory SceneWorldToneInteractiveCommand.fromJson(Map<String, dynamic> json) {
    _presentationCommandFields(json, const {
      'kind',
      'red',
      'green',
      'blue',
      'gray',
      'durationMs',
    });
    if (json['kind'] != 'worldTone' || json['durationMs'] is! int) {
      throw const FormatException('Invalid world tone command.');
    }
    return SceneWorldToneInteractiveCommand(
      red: _presentationNumber(json, 'red'),
      green: _presentationNumber(json, 'green'),
      blue: _presentationNumber(json, 'blue'),
      gray: _presentationNumber(json, 'gray'),
      durationMs: json['durationMs'] as int,
    );
  }

  final double red;
  final double green;
  final double blue;
  final double gray;
  final int durationMs;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.worldTone;
  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'red': red,
    'green': green,
    'blue': blue,
    'gray': gray,
    'durationMs': durationMs,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneWorldToneInteractiveCommand &&
      other.red == red &&
      other.green == green &&
      other.blue == blue &&
      other.gray == gray &&
      other.durationMs == durationMs;
  @override
  int get hashCode => Object.hash(red, green, blue, gray, durationMs);
}

@immutable
final class ScenePlaySoundEffectInteractiveCommand
    extends SceneInteractiveCommand {
  ScenePlaySoundEffectInteractiveCommand({
    required String mediaAssetId,
    required double volume,
    this.waitForCompletion = false,
  }) : mediaAssetId = _normalize(mediaAssetId, 'mediaAssetId'),
       volume = _boundedPresentationNumber(volume, 'volume', 0, 1);

  factory ScenePlaySoundEffectInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    _presentationCommandFields(json, {'kind', 'mediaAssetId', 'volume', if (json.containsKey('waitForCompletion')) 'waitForCompletion'});
    if (json.containsKey('waitForCompletion') && json['waitForCompletion'] is! bool) {
      throw const FormatException('waitForCompletion must be a boolean.');
    }
    if (json['kind'] != 'playSoundEffect') {
      throw const FormatException('Invalid sound effect command.');
    }
    return ScenePlaySoundEffectInteractiveCommand(
      mediaAssetId: _required(json, 'mediaAssetId'),
      volume: _presentationNumber(json, 'volume'),
      waitForCompletion: json['waitForCompletion'] as bool? ?? false,
    );
  }

  final String mediaAssetId;
  final double volume;
  final bool waitForCompletion;

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.playSoundEffect;
  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mediaAssetId': mediaAssetId,
    'volume': volume,
    if (waitForCompletion) 'waitForCompletion': true,
  };
  @override
  bool operator ==(Object other) =>
      other is ScenePlaySoundEffectInteractiveCommand &&
      other.mediaAssetId == mediaAssetId &&
      other.volume == volume && other.waitForCompletion == waitForCompletion;
  @override
  int get hashCode => Object.hash(mediaAssetId, volume, waitForCompletion);
}

final class ScenePlayMusicEffectInteractiveCommand extends SceneInteractiveCommand {
  ScenePlayMusicEffectInteractiveCommand({
    required String mediaAssetId,
    required double volume,
    required this.bgmInterruption,
    this.waitForCompletion = false,
  }) : mediaAssetId = _normalize(mediaAssetId, 'mediaAssetId'),
       volume = _boundedPresentationNumber(volume, 'volume', 0, 1);

  factory ScenePlayMusicEffectInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    _presentationCommandFields(json, {
      'kind', 'mediaAssetId', 'volume', 'bgmInterruption',
      if (json.containsKey('waitForCompletion')) 'waitForCompletion',
    });
    if (json.containsKey('waitForCompletion') && json['waitForCompletion'] is! bool) {
      throw const FormatException('waitForCompletion must be a boolean.');
    }
    if (json['kind'] != 'playMusicEffect' || json['bgmInterruption'] is! Map) {
      throw const FormatException('Invalid music effect command.');
    }
    return ScenePlayMusicEffectInteractiveCommand(
      mediaAssetId: _required(json, 'mediaAssetId'),
      volume: _presentationNumber(json, 'volume'),
      waitForCompletion: json['waitForCompletion'] as bool? ?? false,
      bgmInterruption: DialogueBgmInterruption.fromJson(
        Map<String, dynamic>.from(json['bgmInterruption'] as Map),
      ),
    );
  }

  final String mediaAssetId;
  final double volume;
  final DialogueBgmInterruption bgmInterruption;
  final bool waitForCompletion;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.playMusicEffect;

  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mediaAssetId': mediaAssetId,
    'volume': volume,
    'bgmInterruption': bgmInterruption.toJson(),
    if (waitForCompletion) 'waitForCompletion': true,
  };

  @override
  bool operator ==(Object other) =>
      other is ScenePlayMusicEffectInteractiveCommand &&
      other.mediaAssetId == mediaAssetId &&
      other.volume == volume &&
      other.bgmInterruption == bgmInterruption && other.waitForCompletion == waitForCompletion;

  @override
  int get hashCode => Object.hash(mediaAssetId, volume, bgmInterruption, waitForCompletion);
}

final class SceneMusicInteractiveCommand extends SceneInteractiveCommand {
  SceneMusicInteractiveCommand({
    required this.operation,
    this.channel = SceneMusicChannel.music,
    this.scope = SceneMusicScope.scene,
    String? mediaAssetId,
    double? volume,
    this.durationMs,
  }) : mediaAssetId = mediaAssetId == null ? null : _normalize(mediaAssetId, 'mediaAssetId'),
       volume = volume == null ? null : _boundedPresentationNumber(volume, 'volume', 0, 1) {
    final valid = switch (operation) {
      SceneMusicOperation.play => this.mediaAssetId != null && this.volume != null && durationMs == null,
      SceneMusicOperation.restore || SceneMusicOperation.stop || SceneMusicOperation.memorize || SceneMusicOperation.restoreMemorized => this.mediaAssetId == null && this.volume == null && durationMs == null,
      SceneMusicOperation.fadeOut => this.mediaAssetId == null && this.volume == null && durationMs != null && durationMs! >= 0 && durationMs! <= 60000,
    };
    if (!valid || (channel == SceneMusicChannel.both && operation != SceneMusicOperation.memorize && operation != SceneMusicOperation.restoreMemorized)) {
      throw ArgumentError('Audio parameters do not match the operation.');
    }
  }

  factory SceneMusicInteractiveCommand.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'sceneMusic') throw const FormatException('Invalid audio command.');
    final operation = SceneMusicOperation.values.where((v) => v.name == json['operation']).firstOrNull;
    if (operation == null) throw const FormatException('Invalid audio operation.');
    _presentationCommandFields(json, {...switch (operation) {
      SceneMusicOperation.play => const {'kind', 'operation', 'mediaAssetId', 'volume'},
      SceneMusicOperation.restore || SceneMusicOperation.stop || SceneMusicOperation.memorize || SceneMusicOperation.restoreMemorized => const {'kind', 'operation'},
      SceneMusicOperation.fadeOut => const {'kind', 'operation', 'durationMs'},
    }, if (json.containsKey('channel')) 'channel', if (json.containsKey('scope')) 'scope'});
    final channel = json.containsKey('channel') ? SceneMusicChannel.values.where((v) => v.name == json['channel']).firstOrNull : SceneMusicChannel.music;
    final scope = json.containsKey('scope') ? SceneMusicScope.values.where((v) => v.name == json['scope']).firstOrNull : SceneMusicScope.scene;
    if (channel == null || scope == null) throw const FormatException('Invalid audio channel or scope.');
    if (operation == SceneMusicOperation.fadeOut && json['durationMs'] is! int) throw const FormatException('durationMs must be an integer.');
    return SceneMusicInteractiveCommand(
      operation: operation, channel: channel, scope: scope,
      mediaAssetId: operation == SceneMusicOperation.play ? _required(json, 'mediaAssetId') : null,
      volume: operation == SceneMusicOperation.play ? _presentationNumber(json, 'volume') : null,
      durationMs: operation == SceneMusicOperation.fadeOut ? json['durationMs'] as int : null,
    );
  }

  final SceneMusicOperation operation;
  final SceneMusicChannel channel;
  final SceneMusicScope scope;
  final String? mediaAssetId;
  final double? volume;
  final int? durationMs;
  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.sceneMusic;
  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name, 'operation': operation.name,
    if (channel != SceneMusicChannel.music || scope != SceneMusicScope.scene) 'channel': channel.name,
    if (channel != SceneMusicChannel.music || scope != SceneMusicScope.scene) 'scope': scope.name,
    if (operation == SceneMusicOperation.play) 'mediaAssetId': mediaAssetId!,
    if (operation == SceneMusicOperation.play) 'volume': volume!,
    if (operation == SceneMusicOperation.fadeOut) 'durationMs': durationMs!,
  };
  @override
  bool operator ==(Object other) => other is SceneMusicInteractiveCommand && operation == other.operation && channel == other.channel && scope == other.scope && mediaAssetId == other.mediaAssetId && volume == other.volume && durationMs == other.durationMs;
  @override
  int get hashCode => Object.hash(operation, channel, scope, mediaAssetId, volume, durationMs);
}

final class SceneStopSoundEffectsInteractiveCommand extends SceneInteractiveCommand {
  const SceneStopSoundEffectsInteractiveCommand({this.scope = SceneMusicScope.scene});
  factory SceneStopSoundEffectsInteractiveCommand.fromJson(Map<String, dynamic> json) {
    _presentationCommandFields(json, const {'kind', 'scope'});
    if (json['kind'] != 'stopSoundEffects') throw const FormatException('Invalid stop effects command.');
    final scope = SceneMusicScope.values.where((value) => value.name == json['scope']).firstOrNull;
    if (scope == null) throw const FormatException('Invalid sound effects scope.');
    return SceneStopSoundEffectsInteractiveCommand(scope: scope);
  }
  final SceneMusicScope scope;
  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.stopSoundEffects;
  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];
  @override
  Map<String, dynamic> toJson() => {'kind': kind.name, 'scope': scope.name};
  @override
  bool operator ==(Object other) => other is SceneStopSoundEffectsInteractiveCommand && other.scope == scope;
  @override
  int get hashCode => Object.hash(kind, scope);
}

void _presentationCommandFields(Map<String, dynamic> json, Set<String> fields) {
  final keys = json.keys.toSet();
  if (keys.difference(fields).isNotEmpty ||
      fields.difference(keys).isNotEmpty) {
    throw const FormatException(
      'Presentation command fields do not match the contract.',
    );
  }
}

double _presentationNumber(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! num) {
    throw FormatException('$field must be a number.');
  }
  return value.toDouble();
}

double _boundedPresentationNumber(
  double value,
  String field,
  double minimum,
  double maximum,
) {
  if (!value.isFinite || value < minimum || value > maximum) {
    throw ArgumentError.value(
      value,
      field,
      'Must be finite in [$minimum, $maximum].',
    );
  }
  return value;
}

@immutable
final class SceneMovePlatformInteractiveCommand
    extends SceneInteractiveCommand {
  SceneMovePlatformInteractiveCommand({
    required String mapId,
    required String platformId,
    required this.motion,
  }) : mapId = _normalize(mapId, 'mapId'),
       platformId = _normalize(platformId, 'platformId');

  final String mapId, platformId;
  final MovingPlatformMotion motion;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.movePlatform;
  @override
  List<String> get outputPortIds => const [
    'moved',
    'blocked',
    'notRiding',
    'rotationRequiresPivot',
  ];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mapId': mapId,
    'platformId': platformId,
    'motion': motion.name,
  };
  @override
  bool operator ==(Object other) => other is SceneMovePlatformInteractiveCommand &&
      other.mapId == mapId && other.platformId == platformId && other.motion == motion;
  @override
  int get hashCode => Object.hash(mapId, platformId, motion);
}

@immutable
final class SceneGiveItemInteractiveCommand extends SceneInteractiveCommand {
  SceneGiveItemInteractiveCommand({
    required String itemId,
    required this.quantity,
  }) : itemId = _normalize(itemId, 'itemId') {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive.');
    }
  }

  final String itemId;
  final int quantity;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.giveItem;

  @override
  List<String> get outputPortIds => const ['received', 'bagFull'];

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'itemId': itemId,
        'quantity': quantity,
      };

  @override
  bool operator ==(Object other) =>
      other is SceneGiveItemInteractiveCommand &&
      other.itemId == itemId && other.quantity == quantity;

  @override
  int get hashCode => Object.hash(itemId, quantity);
}

@immutable
final class ScenePlayModelAnimationInteractiveCommand
    extends SceneInteractiveCommand {
  ScenePlayModelAnimationInteractiveCommand({
    required String mapId,
    required String instanceId,
    required this.animationIndex,
    this.speed = 1,
    this.blocksMovementAfter,
  }) : mapId = _normalize(mapId, 'mapId'),
       instanceId = _normalize(instanceId, 'instanceId') {
    if (animationIndex < 0 || !speed.isFinite || speed <= 0 || speed > 16) {
      throw const FormatException('Invalid model animation command.');
    }
  }

  final String mapId, instanceId;
  final int animationIndex;
  final double speed;
  final bool? blocksMovementAfter;

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.playModelAnimation;

  @override
  List<String> get outputPortIds => const ['completed', 'blocked', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mapId': mapId,
    'instanceId': instanceId,
    'animationIndex': animationIndex,
    'speed': speed,
    if (blocksMovementAfter != null) 'blocksMovementAfter': blocksMovementAfter,
  };

  @override
  bool operator ==(Object other) =>
      other is ScenePlayModelAnimationInteractiveCommand &&
      other.mapId == mapId &&
      other.instanceId == instanceId &&
      other.animationIndex == animationIndex &&
      other.speed == speed &&
      other.blocksMovementAfter == blocksMovementAfter;

  @override
  int get hashCode => Object.hash(
    mapId,
    instanceId,
    animationIndex,
    speed,
    blocksMovementAfter,
  );
}

@immutable
final class SceneSetPropStateInteractiveCommand extends SceneInteractiveCommand {
  SceneSetPropStateInteractiveCommand({
    required this.mapId,
    required List<String> propIds,
    required this.state,
    this.durationMs = 350,
  }) : propIds = List.unmodifiable(propIds) {
    if (mapId.isEmpty || mapId.trim() != mapId ||
        this.propIds.isEmpty || this.propIds.length > 32 ||
        this.propIds.toSet().length != this.propIds.length ||
        this.propIds.any((id) => id.isEmpty || id.trim() != id) ||
        durationMs < 16 || durationMs > 10000) {
      throw const FormatException('Prop movement requires a map, 1..32 unique props and a duration of 16..10000 ms.');
    }
  }

  factory SceneSetPropStateInteractiveCommand.fromJson(Map<String, dynamic> json) {
    const fields = {'kind', 'mapId', 'propIds', 'state', 'durationMs'};
    if (json.keys.any((key) => !fields.contains(key)) ||
        json['kind'] != 'setPropState' || json['mapId'] is! String ||
        json['propIds'] is! List ||
        (json['propIds'] as List).any((id) => id is! String) ||
        json['durationMs'] is! int) {
      throw const FormatException('Invalid prop movement fields.');
    }
    return SceneSetPropStateInteractiveCommand(
      mapId: json['mapId'] as String,
      propIds: List<String>.from(json['propIds'] as List),
      state: MovingPropState.values.firstWhere((value) => value.name == json['state'],
          orElse: () => throw const FormatException('Invalid prop state.')),
      durationMs: json['durationMs'] as int,
    );
  }

  final String mapId;
  final List<String> propIds;
  final MovingPropState state;
  final int durationMs;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.setPropState;

  @override
  List<String> get outputPortIds => const ['moved', 'blocked'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mapId': mapId,
    'propIds': propIds,
    'state': state.name,
    'durationMs': durationMs,
  };

  @override
  bool operator ==(Object other) => other is SceneSetPropStateInteractiveCommand &&
      other.mapId == mapId && other.state == state && other.durationMs == durationMs &&
      other.propIds.length == propIds.length &&
      List.generate(propIds.length, (index) => index).every((index) => other.propIds[index] == propIds[index]);

  @override
  int get hashCode => Object.hash(mapId, Object.hashAll(propIds), state, durationMs);
}

@immutable
final class SceneMoveNpcInteractiveCommand extends SceneInteractiveCommand {
  SceneMoveNpcInteractiveCommand({
    required String mapId,
    required String entityId,
    required String warpId,
  }) : mapId = _normalize(mapId, 'mapId'),
       entityId = _normalize(entityId, 'entityId'),
       warpId = _normalize(warpId, 'warpId');

  final String mapId;
  final String entityId;
  final String warpId;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.moveNpc;

  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'mapId': mapId,
    'entityId': entityId,
    'warpId': warpId,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneMoveNpcInteractiveCommand &&
      other.mapId == mapId &&
      other.entityId == entityId &&
      other.warpId == warpId;

  @override
  int get hashCode => Object.hash(mapId, entityId, warpId);
}

@immutable
final class SceneWarpInteractiveCommand extends SceneInteractiveCommand {
  SceneWarpInteractiveCommand({
    required String destinationMapId,
    required String warpId,
    this.arrivalFacing,
    this.transition = SceneWarpTransition.mapDefault,
    this.presentation,
    String? arrivalCollisionOwnerEntityId,
  }) : destinationMapId = _normalize(destinationMapId, 'destinationMapId'),
       warpId = _normalize(warpId, 'warpId'),
       arrivalCollisionOwnerEntityId = arrivalCollisionOwnerEntityId == null
           ? null
           : _arrivalCollisionOwner(arrivalCollisionOwnerEntityId);

  final String destinationMapId;
  final String warpId;
  final EntityFacing? arrivalFacing;
  final SceneWarpTransition transition;
  final SceneWarpPresentation? presentation;
  final String? arrivalCollisionOwnerEntityId;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.warp;

  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'destinationMapId': destinationMapId,
    'warpId': warpId,
    if (arrivalFacing != null) 'arrivalFacing': arrivalFacing!.name,
    'transition': transition.name,
    if (presentation != null) 'presentation': presentation!.toJson(),
    if (arrivalCollisionOwnerEntityId != null)
      'arrivalCollisionOwnerEntityId': arrivalCollisionOwnerEntityId,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneWarpInteractiveCommand &&
      other.destinationMapId == destinationMapId &&
      other.warpId == warpId &&
      other.arrivalFacing == arrivalFacing &&
      other.transition == transition &&
      other.presentation == presentation &&
      other.arrivalCollisionOwnerEntityId == arrivalCollisionOwnerEntityId;

  @override
  int get hashCode =>
      Object.hash(destinationMapId, warpId, arrivalFacing, transition, presentation,
    arrivalCollisionOwnerEntityId,
  );
}

String _warpDestinationMapId(Map<String, dynamic> json) {
  const fields = {'kind', 'destinationMapId', 'warpId', 'arrivalFacing',
    'transition', 'arrivalCollisionOwnerEntityId', 'presentation'};
  if (json.keys.any((key) => !fields.contains(key))) {
    throw const FormatException('Unknown warp command field.');
  }
  return _required(json, 'destinationMapId');
}

String _arrivalCollisionOwner(Object? value) {
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw const FormatException(
      'Arrival collision owner must be a canonical entity identity.',
    );
  }
  return value;
}

@immutable
final class SceneOpenShopInteractiveCommand extends SceneInteractiveCommand {
  SceneOpenShopInteractiveCommand({required String shopId})
    : shopId = _normalize(shopId, 'shopId');

  final String shopId;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.openShop;

  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {'kind': kind.name, 'shopId': shopId};

  @override
  bool operator ==(Object other) =>
      other is SceneOpenShopInteractiveCommand && other.shopId == shopId;

  @override
  int get hashCode => shopId.hashCode;
}

@immutable
final class SceneOpenHealInteractiveCommand extends SceneInteractiveCommand {
  SceneOpenHealInteractiveCommand({this.requiresConfirmation = true, String? displayEntityId})
      : displayEntityId = _healingDisplayIdentity(displayEntityId);

  factory SceneOpenHealInteractiveCommand.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => !const {'kind', 'requiresConfirmation', 'displayEntityId'}.contains(key)) ||
        (json.containsKey('requiresConfirmation') && json['requiresConfirmation'] is! bool) ||
        (json.containsKey('displayEntityId') && json['displayEntityId'] is! String)) {
      throw const FormatException('Unsupported healing service options.');
    }
    return SceneOpenHealInteractiveCommand(
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
      displayEntityId: json['displayEntityId'] as String?,
    );
  }

  final bool requiresConfirmation;
  final String? displayEntityId;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.openHeal;

  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'requiresConfirmation': requiresConfirmation,
    if (displayEntityId != null) 'displayEntityId': displayEntityId,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneOpenHealInteractiveCommand &&
      other.requiresConfirmation == requiresConfirmation && other.displayEntityId == displayEntityId;

  @override
  int get hashCode => Object.hash(requiresConfirmation, displayEntityId);
}

@immutable
final class SceneWhiteOutInteractiveCommand extends SceneInteractiveCommand {
  const SceneWhiteOutInteractiveCommand();

  factory SceneWhiteOutInteractiveCommand.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => key != 'kind')) {
      throw const FormatException('White-out commands do not accept options.');
    }
    return const SceneWhiteOutInteractiveCommand();
  }

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.whiteOut;

  @override
  List<String> get outputPortIds => const ['completed'];

  @override
  Map<String, dynamic> toJson() => {'kind': kind.name};

  @override
  bool operator ==(Object other) => other is SceneWhiteOutInteractiveCommand;

  @override
  int get hashCode => kind.hashCode;
}

@immutable
final class SceneOpenPcInteractiveCommand extends SceneInteractiveCommand {
  SceneOpenPcInteractiveCommand({String? storageId})
    : storageId = storageId?.trim().isEmpty ?? true ? null : storageId!.trim();

  final String? storageId;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.openPc;

  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (storageId != null) 'storageId': storageId,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneOpenPcInteractiveCommand && other.storageId == storageId;

  @override
  int get hashCode => storageId.hashCode;
}

@immutable
final class SceneOpenRegionalMapInteractiveCommand extends SceneInteractiveCommand {
  const SceneOpenRegionalMapInteractiveCommand();

  factory SceneOpenRegionalMapInteractiveCommand.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => key != 'kind')) {
      throw const FormatException('Regional map commands do not accept options.');
    }
    return const SceneOpenRegionalMapInteractiveCommand();
  }

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.openRegionalMap;

  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {'kind': kind.name};

  @override
  bool operator ==(Object other) => other is SceneOpenRegionalMapInteractiveCommand;

  @override
  int get hashCode => kind.hashCode;
}

@immutable
final class SceneOpenPartyTradeInteractiveCommand
    extends SceneInteractiveCommand {
  const SceneOpenPartyTradeInteractiveCommand();

  factory SceneOpenPartyTradeInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json.keys.any((key) => key != 'kind')) {
      throw const FormatException(
        'Party trade commands do not accept options.',
      );
    }
    return const SceneOpenPartyTradeInteractiveCommand();
  }

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.openPartyTrade;

  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {'kind': kind.name};

  @override
  bool operator ==(Object other) =>
      other is SceneOpenPartyTradeInteractiveCommand;

  @override
  int get hashCode => kind.hashCode;
}

@immutable
final class SceneCharacterCustomAnimationInteractiveCommand
    extends SceneInteractiveCommand {
  const SceneCharacterCustomAnimationInteractiveCommand({
    required this.runtimeCommand,
  });

  final CharacterCustomAnimationRuntimeCommand runtimeCommand;

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.playCharacterAnimation;

  @override
  List<String> get outputPortIds => const <String>[
    'completed',
    'fallback',
    'interrupted',
    'failed',
  ];

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'runtimeCommand': runtimeCommand.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SceneCharacterCustomAnimationInteractiveCommand &&
      other.runtimeCommand == runtimeCommand;

  @override
  int get hashCode => runtimeCommand.hashCode;
}

@immutable
final class SceneRailJourneyInteractiveCommand extends SceneInteractiveCommand {
  SceneRailJourneyInteractiveCommand({
    required String commandId,
    required String journeyId,
    required this.operation,
    this.direction,
    this.advanceEvent,
    this.doorSide,
  }) : commandId = _normalize(commandId, 'commandId'),
       journeyId = _normalize(journeyId, 'journeyId') {
    switch (operation) {
      case SceneRailJourneyOperation.begin:
        if (direction == null || doorSide == null || advanceEvent != null) {
          throw ArgumentError(
            'A rail journey begin requires direction and doorSide only.',
          );
        }
      case SceneRailJourneyOperation.advance:
        if (direction != null || advanceEvent == null) {
          throw ArgumentError(
            'A rail journey advance requires advanceEvent only.',
          );
        }
        final requiresDoor =
            advanceEvent == SceneRailJourneyAdvanceEvent.destinationDoorUsed;
        if (requiresDoor != (doorSide != null)) {
          throw ArgumentError(
            'Only destinationDoorUsed requires a rail journey doorSide.',
          );
        }
      case SceneRailJourneyOperation.acknowledge:
        if (direction != null || advanceEvent != null || doorSide != null) {
          throw ArgumentError(
            'A rail journey acknowledge cannot carry transition fields.',
          );
        }
    }
  }

  final String commandId;
  final String journeyId;
  final SceneRailJourneyOperation operation;
  final RailJourneyDirection? direction;
  final SceneRailJourneyAdvanceEvent? advanceEvent;
  final RailJourneyDoorSide? doorSide;

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.railJourney;

  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'commandId': commandId,
    'journeyId': journeyId,
    'operation': operation.name,
    if (direction != null)
      'direction': switch (direction!) {
        RailJourneyDirection.outbound => 'outbound',
        RailJourneyDirection.returnJourney => 'return',
      },
    if (advanceEvent != null) 'advanceEvent': advanceEvent!.name,
    if (doorSide != null) 'doorSide': doorSide!.name,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneRailJourneyInteractiveCommand &&
      other.commandId == commandId &&
      other.journeyId == journeyId &&
      other.operation == operation &&
      other.direction == direction &&
      other.advanceEvent == advanceEvent &&
      other.doorSide == doorSide;

  @override
  int get hashCode => Object.hash(
    commandId,
    journeyId,
    operation,
    direction,
    advanceEvent,
    doorSide,
  );
}

String _normalize(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String _required(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string.');
  return _normalize(value, field);
}

String? _optional(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

bool? _optionalBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! Map) throw FormatException('$field must be an object.');
  return Map<String, dynamic>.from(value);
}

T _requiredEnum<T extends Enum>(
  Map<String, dynamic> json,
  String field,
  List<T> values,
) {
  final value = _required(json, field);
  return values.firstWhere(
    (candidate) => candidate.name == value,
    orElse: () => throw FormatException('$field is invalid.'),
  );
}

T? _optionalEnum<T extends Enum>(
  Map<String, dynamic> json,
  String field,
  List<T> values,
) {
  final value = _optional(json, field);
  if (value == null) return null;
  return values.firstWhere(
    (candidate) => candidate.name == value,
    orElse: () => throw FormatException('$field is invalid.'),
  );
}

RailJourneyDirection? _optionalRailJourneyDirection(
  Map<String, dynamic> json,
  String field,
) {
  final value = _optional(json, field);
  return switch (value) {
    null => null,
    'outbound' => RailJourneyDirection.outbound,
    'return' => RailJourneyDirection.returnJourney,
    _ => throw FormatException('$field is invalid.'),
  };
}

String? _healingDisplayIdentity(String? value) {
  if (value != null && (value.isEmpty || value.trim() != value)) {
    throw const FormatException('The healing display identity must be nonblank and exact.');
  }
  return value;
}

final class SceneInputTextToFactInteractiveCommand
    extends SceneInteractiveCommand {
  SceneInputTextToFactInteractiveCommand({
    required String factId,
    required this.prompt,
    required this.confirmationPrompt,
    required this.constraints,
    List<String> presetValues = const [],
    this.customChoiceLabel,
    this.presetChoicePrompt,
  }) : factId = _normalize(factId, 'factId'),
       presetValues = List.unmodifiable(presetValues) {
    if (constraints.minGraphemes < 1 || constraints.maxGraphemes == null) {
      throw ArgumentError('Text Fact input requires positive bounded length.');
    }
    if (presetValues.isEmpty !=
            (customChoiceLabel == null && presetChoicePrompt == null) ||
        (presetValues.isNotEmpty &&
            (customChoiceLabel == null ||
                customChoiceLabel!.trim().isEmpty ||
                presetChoicePrompt == null)) ||
        presetValues.toSet().length != presetValues.length ||
        presetValues.any(
          (value) =>
              value.trim() != value ||
              value.contains('\n') ||
              value.contains('\r') ||
              value.characters.length < constraints.minGraphemes ||
              value.characters.length > constraints.maxGraphemes!,
        )) {
      throw ArgumentError(
        'Text presets require unique valid values and both choice prompts.',
      );
    }
  }

  factory SceneInputTextToFactInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    const fields = {
      'kind',
      'factId',
      'prompt',
      'confirmationPrompt',
      'constraints',
      'presetValues',
      'customChoiceLabel',
      'presetChoicePrompt',
    };
    if (json.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Unknown text Fact input field.');
    }
    final presets = json['presetValues'];
    if (presets != null && (presets is! List || presets.any((value) => value is! String))) {
      throw const FormatException('Text presets must be a list of strings.');
    }
    return SceneInputTextToFactInteractiveCommand(
      factId: _required(json, 'factId'),
      prompt: SceneInteractionPrompt.fromJson(_requiredObject(json, 'prompt')),
      confirmationPrompt: SceneInteractionPrompt.fromJson(
        _requiredObject(json, 'confirmationPrompt'),
      ),
      constraints: SceneTextInputConstraints.fromJson(
        _requiredObject(json, 'constraints'),
      ),
      presetValues: json['presetValues'] == null
          ? const []
          : (json['presetValues'] as List).cast<String>(),
      customChoiceLabel: _optional(json, 'customChoiceLabel'),
      presetChoicePrompt: json['presetChoicePrompt'] == null
          ? null
          : SceneInteractionPrompt.fromJson(
              _requiredObject(json, 'presetChoicePrompt'),
            ),
    );
  }

  final String factId;
  final SceneInteractionPrompt prompt;
  final SceneInteractionPrompt confirmationPrompt;
  final SceneTextInputConstraints constraints;
  final List<String> presetValues;
  final String? customChoiceLabel;
  final SceneInteractionPrompt? presetChoicePrompt;

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.inputTextToFact;

  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'factId': factId,
    'prompt': prompt.toJson(),
    'confirmationPrompt': confirmationPrompt.toJson(),
    'constraints': constraints.toJson(),
    if (presetValues.isNotEmpty) 'presetValues': presetValues,
    if (customChoiceLabel != null) 'customChoiceLabel': customChoiceLabel,
    if (presetChoicePrompt != null)
      'presetChoicePrompt': presetChoicePrompt!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SceneInputTextToFactInteractiveCommand &&
      other.factId == factId &&
      other.prompt == prompt &&
      other.confirmationPrompt == confirmationPrompt &&
      other.constraints == constraints &&
      other.customChoiceLabel == customChoiceLabel &&
      other.presetChoicePrompt == presetChoicePrompt &&
      other.presetValues.length == presetValues.length &&
      presetValues.indexed.every(
        (entry) => entry.$2 == other.presetValues[entry.$1],
      );

  @override
  int get hashCode => Object.hash(
    factId,
    prompt,
    confirmationPrompt,
    constraints,
    customChoiceLabel,
    presetChoicePrompt,
    Object.hashAll(presetValues),
  );
}

final class SceneReceivePokemonFromCatalogInteractiveCommand
    extends SceneInteractiveCommand {
  SceneReceivePokemonFromCatalogInteractiveCommand({
    required String speciesId,
    required String formId,
    required this.level,
    required this.nicknamePolicy,
    required this.nicknameMaxGraphemes,
    required this.pokedexPresentationPolicy,
    List<String>? moveIds,
  }) : speciesId = speciesId.trim(),
       formId = formId.trim(),
       moveIds = readScenePokemonGiftMoveIds(moveIds) {
    if (this.speciesId.isEmpty ||
        this.formId.isEmpty ||
        level < 1 ||
        level > 100 ||
        nicknameMaxGraphemes < 1 ||
        nicknameMaxGraphemes > 100) {
      throw const FormatException(
        'Interactive catalog gift requires species, form, level 1..100 and nickname length 1..100.',
      );
    }
  }

  factory SceneReceivePokemonFromCatalogInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    const fields = {
      'kind',
      'speciesId',
      'formId',
      'level',
      'nicknamePolicy',
      'nicknameMaxGraphemes',
      'pokedexPresentationPolicy',
    };
    if (fields.any((field) => !json.containsKey(field)) ||
        json.keys.any((key) => key != 'moveIds' && !fields.contains(key)) ||
        json['kind'] != 'receivePokemonFromCatalog' ||
        json['level'] is! int ||
        json['nicknameMaxGraphemes'] is! int) {
      throw const FormatException('Invalid interactive catalog gift fields.');
    }
    return SceneReceivePokemonFromCatalogInteractiveCommand(
      speciesId: _required(json, 'speciesId'),
      formId: _required(json, 'formId'),
      level: json['level'] as int,
      nicknamePolicy: _requiredEnum(
        json,
        'nicknamePolicy',
        ScenePokemonGiftNicknamePolicy.values,
      ),
      nicknameMaxGraphemes: json['nicknameMaxGraphemes'] as int,
      pokedexPresentationPolicy: _requiredEnum(
        json,
        'pokedexPresentationPolicy',
        ScenePokemonGiftPokedexPresentationPolicy.values,
      ),
      moveIds: readScenePokemonGiftMoveIds(json['moveIds']),
    );
  }

  final String speciesId;
  final String formId;
  final int level;
  final ScenePokemonGiftNicknamePolicy nicknamePolicy;
  final int nicknameMaxGraphemes;
  final ScenePokemonGiftPokedexPresentationPolicy pokedexPresentationPolicy;
  final List<String>? moveIds;

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.receivePokemonFromCatalog;

  @override
  List<String> get outputPortIds => const ['party', 'pc', 'noCapacity'];

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'speciesId': speciesId,
    'formId': formId,
    'level': level,
    'nicknamePolicy': nicknamePolicy.name,
    'nicknameMaxGraphemes': nicknameMaxGraphemes,
    'pokedexPresentationPolicy': pokedexPresentationPolicy.name,
    if (moveIds != null) 'moveIds': moveIds,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneReceivePokemonFromCatalogInteractiveCommand &&
      other.speciesId == speciesId &&
      other.formId == formId &&
      other.level == level &&
      other.nicknamePolicy == nicknamePolicy &&
      other.nicknameMaxGraphemes == nicknameMaxGraphemes &&
      other.pokedexPresentationPolicy == pokedexPresentationPolicy &&
      scenePokemonGiftMoveIdsEqual(other.moveIds, moveIds);

  @override
  int get hashCode => Object.hash(
    speciesId,
    formId,
    level,
    nicknamePolicy,
    nicknameMaxGraphemes,
    pokedexPresentationPolicy,
    moveIds == null ? null : Object.hashAll(moveIds!),
  );
}
