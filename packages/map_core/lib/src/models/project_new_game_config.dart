import 'package:meta/meta.dart' show immutable;

import 'save_data.dart';
import 'project_new_game_recovery_point.dart';
import 'narrative_value.dart';

@immutable
final class ProjectStarterOption {
  const ProjectStarterOption({
    required this.id,
    required this.label,
    required this.pokemon,
  });

  factory ProjectStarterOption.fromJson(Map<String, dynamic> json) {
    return ProjectStarterOption(
      id: _readRequiredString(json, 'id'),
      label: _readRequiredString(json, 'label'),
      pokemon: PlayerPokemon.fromJson(_readObject(json, 'pokemon')),
    );
  }

  final String id;
  final String label;
  final PlayerPokemon pokemon;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'pokemon': pokemon.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectStarterOption &&
          other.id == id &&
          other.label == label &&
          other.pokemon == pokemon;

  @override
  int get hashCode => Object.hash(id, label, pokemon);
}

/// Project-owned contract used to create a real new game without host fixtures.
///
@immutable
final class ProjectNewGameConfig {
  const ProjectNewGameConfig({
    this.enabled = false,
    this.startMapId = '',
    this.startSpawnId,
    this.initialRecoveryPoint,
    this.playerName = 'Player',
    this.playerAvatarCharacterIds = const <String>[],
    this.playerPronounSet = PlayerPronounSet.neutral,
    this.startingMoney = 0,
    this.initialBag = const <BagEntry>[],
    this.initialParty = const <PlayerPokemon>[],
    this.initialFacts = const <String, bool>{},
    this.initialFactValues = const <String, NarrativeValue>{},
    this.initialFactValuesByAvatarCharacterId =
        const <String, Map<String, NarrativeValue>>{},
    this.existingPartyFactId,
    this.preSessionSceneId,
    this.starterOptions = const <ProjectStarterOption>[],
  });

  factory ProjectNewGameConfig.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('starterSelectionSceneId')) {
      throw const FormatException(
        r'$.newGame.starterSelectionSceneId: '
        'new_game_legacy_entrypoint_unsupported '
        '(expected=preSessionSceneId)',
      );
    }
    return ProjectNewGameConfig(
      enabled: _readBool(json, 'enabled', fallback: false),
      startMapId: _readString(json, 'startMapId') ?? '',
      startSpawnId: _readString(json, 'startSpawnId'),
      initialRecoveryPoint: json['initialRecoveryPoint'] == null
          ? null
          : ProjectNewGameRecoveryPoint.fromJson(
              _readObject(json, 'initialRecoveryPoint')),
      playerName: _readString(json, 'playerName') ?? 'Player',
      playerAvatarCharacterIds:
          _readStringList(json, 'playerAvatarCharacterIds'),
      playerPronounSet: _readPlayerPronounSet(json, 'playerPronounSet'),
      startingMoney: _readInt(json, 'startingMoney', fallback: 0),
      initialBag: _readObjectList(json, 'initialBag')
          .map(BagEntry.fromJson)
          .toList(growable: false),
      initialParty: _readObjectList(json, 'initialParty')
          .map(PlayerPokemon.fromJson)
          .toList(growable: false),
      initialFacts: json['factSchemaVersion'] == 2
          ? const <String, bool>{}
          : _readBoolMap(json, 'initialFacts'),
      initialFactValues: json['factSchemaVersion'] == 2
          ? _readNarrativeValueMap(json, 'initialFactValues')
          : const <String, NarrativeValue>{},
      initialFactValuesByAvatarCharacterId: _readAvatarFactValues(json),
      existingPartyFactId: _readString(json, 'existingPartyFactId'),
      preSessionSceneId: _readString(json, 'preSessionSceneId'),
      starterOptions: _readObjectList(json, 'starterOptions')
          .map(ProjectStarterOption.fromJson)
          .toList(growable: false),
    );
  }

  final bool enabled;
  final String startMapId;
  final String? startSpawnId;
  final ProjectNewGameRecoveryPoint? initialRecoveryPoint;
  final String playerName;
  final List<String> playerAvatarCharacterIds;
  final PlayerPronounSet playerPronounSet;
  final int startingMoney;
  final List<BagEntry> initialBag;
  final List<PlayerPokemon> initialParty;
  final Map<String, bool> initialFacts;
  final Map<String, NarrativeValue> initialFactValues;
  final Map<String, Map<String, NarrativeValue>>
      initialFactValuesByAvatarCharacterId;

  Map<String, NarrativeValue> get resolvedInitialFactValues =>
      Map.unmodifiable({
        for (final entry in initialFacts.entries)
          entry.key: NarrativeValue.boolean(entry.value),
        ...initialFactValues,
      });
  final String? existingPartyFactId;
  final String? preSessionSceneId;
  final List<ProjectStarterOption> starterOptions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'startMapId': startMapId,
        if (startSpawnId != null) 'startSpawnId': startSpawnId,
        if (initialRecoveryPoint != null)
          'initialRecoveryPoint': initialRecoveryPoint!.toJson(),
        'playerName': playerName,
        'playerAvatarCharacterIds': playerAvatarCharacterIds,
        'playerPronounSet': playerPronounSet.name,
        'startingMoney': startingMoney,
        'initialBag': initialBag.map((entry) => entry.toJson()).toList(),
        'initialParty': initialParty.map((member) => member.toJson()).toList(),
        if (initialFactValues.isEmpty)
          'initialFacts': Map<String, bool>.from(initialFacts)
        else ...{
          'factSchemaVersion': 2,
          'initialFactValues': {
            for (final entry in resolvedInitialFactValues.entries)
              entry.key: entry.value.toJson(),
          },
        },
        if (initialFactValuesByAvatarCharacterId.isNotEmpty)
          'initialFactValuesByAvatarCharacterId': {
            for (final avatar in initialFactValuesByAvatarCharacterId.entries)
              avatar.key: {
                for (final fact in avatar.value.entries)
                  fact.key: fact.value.toJson(),
              },
          },
        if (existingPartyFactId != null)
          'existingPartyFactId': existingPartyFactId,
        if (preSessionSceneId != null) 'preSessionSceneId': preSessionSceneId,
        'starterOptions':
            starterOptions.map((option) => option.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectNewGameConfig &&
          other.enabled == enabled &&
          other.startMapId == startMapId &&
          other.startSpawnId == startSpawnId &&
          other.initialRecoveryPoint == initialRecoveryPoint &&
          other.playerName == playerName &&
          _listEquals(
            other.playerAvatarCharacterIds,
            playerAvatarCharacterIds,
          ) &&
          other.playerPronounSet == playerPronounSet &&
          other.startingMoney == startingMoney &&
          _listEquals(other.initialBag, initialBag) &&
          _listEquals(other.initialParty, initialParty) &&
          _mapEquals(other.initialFacts, initialFacts) &&
          _mapEquals(other.initialFactValues, initialFactValues) &&
          _avatarFactsEqual(other.initialFactValuesByAvatarCharacterId,
              initialFactValuesByAvatarCharacterId) &&
          other.existingPartyFactId == existingPartyFactId &&
          other.preSessionSceneId == preSessionSceneId &&
          _listEquals(other.starterOptions, starterOptions);

  @override
  int get hashCode => Object.hash(
        enabled,
        startMapId,
        startSpawnId,
        initialRecoveryPoint,
        playerName,
        Object.hashAll(playerAvatarCharacterIds),
        playerPronounSet,
        startingMoney,
        Object.hashAll(initialBag),
        Object.hashAll(initialParty),
        _factMapHash(initialFacts),
        _factMapHash(initialFactValues),
        Object.hashAllUnordered([
          for (final avatar in initialFactValuesByAvatarCharacterId.entries)
            Object.hash(avatar.key, _factMapHash(avatar.value)),
        ]),
        existingPartyFactId,
        preSessionSceneId,
        Object.hashAll(starterOptions),
      );
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('ProjectStarterOption.$key must be a string.');
  }
  return value;
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('ProjectNewGameConfig.$key must be a string.');
  }
  return value;
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return const <String>[];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException(
      'ProjectNewGameConfig.$key must be a list of strings.',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}

PlayerPronounSet _readPlayerPronounSet(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value == null) return PlayerPronounSet.neutral;
  if (value is! String) {
    throw FormatException('ProjectNewGameConfig.$key must be a string.');
  }
  return PlayerPronounSet.values
          .where((entry) => entry.name == value)
          .firstOrNull ??
      (throw FormatException(
        'ProjectNewGameConfig.$key contains an unknown value: $value.',
      ));
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  required bool fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! bool) {
    throw FormatException('ProjectNewGameConfig.$key must be a boolean.');
  }
  return value;
}

int _readInt(
  Map<String, dynamic> json,
  String key, {
  required int fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! int) {
    throw FormatException('ProjectNewGameConfig.$key must be an integer.');
  }
  return value;
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('ProjectStarterOption.$key must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _readObjectList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value == null) return const <Map<String, dynamic>>[];
  if (value is! List) {
    throw FormatException('ProjectNewGameConfig.$key must be a list.');
  }
  return <Map<String, dynamic>>[
    for (final item in value)
      if (item is Map)
        Map<String, dynamic>.from(item)
      else
        throw FormatException(
          'ProjectNewGameConfig.$key entries must be objects.',
        ),
  ];
}

Map<String, bool> _readBoolMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return const <String, bool>{};
  if (value is! Map) {
    throw FormatException('ProjectNewGameConfig.$key must be an object.');
  }
  final decoded = <String, bool>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! bool) {
      throw FormatException(
        'ProjectNewGameConfig.$key must contain boolean values.',
      );
    }
    decoded[entry.key as String] = entry.value as bool;
  }
  return decoded;
}

Map<String, NarrativeValue> _readNarrativeValueMap(
  Map<String, dynamic> json,
  String key,
) {
  final raw = json[key];
  if (raw is! Map) {
    throw FormatException('ProjectNewGameConfig.$key must be an object.');
  }
  final decoded = <String, NarrativeValue>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw FormatException(
        'ProjectNewGameConfig.$key keys must be strings.',
      );
    }
    decoded[entry.key as String] = NarrativeValue.fromJson(entry.value);
  }
  return Map.unmodifiable(decoded);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

Map<String, Map<String, NarrativeValue>> _readAvatarFactValues(
  Map<String, dynamic> json,
) {
  const key = 'initialFactValuesByAvatarCharacterId';
  if (!json.containsKey(key)) return const {};
  final raw = json[key];
  if (raw is! Map) {
    throw const FormatException(
      'ProjectNewGameConfig.initialFactValuesByAvatarCharacterId must be an object.',
    );
  }
  final result = <String, Map<String, NarrativeValue>>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      throw const FormatException(
        'ProjectNewGameConfig.initialFactValuesByAvatarCharacterId keys must be strings.',
      );
    }
    result[entry.key as String] = _readNarrativeValueMap({
      'values': entry.value,
    }, 'values');
  }
  return Map.unmodifiable(result);
}

bool _avatarFactsEqual(
  Map<String, Map<String, NarrativeValue>> left,
  Map<String, Map<String, NarrativeValue>> right,
) =>
    left.length == right.length &&
    left.entries.every(
      (entry) =>
          right.containsKey(entry.key) &&
          _mapEquals(entry.value, right[entry.key]!),
    );

int _factMapHash<T>(Map<String, T> values) => Object.hashAllUnordered([
  for (final entry in values.entries) Object.hash(entry.key, entry.value),
]);
