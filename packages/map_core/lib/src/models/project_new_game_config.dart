import 'package:meta/meta.dart' show immutable;

import 'save_data.dart';
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
/// The config deliberately describes state only. Narrative presentation and
/// starter selection remain authored as Yarn/Scene/Event assets referenced by
/// [starterSelectionSceneId].
@immutable
final class ProjectNewGameConfig {
  const ProjectNewGameConfig({
    this.enabled = false,
    this.startMapId = '',
    this.startSpawnId,
    this.playerName = 'Player',
    this.startingMoney = 0,
    this.initialBag = const <BagEntry>[],
    this.initialParty = const <PlayerPokemon>[],
    this.initialFacts = const <String, bool>{},
    this.initialFactValues = const <String, NarrativeValue>{},
    this.existingPartyFactId,
    this.starterSelectionSceneId,
    this.starterOptions = const <ProjectStarterOption>[],
  });

  factory ProjectNewGameConfig.fromJson(Map<String, dynamic> json) {
    return ProjectNewGameConfig(
      enabled: _readBool(json, 'enabled', fallback: false),
      startMapId: _readString(json, 'startMapId') ?? '',
      startSpawnId: _readString(json, 'startSpawnId'),
      playerName: _readString(json, 'playerName') ?? 'Player',
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
      existingPartyFactId: _readString(json, 'existingPartyFactId'),
      starterSelectionSceneId: _readString(json, 'starterSelectionSceneId'),
      starterOptions: _readObjectList(json, 'starterOptions')
          .map(ProjectStarterOption.fromJson)
          .toList(growable: false),
    );
  }

  final bool enabled;
  final String startMapId;
  final String? startSpawnId;
  final String playerName;
  final int startingMoney;
  final List<BagEntry> initialBag;
  final List<PlayerPokemon> initialParty;
  final Map<String, bool> initialFacts;
  final Map<String, NarrativeValue> initialFactValues;

  Map<String, NarrativeValue> get resolvedInitialFactValues =>
      Map.unmodifiable({
        for (final entry in initialFacts.entries)
          entry.key: NarrativeValue.boolean(entry.value),
        ...initialFactValues,
      });
  final String? existingPartyFactId;
  final String? starterSelectionSceneId;
  final List<ProjectStarterOption> starterOptions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'startMapId': startMapId,
        if (startSpawnId != null) 'startSpawnId': startSpawnId,
        'playerName': playerName,
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
        if (existingPartyFactId != null)
          'existingPartyFactId': existingPartyFactId,
        if (starterSelectionSceneId != null)
          'starterSelectionSceneId': starterSelectionSceneId,
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
          other.playerName == playerName &&
          other.startingMoney == startingMoney &&
          _listEquals(other.initialBag, initialBag) &&
          _listEquals(other.initialParty, initialParty) &&
          _mapEquals(other.initialFacts, initialFacts) &&
          _mapEquals(other.initialFactValues, initialFactValues) &&
          other.existingPartyFactId == existingPartyFactId &&
          other.starterSelectionSceneId == starterSelectionSceneId &&
          _listEquals(other.starterOptions, starterOptions);

  @override
  int get hashCode => Object.hash(
        enabled,
        startMapId,
        startSpawnId,
        playerName,
        startingMoney,
        Object.hashAll(initialBag),
        Object.hashAll(initialParty),
        Object.hashAllUnordered(initialFacts.entries),
        Object.hashAllUnordered(initialFactValues.entries),
        existingPartyFactId,
        starterSelectionSceneId,
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
