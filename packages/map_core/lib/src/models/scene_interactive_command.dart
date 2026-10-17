import 'package:meta/meta.dart' show immutable;

import '../runtime/character_custom_animation_runtime_contract.dart';
import 'rail_journey.dart';
import 'moving_platform.dart';
import 'enums.dart';
import 'scene_actor_route.dart';
import 'scene_warp_presentation.dart';

enum SceneInteractiveCommandKind {
  giveItem,
  warp,
  wait,
  waitForActorRoutes,
  worldTone,
  playSoundEffect,
  actorRoute,
  actorVisibility,
  moveNpc,
  movePlatform,
  openShop,
  openHeal,
  openPc,
  openRegionalMap,
  openPartyTrade,
  playCharacterAnimation,
  playModelAnimation,
  railJourney,
}

enum SceneRailJourneyOperation { begin, advance, acknowledge }

enum SceneWarpTransition { mapDefault, none }

enum SceneRailJourneyAdvanceEvent {
  doorsClosed,
  arrivalReached,
  destinationDoorUsed,
}

@immutable
abstract base class SceneInteractiveCommand {
  const SceneInteractiveCommand();

  factory SceneInteractiveCommand.giveItem({
    required String itemId,
    required int quantity,
  }) = SceneGiveItemInteractiveCommand;

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

  factory SceneInteractiveCommand.playSoundEffect({
    required String mediaAssetId,
    required double volume,
  }) = ScenePlaySoundEffectInteractiveCommand;

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

  factory SceneInteractiveCommand.openShop({required String shopId}) =
      SceneOpenShopInteractiveCommand;

  factory SceneInteractiveCommand.openHeal({bool requiresConfirmation, String? displayEntityId}) =
      SceneOpenHealInteractiveCommand;

  factory SceneInteractiveCommand.openPc({String storageId}) =
      SceneOpenPcInteractiveCommand;

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
      SceneInteractiveCommandKind.playSoundEffect =>
        ScenePlaySoundEffectInteractiveCommand.fromJson(json),
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
      SceneInteractiveCommandKind.openShop => SceneOpenShopInteractiveCommand(
        shopId: _required(json, 'shopId'),
      ),
      SceneInteractiveCommandKind.openHeal => SceneOpenHealInteractiveCommand.fromJson(json),
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
  }) : mediaAssetId = _normalize(mediaAssetId, 'mediaAssetId'),
       volume = _boundedPresentationNumber(volume, 'volume', 0, 1);

  factory ScenePlaySoundEffectInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    _presentationCommandFields(json, const {'kind', 'mediaAssetId', 'volume'});
    if (json['kind'] != 'playSoundEffect') {
      throw const FormatException('Invalid sound effect command.');
    }
    return ScenePlaySoundEffectInteractiveCommand(
      mediaAssetId: _required(json, 'mediaAssetId'),
      volume: _presentationNumber(json, 'volume'),
    );
  }

  final String mediaAssetId;
  final double volume;

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
  };
  @override
  bool operator ==(Object other) =>
      other is ScenePlaySoundEffectInteractiveCommand &&
      other.mediaAssetId == mediaAssetId &&
      other.volume == volume;
  @override
  int get hashCode => Object.hash(mediaAssetId, volume);
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
