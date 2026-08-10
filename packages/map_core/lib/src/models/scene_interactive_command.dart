import 'package:meta/meta.dart' show immutable;

import '../runtime/character_custom_animation_runtime_contract.dart';

enum SceneInteractiveCommandKind {
  warp,
  moveNpc,
  openShop,
  openHeal,
  openPc,
  playCharacterAnimation,
}

@immutable
abstract base class SceneInteractiveCommand {
  const SceneInteractiveCommand();

  factory SceneInteractiveCommand.warp({
    required String destinationMapId,
    required String warpId,
  }) = SceneWarpInteractiveCommand;

  factory SceneInteractiveCommand.moveNpc({
    required String mapId,
    required String entityId,
    required String warpId,
  }) = SceneMoveNpcInteractiveCommand;

  factory SceneInteractiveCommand.openShop({required String shopId}) =
      SceneOpenShopInteractiveCommand;

  factory SceneInteractiveCommand.openHeal({bool requiresConfirmation}) =
      SceneOpenHealInteractiveCommand;

  factory SceneInteractiveCommand.openPc({String storageId}) =
      SceneOpenPcInteractiveCommand;

  factory SceneInteractiveCommand.playCharacterAnimation({
    required CharacterCustomAnimationRuntimeCommand runtimeCommand,
  }) = SceneCharacterCustomAnimationInteractiveCommand;

  factory SceneInteractiveCommand.fromJson(Map<String, dynamic> json) {
    final kind = SceneInteractiveCommandKind.values.firstWhere(
      (value) => value.name == json['kind'],
      orElse: () => throw FormatException(
        'Unknown SceneInteractiveCommand kind: ${json['kind']}',
      ),
    );
    return switch (kind) {
      SceneInteractiveCommandKind.warp => SceneWarpInteractiveCommand(
          destinationMapId: _required(json, 'destinationMapId'),
          warpId: _required(json, 'warpId'),
        ),
      SceneInteractiveCommandKind.moveNpc => SceneMoveNpcInteractiveCommand(
          mapId: _required(json, 'mapId'),
          entityId: _required(json, 'entityId'),
          warpId: _required(json, 'warpId'),
        ),
      SceneInteractiveCommandKind.openShop => SceneOpenShopInteractiveCommand(
          shopId: _required(json, 'shopId'),
        ),
      SceneInteractiveCommandKind.openHeal => SceneOpenHealInteractiveCommand(
          requiresConfirmation:
              _optionalBool(json, 'requiresConfirmation') ?? true,
        ),
      SceneInteractiveCommandKind.openPc => SceneOpenPcInteractiveCommand(
          storageId: _optional(json, 'storageId'),
        ),
      SceneInteractiveCommandKind.playCharacterAnimation =>
        SceneCharacterCustomAnimationInteractiveCommand(
          runtimeCommand: CharacterCustomAnimationRuntimeCommand.fromJson(
            _requiredObject(json, 'runtimeCommand'),
          ),
        ),
    };
  }

  SceneInteractiveCommandKind get kind;
  List<String> get outputPortIds;
  Map<String, dynamic> toJson();
}

@immutable
final class SceneMoveNpcInteractiveCommand extends SceneInteractiveCommand {
  SceneMoveNpcInteractiveCommand({
    required String mapId,
    required String entityId,
    required String warpId,
  })  : mapId = _normalize(mapId, 'mapId'),
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
  })  : destinationMapId = _normalize(destinationMapId, 'destinationMapId'),
        warpId = _normalize(warpId, 'warpId');

  final String destinationMapId;
  final String warpId;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.warp;

  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'destinationMapId': destinationMapId,
        'warpId': warpId,
      };

  @override
  bool operator ==(Object other) =>
      other is SceneWarpInteractiveCommand &&
      other.destinationMapId == destinationMapId &&
      other.warpId == warpId;

  @override
  int get hashCode => Object.hash(destinationMapId, warpId);
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
  const SceneOpenHealInteractiveCommand({this.requiresConfirmation = true});

  final bool requiresConfirmation;

  @override
  SceneInteractiveCommandKind get kind => SceneInteractiveCommandKind.openHeal;

  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'requiresConfirmation': requiresConfirmation,
      };

  @override
  bool operator ==(Object other) =>
      other is SceneOpenHealInteractiveCommand &&
      other.requiresConfirmation == requiresConfirmation;

  @override
  int get hashCode => requiresConfirmation.hashCode;
}

@immutable
final class SceneOpenPcInteractiveCommand extends SceneInteractiveCommand {
  SceneOpenPcInteractiveCommand({String? storageId})
      : storageId =
            storageId?.trim().isEmpty ?? true ? null : storageId!.trim();

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
