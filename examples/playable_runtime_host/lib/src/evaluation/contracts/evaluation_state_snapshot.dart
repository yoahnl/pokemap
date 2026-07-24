import 'dart:convert';

import 'package:crypto/crypto.dart';

final class EvaluationStateSnapshot {
  EvaluationStateSnapshot({
    required String projectId,
    required String runId,
    required String mapId,
    required this.x,
    required this.y,
    required String movementMode,
    Map<String, bool> entityVisibility = const <String, bool>{},
    Map<String, Object?> facts = const <String, Object?>{},
    Map<String, Object?> eventLedger = const <String, Object?>{},
    Map<String, Object?> progression = const <String, Object?>{},
    required this.money,
    List<String> badges = const <String>[],
    Map<String, int> bag = const <String, int>{},
    Map<String, Object?> shop = const <String, Object?>{},
    List<Map<String, Object?>> party = const <Map<String, Object?>>[],
    List<Map<String, Object?>> storage = const <Map<String, Object?>>[],
    Map<String, Object?>? activeDialogue,
    Map<String, Object?>? activeScene,
    Map<String, Object?>? activeBattle,
    Map<String, Object?> saveMetadata = const <String, Object?>{},
  })  : projectId = _nonBlank(projectId, 'projectId'),
        runId = _nonBlank(runId, 'runId'),
        mapId = _nonBlank(mapId, 'mapId'),
        movementMode = _nonBlank(movementMode, 'movementMode'),
        entityVisibility = Map<String, bool>.unmodifiable(entityVisibility),
        facts = _freezeMap(facts),
        eventLedger = _freezeMap(eventLedger),
        progression = _freezeMap(progression),
        badges = List<String>.unmodifiable(badges),
        bag = Map<String, int>.unmodifiable(bag),
        shop = _freezeMap(shop),
        party = _freezeMapList(party),
        storage = _freezeMapList(storage),
        activeDialogue =
            activeDialogue == null ? null : _freezeMap(activeDialogue),
        activeScene = activeScene == null ? null : _freezeMap(activeScene),
        activeBattle = activeBattle == null ? null : _freezeMap(activeBattle),
        saveMetadata = _freezeMap(saveMetadata);

  final String projectId;
  final String runId;
  final String mapId;
  final int x;
  final int y;
  final String movementMode;
  final Map<String, bool> entityVisibility;
  final Map<String, Object?> facts;
  final Map<String, Object?> eventLedger;
  final Map<String, Object?> progression;
  final int money;
  final List<String> badges;
  final Map<String, int> bag;
  final Map<String, Object?> shop;
  final List<Map<String, Object?>> party;
  final List<Map<String, Object?>> storage;
  final Map<String, Object?>? activeDialogue;
  final Map<String, Object?>? activeScene;
  final Map<String, Object?>? activeBattle;
  final Map<String, Object?> saveMetadata;

  String get currentMapId => mapId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'projectId': projectId,
      'runId': runId,
      'world': <String, Object?>{
        'mapId': mapId,
        'position': <String, Object?>{'x': x, 'y': y},
        'movementMode': movementMode,
        'entityVisibility': entityVisibility,
      },
      'facts': facts,
      'eventLedger': eventLedger,
      'progression': progression,
      'trainer': <String, Object?>{
        'money': money,
        'badges': badges,
      },
      'bag': bag,
      'shop': shop,
      'party': party,
      'storage': storage,
      'dialogue': activeDialogue,
      'scene': activeScene,
      'battle': activeBattle,
      'save': saveMetadata,
    };
  }

  String get canonicalJson => jsonEncode(_canonicalize(_digestJson()));

  String get digestSha256 {
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  Map<String, Object?> _digestJson() {
    final json = toJson()..remove('runId');
    final save = Map<String, Object?>.from(saveMetadata)
      ..remove('createdAt')
      ..remove('savedAt')
      ..remove('timestamp')
      ..remove('updatedAt');
    json['save'] = save;
    return json;
  }
}

String _nonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}

List<Map<String, Object?>> _freezeMapList(
  List<Map<String, Object?>> values,
) {
  return List<Map<String, Object?>>.unmodifiable(
    values.map(_freezeMap),
  );
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, item) => MapEntry<String, Object?>(key, _freezeValue(item)),
    ),
  );
}

Object? _freezeValue(Object? value) {
  return switch (value) {
    Map<String, Object?> map => _freezeMap(map),
    Map map => _freezeMap(Map<String, Object?>.from(map)),
    List list => List<Object?>.unmodifiable(list.map(_freezeValue)),
    double number when !number.isFinite => throw ArgumentError.value(
        value,
        'value',
        'Snapshot numbers must be finite.',
      ),
    null || bool() || num() || String() => value,
    _ => throw ArgumentError.value(
        value,
        'value',
        'Snapshot values must be JSON-compatible.',
      ),
  };
}

Object? _canonicalize(Object? value) {
  return switch (value) {
    Map map => <String, Object?>{
        for (final key in map.keys.cast<String>().toList()..sort())
          key: _canonicalize(map[key]),
      },
    List list => list.map(_canonicalize).toList(growable: false),
    _ => value,
  };
}
